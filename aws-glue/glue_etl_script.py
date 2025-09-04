import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import functions as F
from pyspark.sql.types import *
from datetime import datetime

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)

args = getResolvedOptions(sys.argv, [
    'JOB_NAME',
    'RDS_CONNECTION_NAME',
    'S3_OUTPUT_PATH',
    'DATABASE_NAME'
])

job.init(args['JOB_NAME'], args)

customer_schema = StructType([
    StructField("customer_id", IntegerType(), True),
    StructField("first_name", StringType(), True),
    StructField("last_name", StringType(), True),
    StructField("email", StringType(), True),
    StructField("phone", StringType(), True),
    StructField("address", StringType(), True),
    StructField("city", StringType(), True),
    StructField("state", StringType(), True),
    StructField("zip_code", StringType(), True),
    StructField("country", StringType(), True),
    StructField("registration_date", DateType(), True),
    StructField("customer_segment", StringType(), True),
    StructField("total_spent", DecimalType(10,2), True),
    StructField("last_purchase_date", DateType(), True)
])

order_schema = StructType([
    StructField("order_id", IntegerType(), True),
    StructField("customer_id", IntegerType(), True),
    StructField("order_date", TimestampType(), True),
    StructField("status", StringType(), True),
    StructField("total_amount", DecimalType(10,2), True),
    StructField("shipping_address", StringType(), True),
    StructField("shipping_city", StringType(), True),
    StructField("shipping_state", StringType(), True),
    StructField("shipping_zip", StringType(), True),
    StructField("shipping_cost", DecimalType(8,2), True),
    StructField("tax_amount", DecimalType(8,2), True),
    StructField("discount_amount", DecimalType(8,2), True),
    StructField("promo_code", StringType(), True)
])

product_schema = StructType([
    StructField("product_id", IntegerType(), True),
    StructField("product_name", StringType(), True),
    StructField("category", StringType(), True),
    StructField("subcategory", StringType(), True),
    StructField("brand", StringType(), True),
    StructField("price", DecimalType(10,2), True),
    StructField("cost", DecimalType(10,2), True),
    StructField("stock_quantity", IntegerType(), True),
    StructField("description", StringType(), True),
    StructField("created_date", DateType(), True),
    StructField("is_active", BooleanType(), True)
])

order_item_schema = StructType([
    StructField("order_item_id", IntegerType(), True),
    StructField("order_id", IntegerType(), True),
    StructField("product_id", IntegerType(), True),
    StructField("quantity", IntegerType(), True),
    StructField("unit_price", DecimalType(10,2), True),
    StructField("total_price", DecimalType(10,2), True)
])

review_schema = StructType([
    StructField("review_id", IntegerType(), True),
    StructField("customer_id", IntegerType(), True),
    StructField("product_id", IntegerType(), True),
    StructField("order_id", IntegerType(), True),
    StructField("rating", IntegerType(), True),
    StructField("review_title", StringType(), True),
    StructField("review_text", StringType(), True),
    StructField("review_date", TimestampType(), True),
    StructField("is_verified_purchase", BooleanType(), True),
    StructField("helpful_votes", IntegerType(), True)
])

payment_schema = StructType([
    StructField("payment_id", IntegerType(), True),
    StructField("order_id", IntegerType(), True),
    StructField("payment_method", StringType(), True),
    StructField("payment_status", StringType(), True),
    StructField("amount", DecimalType(10,2), True),
    StructField("payment_date", TimestampType(), True),
    StructField("transaction_id", StringType(), True),
    StructField("refund_amount", DecimalType(10,2), True),
    StructField("refund_date", TimestampType(), True)
])

def extract_data_from_rds(table_name, schema):
    try:
        dynamic_frame = glueContext.create_dynamic_frame.from_options(
            connection_type="mysql",
            connection_options={
                "url": f"jdbc:mysql://your-rds-endpoint:3306/{args['DATABASE_NAME']}",
                "dbtable": table_name,
                "user": "admin",
                "password": "your-password"
            },
            transformation_ctx=f"extract_{table_name}"
        )
        
        df = dynamic_frame.toDF()
        df = spark.createDataFrame(df.rdd, schema)
        
        return df
    except Exception as e:
        print(f"Error extracting {table_name}: {str(e)}")
        return None

def transform_customer_data(customers_df):
    if customers_df is None:
        return None
    
    customers_transformed = customers_df.withColumn(
        "full_name", 
        F.concat(F.col("first_name"), F.lit(" "), F.col("last_name"))
    ).withColumn(
        "customer_lifespan_days",
        F.datediff(F.current_date(), F.col("registration_date"))
    ).withColumn(
        "days_since_last_purchase",
        F.when(F.col("last_purchase_date").isNotNull(),
               F.datediff(F.current_date(), F.col("last_purchase_date")))
        .otherwise(None)
    ).withColumn(
        "is_active_customer",
        F.when(F.col("days_since_last_purchase") <= 90, True)
        .otherwise(False)
    ).withColumn(
        "value_tier",
        F.when(F.col("total_spent") >= 2000, "High Value")
        .when(F.col("total_spent") >= 1000, "Medium Value")
        .when(F.col("total_spent") >= 500, "Low Value")
        .otherwise("Very Low Value")
    )
    
    return customers_transformed

def transform_order_data(orders_df, order_items_df):
    if orders_df is None or order_items_df is None:
        return None
    
    orders_with_items = orders_df.join(
        order_items_df, 
        orders_df.order_id == order_items_df.order_id, 
        "left"
    )
    
    order_metrics = orders_with_items.groupBy("order_id").agg(
        F.first("customer_id").alias("customer_id"),
        F.first("order_date").alias("order_date"),
        F.first("status").alias("status"),
        F.first("total_amount").alias("total_amount"),
        F.first("shipping_cost").alias("shipping_cost"),
        F.first("tax_amount").alias("tax_amount"),
        F.first("discount_amount").alias("discount_amount"),
        F.sum("quantity").alias("total_items"),
        F.count("product_id").alias("unique_products"),
        F.avg("unit_price").alias("avg_item_price")
    )
    
    orders_transformed = order_metrics.withColumn(
        "order_year", F.year(F.col("order_date"))
    ).withColumn(
        "order_month", F.month(F.col("order_date"))
    ).withColumn(
        "order_quarter", F.quarter(F.col("order_date"))
    ).withColumn(
        "order_day_of_week", F.dayofweek(F.col("order_date"))
    ).withColumn(
        "order_hour", F.hour(F.col("order_date"))
    )
    
    return orders_transformed

def transform_product_data(products_df, order_items_df, reviews_df):
    if products_df is None:
        return None
    
    product_sales = order_items_df.groupBy("product_id").agg(
        F.sum("quantity").alias("total_quantity_sold"),
        F.sum("total_price").alias("total_revenue"),
        F.avg("unit_price").alias("avg_selling_price"),
        F.count("order_item_id").alias("times_ordered")
    )
    
    product_reviews = reviews_df.groupBy("product_id").agg(
        F.avg("rating").alias("avg_rating"),
        F.count("review_id").alias("total_reviews"),
        F.sum("helpful_votes").alias("total_helpful_votes")
    )
    
    products_with_metrics = products_df.join(
        product_sales, 
        products_df.product_id == product_sales.product_id, 
        "left"
    ).join(
        product_reviews,
        products_df.product_id == product_reviews.product_id,
        "left"
    )
    
    products_transformed = products_with_metrics.withColumn(
        "profit_margin",
        F.when(F.col("price") > 0,
               (F.col("price") - F.col("cost")) / F.col("price"))
        .otherwise(0)
    ).withColumn(
        "inventory_turnover",
        F.when(F.col("stock_quantity") > 0,
               F.col("total_quantity_sold") / F.col("stock_quantity"))
        .otherwise(0)
    ).withColumn(
        "is_bestseller",
        F.when(F.col("total_quantity_sold") >= 10, True)
        .otherwise(False)
    ).withColumn(
        "rating_category",
        F.when(F.col("avg_rating") >= 4.5, "Excellent")
        .when(F.col("avg_rating") >= 4.0, "Good")
        .when(F.col("avg_rating") >= 3.5, "Average")
        .when(F.col("avg_rating") >= 3.0, "Below Average")
        .otherwise("Poor")
    )
    
    return products_transformed

def create_analytics_tables(customers_df, orders_df, products_df):
    customer_analytics = customers_df.select(
        "customer_id",
        "full_name",
        "customer_segment",
        "total_spent",
        "customer_lifespan_days",
        "days_since_last_purchase",
        "is_active_customer",
        "value_tier"
    )
    
    product_analytics = products_df.select(
        "product_id",
        "product_name",
        "category",
        "brand",
        "price",
        "total_quantity_sold",
        "total_revenue",
        "avg_rating",
        "total_reviews",
        "profit_margin",
        "inventory_turnover",
        "is_bestseller",
        "rating_category"
    )
    
    sales_analytics = orders_df.select(
        "order_id",
        "customer_id",
        "order_date",
        "order_year",
        "order_month",
        "order_quarter",
        "status",
        "total_amount",
        "total_items",
        "unique_products",
        "avg_item_price"
    )
    
    return customer_analytics, product_analytics, sales_analytics

def main():
    try:
        print("Starting E-commerce Analytics ETL Process")
        
        print("Extracting data from RDS...")
        customers_df = extract_data_from_rds("customers", customer_schema)
        orders_df = extract_data_from_rds("orders", order_schema)
        products_df = extract_data_from_rds("products", product_schema)
        order_items_df = extract_data_from_rds("order_items", order_item_schema)
        reviews_df = extract_data_from_rds("reviews", review_schema)
        payments_df = extract_data_from_rds("payments", payment_schema)
        
        print("Transforming data...")
        customers_transformed = transform_customer_data(customers_df)
        orders_transformed = transform_order_data(orders_df, order_items_df)
        products_transformed = transform_product_data(products_df, order_items_df, reviews_df)
        
        print("Creating analytics tables...")
        customer_analytics, product_analytics, sales_analytics = create_analytics_tables(
            customers_transformed, orders_transformed, products_transformed
        )
        
        print("Writing data to S3...")
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        customer_analytics.write \
            .mode("overwrite") \
            .parquet(f"{args['S3_OUTPUT_PATH']}/analytics/customers/{timestamp}/")
        
        product_analytics.write \
            .mode("overwrite") \
            .parquet(f"{args['S3_OUTPUT_PATH']}/analytics/products/{timestamp}/")
        
        sales_analytics.write \
            .mode("overwrite") \
            .parquet(f"{args['S3_OUTPUT_PATH']}/analytics/sales/{timestamp}/")
        
        print("Writing raw data to data lake...")
        customers_df.write \
            .mode("overwrite") \
            .parquet(f"{args['S3_OUTPUT_PATH']}/raw/customers/{timestamp}/")
        
        orders_df.write \
            .mode("overwrite") \
            .parquet(f"{args['S3_OUTPUT_PATH']}/raw/orders/{timestamp}/")
        
        products_df.write \
            .mode("overwrite") \
            .parquet(f"{args['S3_OUTPUT_PATH']}/raw/products/{timestamp}/")
        
        order_items_df.write \
            .mode("overwrite") \
            .parquet(f"{args['S3_OUTPUT_PATH']}/raw/order_items/{timestamp}/")
        
        reviews_df.write \
            .mode("overwrite") \
            .parquet(f"{args['S3_OUTPUT_PATH']}/raw/reviews/{timestamp}/")
        
        payments_df.write \
            .mode("overwrite") \
            .parquet(f"{args['S3_OUTPUT_PATH']}/raw/payments/{timestamp}/")
        
        print("ETL process completed successfully!")
        
    except Exception as e:
        print(f"Error in ETL process: {str(e)}")
        raise

if __name__ == "__main__":
    main()
    job.commit()