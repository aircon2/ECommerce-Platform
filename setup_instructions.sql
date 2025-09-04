CREATE DATABASE IF NOT EXISTS ecommerce_analytics;
USE ecommerce_analytics;

SOURCE database_schema.sql;

SOURCE sample_data.sql;

SELECT 'Customers' as table_name, COUNT(*) as record_count FROM customers
UNION ALL
SELECT 'Products', COUNT(*) FROM products
UNION ALL
SELECT 'Orders', COUNT(*) FROM orders
UNION ALL
SELECT 'Order Items', COUNT(*) FROM order_items
UNION ALL
SELECT 'Reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'Payments', COUNT(*) FROM payments;

SELECT 
    'Database Setup Complete!' as status,
    COUNT(DISTINCT c.customer_id) as total_customers,
    COUNT(o.order_id) as total_orders,
    ROUND(SUM(o.total_amount), 2) as total_revenue
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;

SELECT 'Available Query Files:' as info
UNION ALL
SELECT '1. analytics_queries.sql - Core analytics queries'
UNION ALL
SELECT '2. advanced_queries.sql - Advanced analytical queries'
UNION ALL
SELECT '3. Run individual queries or entire files as needed';