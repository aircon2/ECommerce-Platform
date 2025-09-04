-- Advanced E-commerce Analytics Queries
-- Additional complex queries demonstrating advanced SQL techniques

-- =============================================================================
-- ADVANCED WINDOW FUNCTIONS AND ANALYTICS
-- =============================================================================

-- 1. Customer Cohort Analysis
WITH customer_cohorts AS (
    SELECT 
        customer_id,
        DATE_FORMAT(MIN(order_date), '%Y-%m') as cohort_month,
        DATE_FORMAT(order_date, '%Y-%m') as order_month,
        MONTHS_BETWEEN(STR_TO_DATE(DATE_FORMAT(order_date, '%Y-%m'), '%Y-%m'), 
                      STR_TO_DATE(DATE_FORMAT(MIN(order_date), '%Y-%m'), '%Y-%m')) as period_number
    FROM orders
    GROUP BY customer_id, DATE_FORMAT(order_date, '%Y-%m')
),
cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) as cohort_size
    FROM customer_cohorts
    WHERE period_number = 0
    GROUP BY cohort_month
)
SELECT 
    c.cohort_month,
    cs.cohort_size,
    c.period_number,
    COUNT(DISTINCT c.customer_id) as customers,
    ROUND(COUNT(DISTINCT c.customer_id) * 100.0 / cs.cohort_size, 2) as retention_rate
FROM customer_cohorts c
JOIN cohort_sizes cs ON c.cohort_month = cs.cohort_month
GROUP BY c.cohort_month, cs.cohort_size, c.period_number
ORDER BY c.cohort_month, c.period_number;

-- 2. Product Recommendation Engine (Customers who bought X also bought Y)
WITH product_pairs AS (
    SELECT 
        oi1.product_id as product_a,
        oi2.product_id as product_b,
        COUNT(DISTINCT oi1.order_id) as pair_count
    FROM order_items oi1
    INNER JOIN order_items oi2 ON oi1.order_id = oi2.order_id
    WHERE oi1.product_id != oi2.product_id
    GROUP BY oi1.product_id, oi2.product_id
    HAVING COUNT(DISTINCT oi1.order_id) >= 2
),
product_totals AS (
    SELECT 
        product_id,
        COUNT(DISTINCT order_id) as total_orders
    FROM order_items
    GROUP BY product_id
)
SELECT 
    p1.product_name as product_a,
    p2.product_name as product_b,
    pp.pair_count,
    pt1.total_orders as product_a_orders,
    pt2.total_orders as product_b_orders,
    ROUND(pp.pair_count * 100.0 / pt1.total_orders, 2) as confidence_percent
FROM product_pairs pp
JOIN products p1 ON pp.product_a = p1.product_id
JOIN products p2 ON pp.product_b = p2.product_id
JOIN product_totals pt1 ON pp.product_a = pt1.product_id
JOIN product_totals pt2 ON pp.product_b = pt2.product_id
ORDER BY confidence_percent DESC
LIMIT 20;

-- 3. Seasonal Sales Analysis with Year-over-Year Comparison
SELECT 
    MONTH(order_date) as month,
    MONTHNAME(order_date) as month_name,
    YEAR(order_date) as year,
    COUNT(order_id) as order_count,
    SUM(total_amount) as revenue,
    AVG(total_amount) as avg_order_value,
    LAG(SUM(total_amount)) OVER (PARTITION BY MONTH(order_date) ORDER BY YEAR(order_date)) as prev_year_revenue,
    ROUND(
        (SUM(total_amount) - LAG(SUM(total_amount)) OVER (PARTITION BY MONTH(order_date) ORDER BY YEAR(order_date))) * 100.0 / 
        LAG(SUM(total_amount)) OVER (PARTITION BY MONTH(order_date) ORDER BY YEAR(order_date)), 2
    ) as yoy_growth_percent
FROM orders
WHERE order_date >= '2023-01-01'
GROUP BY YEAR(order_date), MONTH(order_date), MONTHNAME(order_date)
ORDER BY month, year;

-- 4. Customer Value Segmentation with RFM Analysis
WITH rfm_analysis AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) as customer_name,
        DATEDIFF(CURDATE(), MAX(o.order_date)) as recency_days,
        COUNT(o.order_id) as frequency,
        SUM(o.total_amount) as monetary_value,
        NTILE(5) OVER (ORDER BY DATEDIFF(CURDATE(), MAX(o.order_date)) DESC) as recency_score,
        NTILE(5) OVER (ORDER BY COUNT(o.order_id)) as frequency_score,
        NTILE(5) OVER (ORDER BY SUM(o.total_amount)) as monetary_score
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
),
rfm_segments AS (
    SELECT 
        *,
        CONCAT(recency_score, frequency_score, monetary_score) as rfm_score,
        CASE 
            WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
            WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Customers'
            WHEN recency_score >= 3 AND frequency_score >= 2 AND monetary_score >= 3 THEN 'Potential Loyalists'
            WHEN recency_score >= 2 AND frequency_score >= 3 AND monetary_score >= 2 THEN 'At Risk'
            WHEN recency_score <= 2 AND frequency_score >= 2 THEN 'Cannot Lose Them'
            WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score >= 2 THEN 'Hibernating'
            ELSE 'Lost'
        END as customer_segment
    FROM rfm_analysis
)
SELECT 
    customer_segment,
    COUNT(*) as customer_count,
    AVG(recency_days) as avg_recency_days,
    AVG(frequency) as avg_frequency,
    AVG(monetary_value) as avg_monetary_value,
    SUM(monetary_value) as total_value
FROM rfm_segments
GROUP BY customer_segment
ORDER BY total_value DESC;

-- 5. Inventory Turnover Analysis
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.stock_quantity,
    COALESCE(SUM(oi.quantity), 0) as total_sold,
    COALESCE(SUM(oi.quantity) / p.stock_quantity, 0) as turnover_ratio,
    CASE 
        WHEN COALESCE(SUM(oi.quantity) / p.stock_quantity, 0) > 2 THEN 'High Turnover'
        WHEN COALESCE(SUM(oi.quantity) / p.stock_quantity, 0) > 1 THEN 'Medium Turnover'
        WHEN COALESCE(SUM(oi.quantity) / p.stock_quantity, 0) > 0 THEN 'Low Turnover'
        ELSE 'No Sales'
    END as turnover_category
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category, p.stock_quantity
ORDER BY turnover_ratio DESC;

-- 6. Customer Churn Prediction Indicators
WITH customer_activity AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) as customer_name,
        c.customer_segment,
        COUNT(o.order_id) as total_orders,
        MAX(o.order_date) as last_order_date,
        DATEDIFF(CURDATE(), MAX(o.order_date)) as days_since_last_order,
        AVG(o.total_amount) as avg_order_value,
        SUM(o.total_amount) as total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.customer_segment
),
churn_indicators AS (
    SELECT 
        *,
        CASE 
            WHEN days_since_last_order > 90 THEN 'High Risk'
            WHEN days_since_last_order > 60 THEN 'Medium Risk'
            WHEN days_since_last_order > 30 THEN 'Low Risk'
            ELSE 'Active'
        END as churn_risk,
        CASE 
            WHEN total_orders = 0 THEN 'Never Purchased'
            WHEN total_orders = 1 THEN 'One-time Buyer'
            WHEN total_orders BETWEEN 2 AND 5 THEN 'Occasional Buyer'
            ELSE 'Regular Buyer'
        END as purchase_behavior
    FROM customer_activity
)
SELECT 
    churn_risk,
    purchase_behavior,
    COUNT(*) as customer_count,
    AVG(total_spent) as avg_total_spent,
    AVG(days_since_last_order) as avg_days_since_order
FROM churn_indicators
GROUP BY churn_risk, purchase_behavior
ORDER BY churn_risk, purchase_behavior;

-- 7. Geographic Sales Analysis
SELECT 
    c.state,
    COUNT(DISTINCT c.customer_id) as customer_count,
    COUNT(o.order_id) as total_orders,
    SUM(o.total_amount) as total_revenue,
    AVG(o.total_amount) as avg_order_value,
    SUM(o.shipping_cost) as total_shipping_cost,
    ROUND(SUM(o.total_amount) / COUNT(DISTINCT c.customer_id), 2) as revenue_per_customer
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.state
ORDER BY total_revenue DESC;

-- 8. Product Category Performance with Market Share
WITH category_performance AS (
    SELECT 
        p.category,
        COUNT(DISTINCT oi.order_id) as order_count,
        SUM(oi.total_price) as category_revenue,
        SUM(oi.quantity) as total_quantity_sold,
        AVG(oi.unit_price) as avg_price
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.category
),
total_market AS (
    SELECT 
        SUM(category_revenue) as total_market_revenue
    FROM category_performance
)
SELECT 
    cp.category,
    cp.order_count,
    cp.category_revenue,
    cp.total_quantity_sold,
    cp.avg_price,
    ROUND(cp.category_revenue * 100.0 / tm.total_market_revenue, 2) as market_share_percent,
    RANK() OVER (ORDER BY cp.category_revenue DESC) as revenue_rank
FROM category_performance cp
CROSS JOIN total_market tm
ORDER BY cp.category_revenue DESC;

-- 9. Time-based Sales Patterns
SELECT 
    HOUR(order_date) as hour_of_day,
    DAYOFWEEK(order_date) as day_of_week,
    DAYNAME(order_date) as day_name,
    COUNT(order_id) as order_count,
    SUM(total_amount) as revenue,
    AVG(total_amount) as avg_order_value
FROM orders
GROUP BY HOUR(order_date), DAYOFWEEK(order_date), DAYNAME(order_date)
ORDER BY day_of_week, hour_of_day;

-- 10. Customer Lifetime Value Prediction
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) as customer_name,
        c.customer_segment,
        COUNT(o.order_id) as total_orders,
        SUM(o.total_amount) as total_spent,
        AVG(o.total_amount) as avg_order_value,
        DATEDIFF(MAX(o.order_date), MIN(o.order_date)) as customer_lifespan_days,
        DATEDIFF(CURDATE(), MAX(o.order_date)) as days_since_last_order
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.customer_segment
),
predicted_clv AS (
    SELECT 
        *,
        CASE 
            WHEN customer_lifespan_days > 0 THEN 
                (total_spent / customer_lifespan_days) * 365 * 3  -- Predict 3 years
            ELSE total_spent
        END as predicted_3_year_clv,
        CASE 
            WHEN days_since_last_order <= 30 THEN 'Active'
            WHEN days_since_last_order <= 90 THEN 'At Risk'
            ELSE 'Inactive'
        END as activity_status
    FROM customer_metrics
)
SELECT 
    customer_segment,
    activity_status,
    COUNT(*) as customer_count,
    AVG(total_spent) as avg_current_value,
    AVG(predicted_3_year_clv) as avg_predicted_clv,
    SUM(predicted_3_year_clv) as total_predicted_value
FROM predicted_clv
GROUP BY customer_segment, activity_status
ORDER BY customer_segment, activity_status;
