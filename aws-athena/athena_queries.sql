CREATE DATABASE IF NOT EXISTS ecommerce_analytics;

CREATE EXTERNAL TABLE IF NOT EXISTS ecommerce_analytics.customer_segments (
    customer_segment STRING,
    customer_count BIGINT,
    total_revenue DECIMAL(10,2),
    avg_spent DECIMAL(10,2),
    max_spent DECIMAL(10,2),
    min_spent DECIMAL(10,2)
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://ecommerce-analytics-bucket/analytics/customers/';

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
LOCATION 's3://ecommerce-analytics-bucket/analytics/products/';

CREATE EXTERNAL TABLE IF NOT EXISTS ecommerce_analytics.monthly_sales (
    month STRING,
    total_orders BIGINT,
    total_revenue DECIMAL(10,2),
    avg_order_value DECIMAL(10,2),
    unique_customers BIGINT
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://ecommerce-analytics-bucket/analytics/sales/';

CREATE EXTERNAL TABLE IF NOT EXISTS ecommerce_analytics.payment_methods (
    payment_method STRING,
    transaction_count BIGINT,
    total_amount DECIMAL(10,2),
    avg_transaction_amount DECIMAL(10,2),
    successful_transactions BIGINT,
    failed_transactions BIGINT,
    success_rate DECIMAL(5,2)
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://ecommerce-analytics-bucket/analytics/payments/';

SELECT 
    customer_segment,
    customer_count,
    total_revenue,
    avg_spent,
    ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER(), 2) as revenue_percentage
FROM ecommerce_analytics.customer_segments
ORDER BY total_revenue DESC;

SELECT 
    product_name,
    category,
    total_revenue,
    total_quantity_sold,
    avg_rating,
    ROW_NUMBER() OVER (ORDER BY total_revenue DESC) as revenue_rank
FROM ecommerce_analytics.product_performance
WHERE total_revenue > 0
ORDER BY total_revenue DESC
LIMIT 10;

SELECT 
    month,
    total_orders,
    total_revenue,
    avg_order_value,
    unique_customers,
    LAG(total_revenue) OVER (ORDER BY month) as prev_month_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY month)) * 100.0 / 
        LAG(total_revenue) OVER (ORDER BY month), 2
    ) as month_over_month_growth
FROM ecommerce_analytics.monthly_sales
ORDER BY month;

SELECT 
    payment_method,
    transaction_count,
    total_amount,
    success_rate,
    ROUND(total_amount * 100.0 / SUM(total_amount) OVER(), 2) as volume_percentage
FROM ecommerce_analytics.payment_methods
ORDER BY total_amount DESC;

SELECT 
    category,
    COUNT(*) as product_count,
    SUM(total_revenue) as category_revenue,
    AVG(avg_rating) as avg_category_rating,
    SUM(total_quantity_sold) as total_units_sold
FROM ecommerce_analytics.product_performance
WHERE total_revenue > 0
GROUP BY category
ORDER BY category_revenue DESC;

SELECT 
    customer_segment,
    customer_count,
    total_revenue,
    ROUND(total_revenue / customer_count, 2) as revenue_per_customer,
    ROUND(customer_count * 100.0 / SUM(customer_count) OVER(), 2) as customer_percentage
FROM ecommerce_analytics.customer_segments
ORDER BY revenue_per_customer DESC;

WITH monthly_trends AS (
    SELECT 
        month,
        total_revenue,
        AVG(total_revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as moving_avg_3_months,
        AVG(total_revenue) OVER (ORDER BY month ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) as moving_avg_6_months
    FROM ecommerce_analytics.monthly_sales
)
SELECT 
    month,
    total_revenue,
    ROUND(moving_avg_3_months, 2) as moving_avg_3_months,
    ROUND(moving_avg_6_months, 2) as moving_avg_6_months,
    CASE 
        WHEN total_revenue > moving_avg_3_months THEN 'Above Trend'
        WHEN total_revenue < moving_avg_3_months THEN 'Below Trend'
        ELSE 'On Trend'
    END as trend_status
FROM monthly_trends
ORDER BY month;

SELECT 
    payment_method,
    transaction_count,
    successful_transactions,
    failed_transactions,
    success_rate,
    ROUND(avg_transaction_amount, 2) as avg_transaction_amount,
    ROUND(total_amount, 2) as total_amount
FROM ecommerce_analytics.payment_methods
WHERE transaction_count > 0
ORDER BY success_rate DESC, total_amount DESC;

SELECT 
    product_name,
    brand,
    total_revenue,
    avg_rating,
    total_reviews,
    CASE 
        WHEN avg_rating >= 4.5 THEN 'Excellent'
        WHEN avg_rating >= 4.0 THEN 'Good'
        WHEN avg_rating >= 3.5 THEN 'Average'
        WHEN avg_rating >= 3.0 THEN 'Below Average'
        ELSE 'Poor'
    END as rating_category
FROM ecommerce_analytics.product_performance
WHERE total_revenue > 0 AND avg_rating > 0
ORDER BY avg_rating DESC, total_revenue DESC
LIMIT 15;

SELECT 
    'Total Revenue' as metric,
    ROUND(SUM(total_revenue), 2) as value
FROM ecommerce_analytics.monthly_sales
UNION ALL
SELECT 
    'Total Orders',
    SUM(total_orders)
FROM ecommerce_analytics.monthly_sales
UNION ALL
SELECT 
    'Total Customers',
    SUM(unique_customers)
FROM ecommerce_analytics.monthly_sales
UNION ALL
SELECT 
    'Average Order Value',
    ROUND(AVG(avg_order_value), 2)
FROM ecommerce_analytics.monthly_sales;