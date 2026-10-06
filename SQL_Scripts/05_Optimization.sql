-- 1. Create B-Tree indexes for performance tuning on high-frequency join keys
CREATE INDEX IF NOT EXISTS idx_fact_orders_customer_id ON fact_orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_fact_order_items_product_id ON fact_order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_fact_order_items_seller_id ON fact_order_items(seller_id);
CREATE INDEX IF NOT EXISTS idx_dim_customers_zip ON dim_customers(zip_code_prefix);


-- 2. Query execution plan analysis using EXPLAIN ANALYZE
EXPLAIN ANALYZE
SELECT 
    c.customer_id,
    SUM(oi.price) AS total_spent
FROM dim_customers c
JOIN fact_orders o ON c.customer_id = o.customer_id
JOIN fact_order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id
ORDER BY total_spent DESC
LIMIT 10;


-- 3. Stored Procedure for dynamic discount calculation
CREATE OR REPLACE PROCEDURE apply_dynamic_discount(
    IN p_order_id VARCHAR,
    IN p_discount_percentage NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE fact_order_items
    SET price = price * (1 - p_discount_percentage / 100.0)
    WHERE order_id = p_order_id;
    
    COMMIT;
END;
$$;
