import json
import boto3
import pymysql
import os
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Any

s3_client = boto3.client('s3')
athena_client = boto3.client('athena')

def get_db_connection():
    try:
        connection = pymysql.connect(
            host=os.environ['RDS_ENDPOINT'],
            user=os.environ['DB_USERNAME'],
            password=os.environ['DB_PASSWORD'],
            database=os.environ['DB_NAME'],
            port=3306,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        return connection
    except Exception as e:
        print(f"Database connection error: {str(e)}")
        return None

def execute_query(connection, query):
    try:
        with connection.cursor() as cursor:
            cursor.execute(query)
            result = cursor.fetchall()
            return result
    except Exception as e:
        print(f"Query execution error: {str(e)}")
        return None

def process_customer_analytics(connection):
    query = """
    SELECT 
        c.customer_segment,
        COUNT(DISTINCT c.customer_id) as total_customers,
        COUNT(o.order_id) as total_orders,
        SUM(o.total_amount) as total_revenue,
        AVG(o.total_amount) as avg_order_value,
        MAX(o.total_amount) as max_order_value,
        MIN(o.total_amount) as min_order_value
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_segment
    ORDER BY total_revenue DESC
    """
    
    result = execute_query(connection, query)
    if result:
        return {
            'customer_segments': [
                {
                    'segment': row['customer_segment'],
                    'total_customers': row['total_customers'],
                    'total_orders': row['total_orders'],
                    'total_revenue': float(row['total_revenue']) if row['total_revenue'] else 0,
                    'avg_order_value': float(row['avg_order_value']) if row['avg_order_value'] else 0,
                    'max_order_value': float(row['max_order_value']) if row['max_order_value'] else 0,
                    'min_order_value': float(row['min_order_value']) if row['min_order_value'] else 0
                }
                for row in result
            ]
        }
    return None

def process_product_analytics(connection):
    query = """
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
    LIMIT 20
    """
    
    result = execute_query(connection, query)
    if result:
        return {
            'top_products': [
                {
                    'product_name': row['product_name'],
                    'category': row['category'],
                    'brand': row['brand'],
                    'times_ordered': row['times_ordered'],
                    'total_quantity_sold': row['total_quantity_sold'],
                    'total_revenue': float(row['total_revenue']) if row['total_revenue'] else 0,
                    'avg_selling_price': float(row['avg_selling_price']) if row['avg_selling_price'] else 0,
                    'avg_rating': float(row['avg_rating']) if row['avg_rating'] else 0,
                    'total_reviews': row['total_reviews']
                }
                for row in result
            ]
        }
    return None

def process_sales_analytics(connection):
    query = """
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') as month,
        COUNT(order_id) as total_orders,
        SUM(total_amount) as total_revenue,
        AVG(total_amount) as avg_order_value,
        COUNT(DISTINCT customer_id) as unique_customers
    FROM orders
    WHERE order_date >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
    ORDER BY month
    """
    
    result = execute_query(connection, query)
    if result:
        return {
            'monthly_sales': [
                {
                    'month': row['month'],
                    'total_orders': row['total_orders'],
                    'total_revenue': float(row['total_revenue']) if row['total_revenue'] else 0,
                    'avg_order_value': float(row['avg_order_value']) if row['avg_order_value'] else 0,
                    'unique_customers': row['unique_customers']
                }
                for row in result
            ]
        }
    return None

def process_payment_analytics(connection):
    query = """
    SELECT 
        p.payment_method,
        COUNT(p.payment_id) as transaction_count,
        SUM(p.amount) as total_amount,
        AVG(p.amount) as avg_transaction_amount,
        COUNT(CASE WHEN p.payment_status = 'Completed' THEN 1 END) as successful_transactions,
        COUNT(CASE WHEN p.payment_status = 'Failed' THEN 1 END) as failed_transactions
    FROM payments p
    GROUP BY p.payment_method
    ORDER BY total_amount DESC
    """
    
    result = execute_query(connection, query)
    if result:
        return {
            'payment_methods': [
                {
                    'payment_method': row['payment_method'],
                    'transaction_count': row['transaction_count'],
                    'total_amount': float(row['total_amount']) if row['total_amount'] else 0,
                    'avg_transaction_amount': float(row['avg_transaction_amount']) if row['avg_transaction_amount'] else 0,
                    'successful_transactions': row['successful_transactions'],
                    'failed_transactions': row['failed_transactions'],
                    'success_rate': round((row['successful_transactions'] / row['transaction_count']) * 100, 2) if row['transaction_count'] > 0 else 0
                }
                for row in result
            ]
        }
    return None

def export_to_s3(data, bucket_name, key_prefix):
    try:
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        for data_type, data_content in data.items():
            if data_content:
                key = f"{key_prefix}/{data_type}/{timestamp}.json"
                s3_client.put_object(
                    Bucket=bucket_name,
                    Key=key,
                    Body=json.dumps(data_content, default=str),
                    ContentType='application/json'
                )
                print(f"Exported {data_type} to s3://{bucket_name}/{key}")
        
        return True
    except Exception as e:
        print(f"Error exporting to S3: {str(e)}")
        return False

def lambda_handler(event, context):
    try:
        print(f"Processing event: {json.dumps(event)}")
        
        connection = get_db_connection()
        if not connection:
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'error': 'Database connection failed',
                    'timestamp': datetime.now().isoformat()
                })
            }
        
        analytics_data = {}
        
        if event.get('process_customers', True):
            print("Processing customer analytics...")
            analytics_data['customers'] = process_customer_analytics(connection)
        
        if event.get('process_products', True):
            print("Processing product analytics...")
            analytics_data['products'] = process_product_analytics(connection)
        
        if event.get('process_sales', True):
            print("Processing sales analytics...")
            analytics_data['sales'] = process_sales_analytics(connection)
        
        if event.get('process_payments', True):
            print("Processing payment analytics...")
            analytics_data['payments'] = process_payment_analytics(connection)
        
        connection.close()
        
        if event.get('export_to_s3', True):
            bucket_name = os.environ.get('S3_BUCKET_NAME', 'ecommerce-analytics-bucket')
            key_prefix = os.environ.get('S3_KEY_PREFIX', 'analytics')
            
            export_success = export_to_s3(analytics_data, bucket_name, key_prefix)
            
            if export_success:
                return {
                    'statusCode': 200,
                    'body': json.dumps({
                        'message': 'Analytics processing and export completed successfully',
                        'data_processed': list(analytics_data.keys()),
                        'timestamp': datetime.now().isoformat()
                    })
                }
            else:
                return {
                    'statusCode': 500,
                    'body': json.dumps({
                        'error': 'Analytics processing completed but S3 export failed',
                        'data_processed': list(analytics_data.keys()),
                        'timestamp': datetime.now().isoformat()
                    })
                }
        else:
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Analytics processing completed successfully',
                    'data': analytics_data,
                    'timestamp': datetime.now().isoformat()
                })
            }
        
    except Exception as e:
        print(f"Error in lambda_handler: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            })
        }