-- 1. Find customers spending above their state's average
WITH customer_spend AS (
    SELECT 
        c.customer_id,
        c.zip_code_prefix,
        g.state,
        SUM(oi.price + oi.freight_value) AS total_spend
    FROM dim_customers c
    JOIN dim_geolocation g ON c.zip_code_prefix = g.zip_code_prefix
    JOIN fact_orders o ON c.customer_id = o.customer_id
    JOIN fact_order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id, c.zip_code_prefix, g.state
),
state_avg_spend AS (
    SELECT 
        state,
        AVG(total_spend) AS avg_state_spend
    FROM customer_spend
    GROUP BY state
)
SELECT 
    cs.customer_id,
    cs.state,
    cs.total_spend,
    sas.avg_state_spend
FROM customer_spend cs
JOIN state_avg_spend sas ON cs.state = sas.state
WHERE cs.total_spend > sas.avg_state_spend
ORDER BY cs.total_spend DESC;


-- 2. Get the 2nd highest revenue-generating product in each category
WITH product_revenue AS (
    SELECT 
        p.product_category_name,
        p.product_id,
        SUM(oi.price) AS total_revenue
    FROM dim_products p
    JOIN fact_order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_category_name, p.product_id
),
ranked_products AS (
    SELECT 
        product_category_name,
        product_id,
        total_revenue,
        DENSE_RANK() OVER (PARTITION BY product_category_name ORDER BY total_revenue DESC) as revenue_rank
    FROM product_revenue
)
SELECT 
    product_category_name,
    product_id,
    total_revenue
FROM ranked_products
WHERE revenue_rank = 2;


-- 3. Product category hierarchy using recursive CTEs
-- (Simulating parent-child category structuring or level-based traversal)
WITH RECURSIVE category_tree AS (
    SELECT 
        product_category_name AS category,
        1 AS depth
    FROM dim_products
    WHERE product_category_name IS NOT NULL
    UNION
    SELECT 
        p.product_category_name,
        ct.depth + 1
    FROM dim_products p
    JOIN category_tree ct ON p.product_category_name = ct.category
    WHERE ct.depth < 3
)
SELECT DISTINCT category, depth
FROM category_tree
ORDER BY depth, category;
