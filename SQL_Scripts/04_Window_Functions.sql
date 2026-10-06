-- 1. Calculate a 7-day moving average of daily order count
WITH daily_orders AS (
    SELECT 
        DATE(order_purchase_timestamp) AS order_date,
        COUNT(order_id) AS daily_count
    FROM fact_orders
    WHERE order_purchase_timestamp IS NOT NULL
    GROUP BY DATE(order_purchase_timestamp)
)
SELECT 
    order_date,
    daily_count,
    ROUND(
        AVG(daily_count) OVER (
            ORDER BY order_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2
    ) AS moving_avg_7day
FROM daily_orders
ORDER BY order_date;


-- 2. Find gaps between consecutive customer orders using LAG()
WITH customer_orders AS (
    SELECT 
        customer_id,
        order_id,
        order_purchase_timestamp,
        LAG(order_purchase_timestamp) OVER (
            PARTITION BY customer_id 
            ORDER BY order_purchase_timestamp
        ) AS previous_order_timestamp
    FROM fact_orders
    WHERE order_purchase_timestamp IS NOT NULL
)
SELECT 
    customer_id,
    order_id,
    order_purchase_timestamp,
    previous_order_timestamp,
    EXTRACT(DAY FROM (order_purchase_timestamp - previous_order_timestamp)) AS days_since_last_order
FROM customer_orders
WHERE previous_order_timestamp IS NOT NULL
ORDER BY days_since_last_order DESC;


-- 3. Running revenue totals and percentage contribution partitioned by state
WITH state_revenue AS (
    SELECT 
        g.state,
        o.order_purchase_timestamp,
        oi.price AS item_price
    FROM fact_order_items oi
    JOIN fact_orders o ON oi.order_id = o.order_id
    JOIN dim_customers c ON o.customer_id = c.customer_id
    JOIN dim_geolocation g ON c.zip_code_prefix = g.zip_code_prefix
    WHERE o.order_purchase_timestamp IS NOT NULL
)
SELECT 
    state,
    order_purchase_timestamp,
    item_price,
    SUM(item_price) OVER (PARTITION BY state ORDER BY order_purchase_timestamp) AS running_total_revenue,
    ROUND(
        SUM(item_price) OVER (PARTITION BY state ORDER BY order_purchase_timestamp) * 100.0 / 
        NULLIF(SUM(item_price) OVER (PARTITION BY state), 0), 4
    ) AS cumulative_percentage_contribution
FROM state_revenue;
