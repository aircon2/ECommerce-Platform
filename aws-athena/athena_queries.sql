-- AWS Athena Queries for E-commerce Analytics Data Lake
-- These queries work with data stored in S3 and processed by Lambda functions

-- =============================================================================
-- ATHENA TABLE CREATION QUERIES
-- =============================================================================

-- Create database for e-commerce analytics
CREATE DATABASE IF NOT EXISTS ecommerce_analytics;

-- Customer Segments Table
CREATE EXTERNAL TABLE IF NOT EXISTS ecommerce_analytics.customer_segments (
    customer_segment STRING,
    customer_count BIGINT,
    total_revenue DECIMAL(10,2),
    avg_spent DECIMAL(10,2),
    max_spent DECIMAL(10,2),
    min_spent DECIMAL(10,2)
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://your-bucket-name/analytics/customers/'
TBLPROPERTIES ('has_encrypted_data'='false');

-- Customer Lifetime Value Table
CREATE EXTERNAL TABLE IF NOT EXISTS ecommerce_analytics.customer_lifetime_value (
    customer_id BIGINT,
    customer_name STRING,
    customer_segment STRING,
    total_orders BIGINT,
    lifetime_value DECIMAL(10,2),
    avg_order_value DECIMAL(10,2),
    first_purchase STRING,
    last_purchase STRING
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://your-bucket-name/analytics/customers/'
TBLPROPERTIES ('has_encrypted_data'='false');

-- Product Performance Table
CREATE EXTERNAL TABLE IF NOT EXISTS ecommerce_analytics.product_performance (
    product_name STRING,
    category STRING,
    brand STRING,
    times_ordered BIGINT,
    total_quantity_sold BIGINT,
    total_revenue DECIMAL(10,2),
    avg_selling_price DECIMAL(10,2),
    avg_rating DECIMAL(3,2),
    total_reviews BIGINT
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://your-bucket-name/analytics/products/'
TBLPROPERTIES ('has_encrypted_data'='false');

-- Monthly Sales Table
CREATE EXTERNAL TABLE IF NOT EXISTS ecommerce_analytics.monthly_sales (
    month STRING,
    total_orders BIGINT,
    total_revenue DECIMAL(10,2),
    avg_order_value DECIMAL(10,2),
    total_shipping DECIMAL(8,2),
    total_tax DECIMAL(8,2),
    total_discounts DECIMAL(8,2)
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://your-bucket-name/analytics/sales/'
TBLPROPERTIES ('has_encrypted_data'='false');

-- =============================================================================
-- ANALYTICS QUERIES FOR ATHENA
-- =============================================================================

-- 1. Customer Segment Performance Analysis
SELECT 
    customer_segment,
    customer_count,
    total_revenue,
    avg_spent,
    ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER(), 2) as revenue_percentage
FROM ecommerce_analytics.customer_segments
ORDER BY total_revenue DESC;

-- 2. Top Customers by Lifetime Value
SELECT 
    customer_name,
    customer_segment,
    total_orders,
    lifetime_value,
    avg_order_value,
    ROW_NUMBER() OVER (ORDER BY lifetime_value DESC) as customer_rank
FROM ecommerce_analytics.customer_lifetime_value
WHERE lifetime_value > 0
ORDER BY lifetime_value DESC
LIMIT 20;

-- 3. Product Category Analysis
SELECT 
    category,
    COUNT(*) as product_count,
    SUM(total_revenue) as category_revenue,
    AVG(avg_rating) as avg_category_rating,
    SUM(total_quantity_sold) as total_units_sold
FROM ecommerce_analytics.product_performance
GROUP BY category
ORDER BY category_revenue DESC;

-- 4. Monthly Sales Trend Analysis
SELECT 
    month,
    total_orders,
    total_revenue,
    avg_order_value,
    LAG(total_revenue) OVER (ORDER BY month) as prev_month_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY month)) * 100.0 / 
        LAG(total_revenue) OVER (ORDER BY month), 2
    ) as month_over_month_growth
FROM ecommerce_analytics.monthly_sales
ORDER BY month;

-- 5. High-Value Customer Identification
SELECT 
    customer_segment,
    COUNT(*) as customer_count,
    AVG(lifetime_value) as avg_lifetime_value,
    MAX(lifetime_value) as max_lifetime_value,
    MIN(lifetime_value) as min_lifetime_value
FROM ecommerce_analytics.customer_lifetime_value
WHERE lifetime_value > 0
GROUP BY customer_segment
ORDER BY avg_lifetime_value DESC;

-- 6. Product Performance Ranking
SELECT 
    product_name,
    category,
    total_revenue,
    avg_rating,
    total_reviews,
    RANK() OVER (PARTITION BY category ORDER BY total_revenue DESC) as category_rank,
    RANK() OVER (ORDER BY total_revenue DESC) as overall_rank
FROM ecommerce_analytics.product_performance
WHERE total_revenue > 0
ORDER BY total_revenue DESC;

-- 7. Customer Retention Analysis (if retention data is available)
-- Note: This would require additional data processing to create retention cohorts
WITH monthly_active_customers AS (
    SELECT 
        month,
        total_orders as active_customers
    FROM ecommerce_analytics.monthly_sales
)
SELECT 
    month,
    active_customers,
    LAG(active_customers) OVER (ORDER BY month) as prev_month_active,
    ROUND(
        (active_customers - LAG(active_customers) OVER (ORDER BY month)) * 100.0 / 
        LAG(active_customers) OVER (ORDER BY month), 2
    ) as customer_growth_rate
FROM monthly_active_customers
ORDER BY month;

-- 8. Revenue Distribution Analysis
SELECT 
    CASE 
        WHEN lifetime_value >= 2000 THEN 'High Value (2000+)'
        WHEN lifetime_value >= 1000 THEN 'Medium Value (1000-1999)'
        WHEN lifetime_value >= 500 THEN 'Low Value (500-999)'
        ELSE 'Very Low Value (<500)'
    END as value_segment,
    COUNT(*) as customer_count,
    AVG(lifetime_value) as avg_value,
    SUM(lifetime_value) as total_value
FROM ecommerce_analytics.customer_lifetime_value
WHERE lifetime_value > 0
GROUP BY 
    CASE 
        WHEN lifetime_value >= 2000 THEN 'High Value (2000+)'
        WHEN lifetime_value >= 1000 THEN 'Medium Value (1000-1999)'
        WHEN lifetime_value >= 500 THEN 'Low Value (500-999)'
        ELSE 'Very Low Value (<500)'
    END
ORDER BY avg_value DESC;

-- 9. Product Rating vs Revenue Analysis
SELECT 
    CASE 
        WHEN avg_rating >= 4.5 THEN 'Excellent (4.5+)'
        WHEN avg_rating >= 4.0 THEN 'Good (4.0-4.4)'
        WHEN avg_rating >= 3.5 THEN 'Average (3.5-3.9)'
        WHEN avg_rating >= 3.0 THEN 'Below Average (3.0-3.4)'
        ELSE 'Poor (<3.0)'
    END as rating_category,
    COUNT(*) as product_count,
    AVG(total_revenue) as avg_revenue,
    SUM(total_revenue) as total_revenue
FROM ecommerce_analytics.product_performance
WHERE avg_rating > 0
GROUP BY 
    CASE 
        WHEN avg_rating >= 4.5 THEN 'Excellent (4.5+)'
        WHEN avg_rating >= 4.0 THEN 'Good (4.0-4.4)'
        WHEN avg_rating >= 3.5 THEN 'Average (3.5-3.9)'
        WHEN avg_rating >= 3.0 THEN 'Below Average (3.0-3.4)'
        ELSE 'Poor (<3.0)'
    END
ORDER BY avg_revenue DESC;

-- 10. Executive Summary Dashboard Query
SELECT 
    'Total Revenue' as metric,
    CAST(SUM(total_revenue) AS STRING) as value
FROM ecommerce_analytics.customer_segments
UNION ALL
SELECT 
    'Total Customers',
    CAST(SUM(customer_count) AS STRING)
FROM ecommerce_analytics.customer_segments
UNION ALL
SELECT 
    'Average Order Value',
    CAST(AVG(avg_order_value) AS STRING)
FROM ecommerce_analytics.monthly_sales
UNION ALL
SELECT 
    'Total Products',
    CAST(COUNT(*) AS STRING)
FROM ecommerce_analytics.product_performance
WHERE total_revenue > 0;

-- =============================================================================
-- ADVANCED ATHENA QUERIES
-- =============================================================================

-- 11. Time Series Analysis with Window Functions
SELECT 
    month,
    total_revenue,
    SUM(total_revenue) OVER (ORDER BY month ROWS UNBOUNDED PRECEDING) as cumulative_revenue,
    AVG(total_revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as moving_avg_3_months
FROM ecommerce_analytics.monthly_sales
ORDER BY month;

-- 12. Customer Value Segmentation with Percentiles
SELECT 
    customer_name,
    lifetime_value,
    NTILE(5) OVER (ORDER BY lifetime_value DESC) as value_quintile,
    PERCENT_RANK() OVER (ORDER BY lifetime_value DESC) as percentile_rank
FROM ecommerce_analytics.customer_lifetime_value
WHERE lifetime_value > 0
ORDER BY lifetime_value DESC;

-- 13. Product Performance vs Market Average
WITH market_averages AS (
    SELECT 
        AVG(total_revenue) as avg_revenue,
        AVG(avg_rating) as avg_rating,
        AVG(total_quantity_sold) as avg_quantity
    FROM ecommerce_analytics.product_performance
    WHERE total_revenue > 0
)
SELECT 
    p.product_name,
    p.category,
    p.total_revenue,
    p.avg_rating,
    p.total_quantity_sold,
    ROUND(p.total_revenue / m.avg_revenue, 2) as revenue_vs_avg,
    ROUND(p.avg_rating / m.avg_rating, 2) as rating_vs_avg,
    ROUND(p.total_quantity_sold / m.avg_quantity, 2) as quantity_vs_avg
FROM ecommerce_analytics.product_performance p
CROSS JOIN market_averages m
WHERE p.total_revenue > 0
ORDER BY revenue_vs_avg DESC;

-- 14. Customer Acquisition Cost Analysis (simplified)
-- Note: This would require additional cost data
SELECT 
    customer_segment,
    COUNT(*) as customers_acquired,
    SUM(total_revenue) as total_revenue_generated,
    ROUND(SUM(total_revenue) / COUNT(*), 2) as revenue_per_customer
FROM ecommerce_analytics.customer_lifetime_value
WHERE lifetime_value > 0
GROUP BY customer_segment
ORDER BY revenue_per_customer DESC;
