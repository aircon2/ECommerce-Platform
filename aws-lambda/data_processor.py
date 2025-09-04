"""
AWS Lambda Function for E-commerce Data Processing
This function processes analytics data and exports to S3 for further analysis
"""

import json
import boto3
import pymysql
import os
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Any

# Initialize AWS clients
s3_client = boto3.client('s3')
athena_client = boto3.client('athena')

def get_db_connection():
    """Create database connection"""
    try:
        connection = pymysql.connect(
            host=os.environ['DB_HOST'],
            user=os.environ['DB_USER'],
            password=os.environ['DB_PASSWORD'],
            database=os.environ['DB_NAME'],
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        return connection
    except Exception as e:
        print(f"Database connection error: {str(e)}")
        raise

def execute_analytics_query(connection, query: str) -> List[Dict]:
    """Execute analytics query and return results"""
    try:
        with connection.cursor() as cursor:
            cursor.execute(query)
            results = cursor.fetchall()
            return results
    except Exception as e:
        print(f"Query execution error: {str(e)}")
        raise

def upload_to_s3(data: Any, bucket: str, key: str, format_type: str = 'json'):
    """Upload data to S3 in specified format"""
    try:
        if format_type == 'json':
            body = json.dumps(data, default=str, indent=2)
            content_type = 'application/json'
        elif format_type == 'csv':
            if isinstance(data, list) and len(data) > 0:
                df = pd.DataFrame(data)
                body = df.to_csv(index=False)
            else:
                body = str(data)
            content_type = 'text/csv'
        else:
            body = str(data)
            content_type = 'text/plain'
        
        s3_client.put_object(
            Bucket=bucket,
            Key=key,
            Body=body,
            ContentType=content_type
        )
        print(f"Successfully uploaded {key} to S3")
    except Exception as e:
        print(f"S3 upload error: {str(e)}")
        raise

def process_customer_analytics(connection, bucket: str, timestamp: str):
    """Process customer analytics data"""
    queries = {
        'customer_segments': """
            SELECT 
                customer_segment,
                COUNT(*) as customer_count,
                SUM(total_spent) as total_revenue,
                AVG(total_spent) as avg_spent,
                MAX(total_spent) as max_spent,
                MIN(total_spent) as min_spent
            FROM customers 
            GROUP BY customer_segment
            ORDER BY total_revenue DESC
        """,
        'customer_lifetime_value': """
            SELECT 
                c.customer_id,
                CONCAT(c.first_name, ' ', c.last_name) as customer_name,
                c.customer_segment,
                COUNT(o.order_id) as total_orders,
                SUM(o.total_amount) as lifetime_value,
                AVG(o.total_amount) as avg_order_value,
                MIN(o.order_date) as first_purchase,
                MAX(o.order_date) as last_purchase
            FROM customers c
            LEFT JOIN orders o ON c.customer_id = o.customer_id
            GROUP BY c.customer_id, c.first_name, c.last_name, c.customer_segment
            ORDER BY lifetime_value DESC
        """,
        'customer_retention': """
            WITH monthly_customers AS (
                SELECT 
                    DATE_FORMAT(order_date, '%Y-%m') as month,
                    COUNT(DISTINCT customer_id) as active_customers
                FROM orders
                GROUP BY DATE_FORMAT(order_date, '%Y-%m')
            )
            SELECT 
                month,
                active_customers,
                LAG(active_customers) OVER (ORDER BY month) as prev_month_customers,
                ROUND(
                    (active_customers - LAG(active_customers) OVER (ORDER BY month)) * 100.0 / 
                    LAG(active_customers) OVER (ORDER BY month), 2
                ) as growth_rate_percent
            FROM monthly_customers
            ORDER BY month
        """
    }
    
    for query_name, query in queries.items():
        try:
            results = execute_analytics_query(connection, query)
            upload_to_s3(
                results, 
                bucket, 
                f'analytics/customers/{query_name}_{timestamp}.json'
            )
        except Exception as e:
            print(f"Error processing {query_name}: {str(e)}")

def process_product_analytics(connection, bucket: str, timestamp: str):
    """Process product analytics data"""
    queries = {
        'product_performance': """
            SELECT 
                p.product_name,
                p.category,
                p.brand,
                COUNT(oi.order_item_id) as times_ordered,
                SUM(oi.quantity) as total_quantity_sold,
                SUM(oi.total_price) as total_revenue,
                AVG(oi.unit_price) as avg_selling_price,
                AVG(r.rating) as avg_rating,
                COUNT(r.review_id) as total_reviews
            FROM products p
            LEFT JOIN order_items oi ON p.product_id = oi.product_id
            LEFT JOIN reviews r ON p.product_id = r.product_id
            GROUP BY p.product_id, p.product_name, p.category, p.brand
            ORDER BY total_revenue DESC
        """,
        'category_analysis': """
            SELECT 
                p.category,
                COUNT(DISTINCT p.product_id) as total_products,
                COUNT(oi.order_item_id) as total_orders,
                SUM(oi.total_price) as category_revenue,
                AVG(oi.unit_price) as avg_price,
                SUM(oi.quantity) as total_quantity_sold
            FROM products p
            LEFT JOIN order_items oi ON p.product_id = oi.product_id
            GROUP BY p.category
            ORDER BY category_revenue DESC
        """,
        'inventory_turnover': """
            SELECT 
                p.product_id,
                p.product_name,
                p.category,
                p.stock_quantity,
                COALESCE(SUM(oi.quantity), 0) as total_sold,
                CASE 
                    WHEN p.stock_quantity > 0 THEN 
                        COALESCE(SUM(oi.quantity) / p.stock_quantity, 0)
                    ELSE 0
                END as turnover_ratio
            FROM products p
            LEFT JOIN order_items oi ON p.product_id = oi.product_id
            GROUP BY p.product_id, p.product_name, p.category, p.stock_quantity
            ORDER BY turnover_ratio DESC
        """
    }
    
    for query_name, query in queries.items():
        try:
            results = execute_analytics_query(connection, query)
            upload_to_s3(
                results, 
                bucket, 
                f'analytics/products/{query_name}_{timestamp}.json'
            )
        except Exception as e:
            print(f"Error processing {query_name}: {str(e)}")

def process_sales_analytics(connection, bucket: str, timestamp: str):
    """Process sales analytics data"""
    queries = {
        'monthly_sales': """
            SELECT 
                DATE_FORMAT(order_date, '%Y-%m') as month,
                COUNT(order_id) as total_orders,
                SUM(total_amount) as total_revenue,
                AVG(total_amount) as avg_order_value,
                SUM(shipping_cost) as total_shipping,
                SUM(tax_amount) as total_tax,
                SUM(discount_amount) as total_discounts
            FROM orders
            WHERE order_date >= '2023-01-01'
            GROUP BY DATE_FORMAT(order_date, '%Y-%m')
            ORDER BY month
        """,
        'payment_methods': """
            SELECT 
                p.payment_method,
                COUNT(p.payment_id) as transaction_count,
                SUM(p.amount) as total_amount,
                AVG(p.amount) as avg_transaction_amount,
                COUNT(p.payment_id) * 100.0 / (SELECT COUNT(*) FROM payments) as percentage_of_transactions
            FROM payments p
            GROUP BY p.payment_method
            ORDER BY total_amount DESC
        """,
        'geographic_sales': """
            SELECT 
                c.state,
                COUNT(DISTINCT c.customer_id) as customer_count,
                COUNT(o.order_id) as total_orders,
                SUM(o.total_amount) as total_revenue,
                AVG(o.total_amount) as avg_order_value
            FROM customers c
            LEFT JOIN orders o ON c.customer_id = o.customer_id
            GROUP BY c.state
            ORDER BY total_revenue DESC
        """
    }
    
    for query_name, query in queries.items():
        try:
            results = execute_analytics_query(connection, query)
            upload_to_s3(
                results, 
                bucket, 
                f'analytics/sales/{query_name}_{timestamp}.json'
            )
        except Exception as e:
            print(f"Error processing {query_name}: {str(e)}")

def create_athena_table_definition(bucket: str, timestamp: str):
    """Create Athena table definition for the data lake"""
    table_definitions = {
        'customer_segments': {
            'columns': [
                'customer_segment STRING',
                'customer_count BIGINT',
                'total_revenue DECIMAL(10,2)',
                'avg_spent DECIMAL(10,2)',
                'max_spent DECIMAL(10,2)',
                'min_spent DECIMAL(10,2)'
            ],
            'location': f's3://{bucket}/analytics/customers/'
        },
        'product_performance': {
            'columns': [
                'product_name STRING',
                'category STRING',
                'brand STRING',
                'times_ordered BIGINT',
                'total_quantity_sold BIGINT',
                'total_revenue DECIMAL(10,2)',
                'avg_selling_price DECIMAL(10,2)',
                'avg_rating DECIMAL(3,2)',
                'total_reviews BIGINT'
            ],
            'location': f's3://{bucket}/analytics/products/'
        }
    }
    
    for table_name, definition in table_definitions.items():
        create_table_sql = f"""
        CREATE EXTERNAL TABLE IF NOT EXISTS ecommerce_analytics.{table_name} (
            {', '.join(definition['columns'])}
        )
        ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
        LOCATION '{definition['location']}'
        """
        
        # Store table definition in S3 for reference
        upload_to_s3(
            create_table_sql,
            bucket,
            f'metadata/athena_tables/{table_name}_definition.sql'
        )

def lambda_handler(event, context):
    """
    Main Lambda handler function
    Processes e-commerce analytics data and exports to S3
    """
    try:
        # Get environment variables
        bucket = os.environ['S3_BUCKET']
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        print(f"Starting data processing at {timestamp}")
        
        # Connect to database
        connection = get_db_connection()
        
        try:
            # Process different types of analytics
            process_customer_analytics(connection, bucket, timestamp)
            process_product_analytics(connection, bucket, timestamp)
            process_sales_analytics(connection, bucket, timestamp)
            
            # Create Athena table definitions
            create_athena_table_definition(bucket, timestamp)
            
            # Create processing summary
            summary = {
                'processing_timestamp': timestamp,
                'status': 'success',
                'files_processed': [
                    'customer_segments',
                    'customer_lifetime_value', 
                    'customer_retention',
                    'product_performance',
                    'category_analysis',
                    'inventory_turnover',
                    'monthly_sales',
                    'payment_methods',
                    'geographic_sales'
                ],
                's3_bucket': bucket,
                'lambda_function': context.function_name,
                'execution_time': context.get_remaining_time_in_millis()
            }
            
            upload_to_s3(
                summary,
                bucket,
                f'processing_summary_{timestamp}.json'
            )
            
            print("Data processing completed successfully")
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Data processing completed successfully',
                    'timestamp': timestamp,
                    'files_processed': len(summary['files_processed'])
                })
            }
            
        finally:
            connection.close()
            
    except Exception as e:
        error_message = f"Error in data processing: {str(e)}"
        print(error_message)
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_message,
                'timestamp': datetime.now().isoformat()
            })
        }
