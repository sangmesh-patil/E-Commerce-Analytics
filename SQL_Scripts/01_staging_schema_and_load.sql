-- Drop any existing tables to ensure a clean slate
DROP TABLE IF EXISTS order_reviews, order_payments, order_items, orders, products, sellers, customers, geolocation CASCADE;

-- 1. Geolocation Staging
CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat NUMERIC,
    geolocation_lng NUMERIC,
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(2)
);

-- 2. Customers Staging
CREATE TABLE customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(2)
);

-- 3. Sellers Staging
CREATE TABLE sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(2)
);

-- 4. Products Staging
CREATE TABLE products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g NUMERIC,
    product_length_cm NUMERIC,
    product_height_cm NUMERIC,
    product_width_cm NUMERIC
);

-- 5. Orders Staging
CREATE TABLE orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- 6. Order Items Staging
CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price NUMERIC,
    freight_value NUMERIC
);

-- 7. Order Payments Staging
CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value NUMERIC
);

-- 8. Order Reviews Staging
CREATE TABLE order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

-- Load data from CSVs into staging tables
-- NOTE: Replace the folder path below with your local machine path where the CSV files are stored.
-- Example: 'C:/Users/YourName/Documents/E-Commerce-Analytics/Data/'
--          or 'D:/SQL/E-Commerce-Analytics/Data/'
-- Make sure the folder contains all CSV files before running this script.
\copy geolocation FROM 'D:/SQL/E-Commerce-Analytics/data/olist_geolocation_dataset.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';

\copy customers FROM 'D:/SQL/E-Commerce-Analytics/data/olist_customers_dataset.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';

\copy sellers FROM 'D:/SQL/E-Commerce-Analytics/data/olist_sellers_dataset.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';

\copy products FROM 'D:/SQL/E-Commerce-Analytics/data/olist_products_dataset.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';

\copy orders FROM 'D:/SQL/E-Commerce-Analytics/data/olist_orders_dataset.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';

\copy order_items FROM 'D:/SQL/E-Commerce-Analytics/data/olist_order_items_dataset.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';

\copy order_payments FROM 'D:/SQL/E-Commerce-Analytics/data/olist_order_payments_dataset.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';

\copy order_reviews FROM 'D:/SQL/E-Commerce-Analytics/data/olist_order_reviews_dataset.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8';
