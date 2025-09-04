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
ORDER BY total_revenue DESC;

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
ORDER BY month;

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
ORDER BY total_revenue DESC;

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) as customer_name,
    c.customer_segment,
    COUNT(o.order_id) as total_orders,
    SUM(o.total_amount) as lifetime_value,
    AVG(o.total_amount) as avg_order_value,
    MIN(o.order_date) as first_purchase,
    MAX(o.order_date) as last_purchase,
    DATEDIFF(MAX(o.order_date), MIN(o.order_date)) as customer_lifespan_days
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.customer_segment
ORDER BY lifetime_value DESC;

SELECT 
    o.order_id,
    o.order_date,
    o.status,
    o.total_amount,
    CONCAT(c.first_name, ' ', c.last_name) as customer_name,
    c.email,
    c.customer_segment,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.total_price
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'Delivered'
ORDER BY o.order_date DESC;

SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.price,
    COALESCE(SUM(oi.quantity), 0) as total_sold,
    COALESCE(SUM(oi.total_price), 0) as total_revenue,
    COALESCE(AVG(r.rating), 0) as avg_rating,
    COALESCE(COUNT(r.review_id), 0) as review_count
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name, p.category, p.price
ORDER BY total_revenue DESC;

SELECT 
    p.payment_id,
    p.payment_method,
    p.payment_status,
    p.amount,
    p.payment_date,
    o.order_id,
    o.order_date,
    o.status as order_status,
    CONCAT(c.first_name, ' ', c.last_name) as customer_name
FROM orders o
RIGHT JOIN payments p ON o.order_id = p.order_id
LEFT JOIN customers c ON o.customer_id = c.customer_id
ORDER BY p.payment_date DESC;

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) as customer_name,
    c.customer_segment,
    o.order_id,
    o.order_date,
    o.status,
    o.total_amount,
    p.product_name,
    oi.quantity,
    r.rating,
    r.review_text,
    pay.payment_method,
    pay.payment_status
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.product_id
LEFT JOIN reviews r ON c.customer_id = r.customer_id AND p.product_id = r.product_id
LEFT JOIN payments pay ON o.order_id = pay.order_id
ORDER BY c.customer_id, o.order_date DESC;

SELECT 
    customer_id,
    CONCAT(first_name, ' ', last_name) as customer_name,
    customer_segment,
    total_spent,
    ROW_NUMBER() OVER (ORDER BY total_spent DESC) as revenue_rank,
    RANK() OVER (ORDER BY total_spent DESC) as rank_with_ties,
    DENSE_RANK() OVER (ORDER BY total_spent DESC) as dense_rank,
    PERCENT_RANK() OVER (ORDER BY total_spent DESC) as percentile_rank
FROM customers
ORDER BY total_spent DESC;

SELECT 
    DATE_FORMAT(o.order_date, '%Y-%m') as month,
    p.category,
    SUM(oi.total_price) as monthly_revenue,
    ROW_NUMBER() OVER (PARTITION BY DATE_FORMAT(o.order_date, '%Y-%m') ORDER BY SUM(oi.total_price) DESC) as category_rank,
    RANK() OVER (PARTITION BY DATE_FORMAT(o.order_date, '%Y-%m') ORDER BY SUM(oi.total_price) DESC) as rank_with_ties
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m'), p.category
ORDER BY month, category_rank;

SELECT 
    order_date,
    total_amount,
    SUM(total_amount) OVER (ORDER BY order_date ROWS UNBOUNDED PRECEDING) as running_total,
    AVG(total_amount) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as moving_avg_7_days,
    COUNT(*) OVER (ORDER BY order_date ROWS UNBOUNDED PRECEDING) as cumulative_orders
FROM orders
WHERE order_date >= '2024-01-01'
ORDER BY order_date;

SELECT 
    customer_id,
    CONCAT(first_name, ' ', last_name) as customer_name,
    customer_segment,
    total_spent,
    ROW_NUMBER() OVER (PARTITION BY customer_segment ORDER BY total_spent DESC) as segment_rank,
    LAG(total_spent) OVER (PARTITION BY customer_segment ORDER BY total_spent DESC) as prev_customer_spent,
    LEAD(total_spent) OVER (PARTITION BY customer_segment ORDER BY total_spent DESC) as next_customer_spent
FROM customers
ORDER BY customer_segment, segment_rank;

SELECT 
    p.product_name,
    p.category,
    SUM(oi.total_price) as total_revenue,
    COUNT(oi.order_item_id) as order_count,
    NTILE(4) OVER (ORDER BY SUM(oi.total_price) DESC) as revenue_quartile,
    PERCENT_RANK() OVER (ORDER BY SUM(oi.total_price) DESC) as revenue_percentile,
    CUME_DIST() OVER (ORDER BY SUM(oi.total_price) DESC) as cumulative_distribution
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC;

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) as customer_name,
    c.customer_segment,
    c.total_spent,
    (SELECT AVG(total_spent) FROM customers) as avg_customer_spent,
    c.total_spent - (SELECT AVG(total_spent) FROM customers) as above_avg_amount
FROM customers c
WHERE c.total_spent > (SELECT AVG(total_spent) FROM customers)
ORDER BY c.total_spent DESC;

SELECT 
    p.product_name,
    p.category,
    AVG(r.rating) as avg_rating,
    COUNT(r.review_id) as review_count,
    (SELECT AVG(rating) FROM reviews) as overall_avg_rating
FROM products p
INNER JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name, p.category
HAVING AVG(r.rating) > (SELECT AVG(rating) FROM reviews)
ORDER BY avg_rating DESC;

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
ORDER BY month;

SELECT 
    'Total Customers' as metric,
    COUNT(*) as value,
    NULL as percentage
FROM customers
UNION ALL
SELECT 
    'Total Orders',
    COUNT(*),
    NULL
FROM orders
UNION ALL
SELECT 
    'Total Revenue',
    ROUND(SUM(total_amount), 2),
    NULL
FROM orders
UNION ALL
SELECT 
    'Average Order Value',
    ROUND(AVG(total_amount), 2),
    NULL
FROM orders
UNION ALL
SELECT 
    'Total Products',
    COUNT(*),
    NULL
FROM products
UNION ALL
SELECT 
    'Average Rating',
    ROUND(AVG(rating), 2),
    NULL
FROM reviews;

SELECT 
    p.product_name,
    p.category,
    p.brand,
    SUM(oi.quantity) as total_quantity_sold,
    SUM(oi.total_price) as total_revenue,
    AVG(r.rating) as avg_rating,
    COUNT(r.review_id) as review_count
FROM products p
INNER JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name, p.category, p.brand
ORDER BY total_quantity_sold DESC
LIMIT 10;

SELECT 
    c.customer_segment,
    COUNT(DISTINCT c.customer_id) as total_customers,
    COUNT(o.order_id) as total_orders,
    ROUND(COUNT(o.order_id) / COUNT(DISTINCT c.customer_id), 2) as avg_orders_per_customer,
    ROUND(SUM(o.total_amount) / COUNT(DISTINCT c.customer_id), 2) as avg_revenue_per_customer,
    ROUND(AVG(o.total_amount), 2) as avg_order_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_segment
ORDER BY avg_revenue_per_customer DESC;

SELECT 
    DATE_FORMAT(o.order_date, '%Y-%m') as month,
    p.category,
    COUNT(o.order_id) as order_count,
    SUM(oi.total_price) as revenue,
    AVG(oi.total_price) as avg_order_value
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
WHERE o.order_date >= '2023-01-01'
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m'), p.category
ORDER BY month, revenue DESC;

SELECT 
    p.payment_method,
    COUNT(p.payment_id) as transaction_count,
    SUM(p.amount) as total_amount,
    AVG(p.amount) as avg_transaction_amount,
    COUNT(p.payment_id) * 100.0 / (SELECT COUNT(*) FROM payments) as percentage_of_transactions
FROM payments p
GROUP BY p.payment_method
ORDER BY total_amount DESC;