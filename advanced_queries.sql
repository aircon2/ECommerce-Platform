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
    COUNT(DISTINCT c.customer_id) as customers_retained,
    ROUND(COUNT(DISTINCT c.customer_id) * 100.0 / cs.cohort_size, 2) as retention_rate
FROM customer_cohorts c
JOIN cohort_sizes cs ON c.cohort_month = cs.cohort_month
GROUP BY c.cohort_month, cs.cohort_size, c.period_number
ORDER BY c.cohort_month, c.period_number;

WITH customer_metrics AS (
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
),
customer_rankings AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY lifetime_value DESC) as revenue_rank,
        RANK() OVER (ORDER BY lifetime_value DESC) as rank_with_ties,
        DENSE_RANK() OVER (ORDER BY lifetime_value DESC) as dense_rank,
        PERCENT_RANK() OVER (ORDER BY lifetime_value DESC) as percentile_rank,
        NTILE(4) OVER (ORDER BY lifetime_value DESC) as value_quartile
    FROM customer_metrics
)
SELECT 
    customer_name,
    customer_segment,
    total_orders,
    lifetime_value,
    avg_order_value,
    customer_lifespan_days,
    revenue_rank,
    value_quartile,
    CASE 
        WHEN value_quartile = 1 THEN 'Top 25%'
        WHEN value_quartile = 2 THEN 'Upper Middle 25%'
        WHEN value_quartile = 3 THEN 'Lower Middle 25%'
        ELSE 'Bottom 25%'
    END as value_tier
FROM customer_rankings
ORDER BY lifetime_value DESC;

WITH product_metrics AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.category,
        p.brand,
        p.price,
        p.cost,
        COALESCE(SUM(oi.quantity), 0) as total_sold,
        COALESCE(SUM(oi.total_price), 0) as total_revenue,
        COALESCE(AVG(r.rating), 0) as avg_rating,
        COALESCE(COUNT(r.review_id), 0) as review_count,
        COALESCE(COUNT(DISTINCT oi.order_id), 0) as times_ordered
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN reviews r ON p.product_id = r.product_id
    GROUP BY p.product_id, p.product_name, p.category, p.brand, p.price, p.cost
),
product_rankings AS (
    SELECT 
        *,
        (price - cost) as profit_per_unit,
        CASE WHEN price > 0 THEN (price - cost) / price ELSE 0 END as profit_margin,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_revenue DESC) as category_rank,
        RANK() OVER (ORDER BY total_revenue DESC) as overall_rank,
        LAG(total_revenue) OVER (ORDER BY total_revenue DESC) as prev_product_revenue,
        LEAD(total_revenue) OVER (ORDER BY total_revenue DESC) as next_product_revenue
    FROM product_metrics
)
SELECT 
    product_name,
    category,
    brand,
    price,
    total_sold,
    total_revenue,
    avg_rating,
    review_count,
    profit_margin,
    category_rank,
    overall_rank,
    CASE 
        WHEN category_rank = 1 THEN 'Category Leader'
        WHEN category_rank <= 3 THEN 'Top 3 in Category'
        WHEN category_rank <= 5 THEN 'Top 5 in Category'
        ELSE 'Other'
    END as performance_tier
FROM product_rankings
WHERE total_revenue > 0
ORDER BY total_revenue DESC;

WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') as month,
        COUNT(order_id) as total_orders,
        SUM(total_amount) as total_revenue,
        AVG(total_amount) as avg_order_value,
        COUNT(DISTINCT customer_id) as unique_customers
    FROM orders
    WHERE order_date >= '2023-01-01'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
),
monthly_with_trends AS (
    SELECT 
        *,
        LAG(total_revenue) OVER (ORDER BY month) as prev_month_revenue,
        LEAD(total_revenue) OVER (ORDER BY month) as next_month_revenue,
        AVG(total_revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as moving_avg_3_months,
        AVG(total_revenue) OVER (ORDER BY month ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) as moving_avg_6_months,
        SUM(total_revenue) OVER (ORDER BY month ROWS UNBOUNDED PRECEDING) as cumulative_revenue
    FROM monthly_sales
)
SELECT 
    month,
    total_orders,
    total_revenue,
    avg_order_value,
    unique_customers,
    ROUND(
        (total_revenue - prev_month_revenue) * 100.0 / prev_month_revenue, 2
    ) as month_over_month_growth,
    ROUND(moving_avg_3_months, 2) as moving_avg_3_months,
    ROUND(moving_avg_6_months, 2) as moving_avg_6_months,
    ROUND(cumulative_revenue, 2) as cumulative_revenue
FROM monthly_with_trends
ORDER BY month;

WITH customer_rfm AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) as customer_name,
        c.customer_segment,
        DATEDIFF(CURRENT_DATE, MAX(o.order_date)) as recency_days,
        COUNT(o.order_id) as frequency,
        SUM(o.total_amount) as monetary_value,
        AVG(o.total_amount) as avg_order_value
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.customer_segment
),
rfm_scores AS (
    SELECT 
        *,
        CASE 
            WHEN recency_days <= 30 THEN 5
            WHEN recency_days <= 60 THEN 4
            WHEN recency_days <= 90 THEN 3
            WHEN recency_days <= 180 THEN 2
            ELSE 1
        END as recency_score,
        CASE 
            WHEN frequency >= 10 THEN 5
            WHEN frequency >= 7 THEN 4
            WHEN frequency >= 4 THEN 3
            WHEN frequency >= 2 THEN 2
            ELSE 1
        END as frequency_score,
        CASE 
            WHEN monetary_value >= 2000 THEN 5
            WHEN monetary_value >= 1000 THEN 4
            WHEN monetary_value >= 500 THEN 3
            WHEN monetary_value >= 200 THEN 2
            ELSE 1
        END as monetary_score
    FROM customer_rfm
),
rfm_segments AS (
    SELECT 
        *,
        CONCAT(recency_score, frequency_score, monetary_score) as rfm_score,
        CASE 
            WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
            WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Customers'
            WHEN recency_score >= 3 AND frequency_score >= 2 AND monetary_score >= 2 THEN 'Potential Loyalists'
            WHEN recency_score >= 4 AND frequency_score <= 1 AND monetary_score <= 1 THEN 'Promising'
            WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score <= 2 THEN 'Need Attention'
            WHEN recency_score >= 2 AND frequency_score >= 2 AND monetary_score >= 3 THEN 'About to Sleep'
            WHEN recency_score <= 2 AND frequency_score >= 2 AND monetary_score >= 2 THEN 'At Risk'
            WHEN recency_score <= 2 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Cannot Lose Them'
            WHEN recency_score <= 1 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'Lost'
            ELSE 'Others'
        END as rfm_segment
    FROM rfm_scores
)
SELECT 
    rfm_segment,
    COUNT(*) as customer_count,
    ROUND(AVG(recency_days), 0) as avg_recency_days,
    ROUND(AVG(frequency), 1) as avg_frequency,
    ROUND(AVG(monetary_value), 2) as avg_monetary_value,
    ROUND(SUM(monetary_value), 2) as total_segment_value,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM rfm_segments), 2) as segment_percentage
FROM rfm_segments
GROUP BY rfm_segment
ORDER BY total_segment_value DESC;

WITH category_metrics AS (
    SELECT 
        p.category,
        COUNT(DISTINCT p.product_id) as total_products,
        COUNT(DISTINCT oi.product_id) as products_sold,
        SUM(oi.quantity) as total_quantity_sold,
        SUM(oi.total_price) as total_revenue,
        AVG(oi.unit_price) as avg_selling_price,
        AVG(r.rating) as avg_rating,
        COUNT(r.review_id) as total_reviews
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN reviews r ON p.product_id = r.product_id
    GROUP BY p.category
),
category_rankings AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) as revenue_rank,
        RANK() OVER (ORDER BY total_revenue DESC) as rank_with_ties,
        PERCENT_RANK() OVER (ORDER BY total_revenue DESC) as percentile_rank
    FROM category_metrics
)
SELECT 
    category,
    total_products,
    products_sold,
    ROUND(products_sold * 100.0 / total_products, 2) as product_penetration_rate,
    total_quantity_sold,
    ROUND(total_revenue, 2) as total_revenue,
    ROUND(avg_selling_price, 2) as avg_selling_price,
    ROUND(avg_rating, 2) as avg_rating,
    total_reviews,
    revenue_rank,
    CASE 
        WHEN revenue_rank = 1 THEN 'Top Category'
        WHEN revenue_rank <= 3 THEN 'Top 3 Categories'
        WHEN revenue_rank <= 5 THEN 'Top 5 Categories'
        ELSE 'Other Categories'
    END as performance_tier
FROM category_rankings
ORDER BY total_revenue DESC;

SELECT 
    p.payment_method,
    COUNT(p.payment_id) as transaction_count,
    ROUND(SUM(p.amount), 2) as total_amount,
    ROUND(AVG(p.amount), 2) as avg_transaction_amount,
    ROUND(COUNT(p.payment_id) * 100.0 / (SELECT COUNT(*) FROM payments), 2) as percentage_of_transactions,
    ROUND(SUM(p.amount) * 100.0 / (SELECT SUM(amount) FROM payments), 2) as percentage_of_volume,
    COUNT(CASE WHEN p.payment_status = 'Completed' THEN 1 END) as successful_transactions,
    COUNT(CASE WHEN p.payment_status = 'Failed' THEN 1 END) as failed_transactions,
    ROUND(
        COUNT(CASE WHEN p.payment_status = 'Completed' THEN 1 END) * 100.0 / COUNT(p.payment_id), 2
    ) as success_rate
FROM payments p
GROUP BY p.payment_method
ORDER BY total_amount DESC;

WITH seasonal_data AS (
    SELECT 
        QUARTER(order_date) as quarter,
        MONTHNAME(order_date) as month_name,
        COUNT(order_id) as total_orders,
        SUM(total_amount) as total_revenue,
        AVG(total_amount) as avg_order_value,
        COUNT(DISTINCT customer_id) as unique_customers
    FROM orders
    WHERE order_date >= '2023-01-01'
    GROUP BY QUARTER(order_date), MONTHNAME(order_date)
),
seasonal_analysis AS (
    SELECT 
        *,
        LAG(total_revenue) OVER (ORDER BY quarter, month_name) as prev_month_revenue,
        AVG(total_revenue) OVER (PARTITION BY quarter) as quarterly_avg,
        SUM(total_revenue) OVER (PARTITION BY quarter) as quarterly_total
    FROM seasonal_data
)
SELECT 
    quarter,
    month_name,
    total_orders,
    ROUND(total_revenue, 2) as total_revenue,
    ROUND(avg_order_value, 2) as avg_order_value,
    unique_customers,
    ROUND(quarterly_total, 2) as quarterly_total,
    ROUND(quarterly_avg, 2) as quarterly_avg,
    ROUND(
        (total_revenue - prev_month_revenue) * 100.0 / prev_month_revenue, 2
    ) as month_over_month_growth
FROM seasonal_analysis
ORDER BY quarter, month_name;