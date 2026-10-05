/*
===============================================================================
Data Quality Checks
Description: Identifies anomalies, orphaned records, and business logic 
violations in the raw staging tables.
===============================================================================
*/

-- 1. Ghost Orders (Missing Line Items)
-- Expected: 0 | Actual: 775
SELECT COUNT(o.order_id) as ghost_orders
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;

-- 2. Orphaned Customer Zip Codes
-- Expected: 0 | Actual: 157
SELECT COUNT(DISTINCT c.customer_zip_code_prefix) as missing_customer_zips
FROM customers c
LEFT JOIN geolocation g ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL;

-- 3. Orphaned Seller Zip Codes
-- Expected: 0 | Actual: 7
SELECT COUNT(DISTINCT s.seller_zip_code_prefix) as missing_seller_zips
FROM sellers s
LEFT JOIN geolocation g ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
WHERE g.geolocation_zip_code_prefix IS NULL;

-- 4. Incomplete Product Specifications
-- Expected: 0 | Actual: 6
SELECT COUNT(*) as incomplete_products
FROM products
WHERE product_weight_g IS NULL 
   OR product_weight_g = 0
   OR product_length_cm IS NULL;

-- 5. Geolocation Coordinate Duplication
-- Identifies zip codes with multiple latitude/longitude pairs
SELECT geolocation_zip_code_prefix, COUNT(*) as record_count
FROM geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1
ORDER BY record_count DESC;

-- 6. Unstandardized City Naming
-- Identifies zip codes mapping to multiple city name spelling variations
SELECT geolocation_zip_code_prefix, COUNT(DISTINCT geolocation_city) as unique_city_names
FROM geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(DISTINCT geolocation_city) > 1;

-- 7. Freight Value Outliers
-- Identifies items where freight cost is > 5x the item price
SELECT order_id, product_id, price, freight_value
FROM order_items
WHERE freight_value > (price * 5)
ORDER BY freight_value DESC;

-- 8. Severe Delivery SLA Violations
-- Identifies deliveries arriving > 30 days after the estimated delivery date
SELECT order_id, order_estimated_delivery_date, order_delivered_customer_date,
       EXTRACT(DAY FROM (order_delivered_customer_date - order_estimated_delivery_date)) as days_late
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date > (order_estimated_delivery_date + INTERVAL '30 days')
ORDER BY days_late DESC;

-- 9. State-to-Timestamp Mismatches
-- Identifies 'delivered' orders completely missing a delivery timestamp
SELECT COUNT(*) as missing_delivery_dates
FROM orders
WHERE order_status = 'delivered' 
AND order_delivered_customer_date IS NULL;