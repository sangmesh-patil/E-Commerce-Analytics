-- ============================================================================
-- Script: 02_Data_Cleaning_and_Load.sql
-- Purpose: Deduplicates raw staging data, resolves foreign key dependencies, 
--          and populates the strict 3NF production schema with constraints.
-- ============================================================================

-- 1. POPULATE DIMENSION: dim_geolocation
-- Resolves spatial duplicates by taking the centroid (average lat/lng) per zip code prefix.
INSERT INTO dim_geolocation (zip_code_prefix, lat, lng, city, state)
SELECT 
    geolocation_zip_code_prefix AS zip_code_prefix,
    AVG(geolocation_lat) AS lat,
    AVG(geolocation_lng) AS lng,
    MAX(geolocation_city) AS city,
    MAX(geolocation_state) AS state
FROM staging_geolocation
GROUP BY geolocation_zip_code_prefix
ON CONFLICT (zip_code_prefix) DO NOTHING;


-- 2. POPULATE DIMENSION: dim_customers
-- Ensures referential integrity by checking that the zip code exists in dim_geolocation.
INSERT INTO dim_customers (customer_id, customer_unique_id, zip_code_prefix)
SELECT DISTINCT 
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix AS zip_code_prefix
FROM staging_customers c
JOIN dim_geolocation g ON c.customer_zip_code_prefix = g.zip_code_prefix
ON CONFLICT (customer_id) DO NOTHING;


-- 3. POPULATE DIMENSION: dim_sellers
-- Filters out sellers with zip codes missing from the geolocation reference table.
INSERT INTO dim_sellers (seller_id, zip_code_prefix)
SELECT DISTINCT 
    s.seller_id,
    s.seller_zip_code_prefix AS zip_code_prefix
FROM staging_sellers s
JOIN dim_geolocation g ON s.seller_zip_code_prefix = g.zip_code_prefix
ON CONFLICT (seller_id) DO NOTHING;


-- 4. POPULATE DIMENSION: dim_products
-- Cleans product categories and attributes, handling potential nulls.
INSERT INTO dim_products (
    product_id, 
    product_category_name, 
    product_name_length, 
    product_description_length, 
    product_photos_qty, 
    product_weight_g, 
    product_length_cm, 
    product_height_cm, 
    product_width_cm
)
SELECT DISTINCT 
    p.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS product_category_name,
    NULLIF(p.product_name_lenght, '')::integer,
    NULLIF(p.product_description_lenght, '')::integer,
    NULLIF(p.product_photos_qty, '')::integer,
    NULLIF(p.product_weight_g, '')::numeric,
    NULLIF(p.product_length_cm, '')::numeric,
    NULLIF(p.product_height_cm, '')::numeric,
    NULLIF(p.product_width_cm, '')::numeric
FROM staging_products p
LEFT JOIN staging_category_translation t ON p.product_category_name = t.product_category_name
ON CONFLICT (product_id) DO NOTHING;


-- 5. POPULATE FACT: fact_orders
-- Ensures orders only map to valid customers present in dim_customers.
INSERT INTO fact_orders (
    order_id, 
    customer_id, 
    order_status, 
    order_purchase_timestamp, 
    order_approved_at, 
    order_delivered_carrier_date, 
    order_delivered_customer_date, 
    order_estimated_delivery_date
)
SELECT DISTINCT 
    o.order_id,
    o.customer_id,
    o.order_status,
    NULLIF(o.order_purchase_timestamp, '')::timestamp,
    NULLIF(o.order_approved_at, '')::timestamp,
    NULLIF(o.order_delivered_carrier_date, '')::timestamp,
    NULLIF(o.order_delivered_customer_date, '')::timestamp,
    NULLIF(o.order_estimated_delivery_date, '')::timestamp
FROM staging_orders o
JOIN dim_customers c ON o.customer_id = c.customer_id
ON CONFLICT (order_id) DO NOTHING;


-- 6. POPULATE FACT: fact_order_items
-- Links items strictly to verified orders, products, and sellers.
INSERT INTO fact_order_items (
    order_id, 
    order_item_id, 
    product_id, 
    seller_id, 
    shipping_limit_date, 
    price, 
    freight_value
)
SELECT 
    i.order_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    NULLIF(i.shipping_limit_date, '')::timestamp,
    NULLIF(i.price, '')::numeric,
    NULLIF(i.freight_value, '')::numeric
FROM staging_order_items i
JOIN fact_orders o ON i.order_id = o.order_id
JOIN dim_products p ON i.product_id = p.product_id
JOIN dim_sellers s ON i.seller_id = s.seller_id
ON CONFLICT (order_id, order_item_id) DO NOTHING;


-- 7. POPULATE FACT: fact_order_payments
-- Maps payment transactions securely to verified parent orders.
INSERT INTO fact_order_payments (
    order_id, 
    payment_sequential, 
    payment_type, 
    payment_installments, 
    payment_value
)
SELECT 
    pay.order_id,
    pay.payment_sequential,
    pay.payment_type,
    NULLIF(pay.payment_installments, '')::integer,
    NULLIF(pay.payment_value, '')::numeric
FROM staging_order_payments pay
JOIN fact_orders o ON pay.order_id = o.order_id
ON CONFLICT (order_id, payment_sequential) DO NOTHING;


-- 8. POPULATE FACT: fact_order_reviews
-- Links customer feedback reviews to active orders.
INSERT INTO fact_order_reviews (
    review_id, 
    order_id, 
    review_score, 
    review_comment_title, 
    review_comment_message, 
    review_creation_date, 
    review_answer_timestamp
)
SELECT DISTINCT 
    r.review_id,
    r.order_id,
    NULLIF(r.review_score, '')::integer,
    NULLIF(r.review_comment_title, ''),
    NULLIF(r.review_comment_message, ''),
    NULLIF(r.review_creation_date, '')::timestamp,
    NULLIF(r.review_answer_timestamp, '')::timestamp
FROM staging_order_reviews r
JOIN fact_orders o ON r.order_id = o.order_id
ON CONFLICT (review_id, order_id) DO NOTHING;
