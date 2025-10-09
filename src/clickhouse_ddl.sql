-- Customers Dimension Table
CREATE TABLE IF NOT EXISTS brazilian_ecommerce.dim_customers (
    customer_key UInt64,
    customer_id String,
    customer_unique_id String,
    customer_zip_code_prefix UInt32,
    customer_city String,
    customer_state String,
    lat Nullable(Float64),
    lng Nullable(Float64)
) ENGINE = MergeTree
ORDER BY customer_key;

-- Sellers Dimension Table
CREATE TABLE IF NOT EXISTS brazilian_ecommerce.dim_sellers (
    seller_key UInt64,
    seller_id String,
    seller_zip_code_prefix UInt32,
    seller_city String,
    seller_state String,
    lat Nullable(Float64),
    lng Nullable(Float64)
) ENGINE = MergeTree
ORDER BY seller_key;

-- Products Dimension Table
CREATE TABLE IF NOT EXISTS brazilian_ecommerce.dim_products (
    product_key UInt64,
    product_id String,
    product_category_name Nullable(String),
    product_name_length Nullable(UInt32),
    product_description_length Nullable(UInt32),
    product_photos_qty Nullable(UInt32),
    product_weight_g Nullable(Float32),
    product_length_cm Nullable(Float32),
    product_height_cm Nullable(Float32),
    product_width_cm Nullable(Float32)
) ENGINE = MergeTree
ORDER BY product_key;

-- Orders Fact Table
CREATE TABLE IF NOT EXISTS brazilian_ecommerce.fact_order_items (
    order_id String, 
    order_item_id UInt64, 
    customer_key UInt64, 
    seller_key UInt64, 
    product_key UInt64,
    order_purchase_timestamp DateTime('UTC'), 
    order_approved_at Nullable(DateTime('UTC')), 
    order_delivered_carrier_date Nullable(DateTime('UTC')), 
    shipping_limit_date DateTime('UTC'),
    order_delivered_customer_date Nullable(DateTime('UTC')), 
    order_estimated_delivery_date DateTime('UTC'), 
    order_status String, 
    price Decimal(15, 2), 
    freight_value Decimal(15, 2), 
    total_payment_value Nullable(Decimal(15, 2)), 
    payment_installments Nullable(UInt32), 
    average_review_score Nullable(Float32)
) ENGINE = MergeTree
PARTITION BY toYYYYMM(order_purchase_timestamp) -- partition by month for performance
ORDER BY (order_id, order_item_id);

/*
Used to drop tables to start fresh
*/

-- DROP TABLE IF EXISTS brazilian_ecommerce.dim_customers;
-- DROP TABLE IF EXISTS brazilian_ecommerce.dim_sellers;
-- DROP TABLE IF EXISTS brazilian_ecommerce.dim_products;
-- DROP TABLE IF EXISTS brazilian_ecommerce.fact_order_items;

/*
Used to delete all data without dropping the table definitions
*/

-- TRUNCATE TABLE IF EXISTS brazilian_ecommerce.dim_customers;
-- TRUNCATE TABLE IF EXISTS brazilian_ecommerce.dim_sellers;
-- TRUNCATE TABLE IF EXISTS brazilian_ecommerce.dim_products;
-- TRUNCATE TABLE IF EXISTS brazilian_ecommerce.fact_order_items;