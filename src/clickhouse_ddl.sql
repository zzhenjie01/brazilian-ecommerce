-- Customers Dimension Table
CREATE TABLE IF NOT EXISTS brazilian_ecommerce.dim_customers (
    customer_key UInt64,
    customer_id String,
    customer_unique_id String,
    customer_zip_code_prefix UInt32,
    customer_city String,
    customer_state String,
    lat Float64,
    lng Float64
) ENGINE = MergeTree
ORDER BY customer_key;

-- Sellers Dimension Table
CREATE TABLE IF NOT EXISTS brazilian_ecommerce.dim_sellers (
    seller_key UInt64,
    seller_id String,
    seller_zip_code_prefix UInt32,
    seller_city String,
    seller_state String,
    lat Float64,
    lng Float64
) ENGINE = MergeTree
ORDER BY seller_key;

-- Products Dimension Table
CREATE TABLE IF NOT EXISTS brazilian_ecommerce.dim_products (
    product_key UInt64,
    product_id String,
    product_category_name String,
    product_name_length UInt32,
    product_description_length UInt32,
    product_photos_qty UInt32,
    product_weight_g Float32,
    product_length_cm Float32,
    product_height_cm Float32,
    product_width_cm Float32
) ENGINE = MergeTree
ORDER BY product_key;

-- Orders Fact Table
CREATE TABLE IF NOT EXISTS brazilian_ecommerce.fact_order_items (
    order_id String, 
    order_item_id UInt64, 
    customer_key UInt64, 
    seller_key UInt64, 
    product_key UInt64,
    order_purchase_timestamp DateTime('America/Sao_Paulo'), 
    order_approved_at DateTime('America/Sao_Paulo'), 
    order_delivered_carrier_date DateTime('America/Sao_Paulo'), 
    shipping_limit_date DateTime('America/Sao_Paulo'),
    order_delivered_customer_date DateTime('America/Sao_Paulo'), 
    order_estimated_delivery_date DateTime('America/Sao_Paulo'), 
    order_status String, 
    price Decimal(15, 2), 
    freight_value Decimal(15, 2), 
    total_payment_value Decimal(15, 2), 
    payment_installments UInt32, 
    average_review_score Float32
) ENGINE = MergeTree
PARTITION BY toYYYYMM(order_purchase_timestamp) -- partition by month for performance
ORDER BY (order_id, order_item_id);

/*
Used to delete all data without dropping the table definitions
*/
-- -- Customers Dimension Table
-- TRUNCATE TABLE IF EXISTS brazilian_ecommerce.dim_customers;

-- -- Sellers Dimension Table
-- TRUNCATE TABLE IF EXISTS brazilian_ecommerce.dim_sellers;

-- -- Products Dimension Table
-- TRUNCATE TABLE IF EXISTS brazilian_ecommerce.dim_products;

-- -- Orders Fact Table
-- TRUNCATE TABLE IF EXISTS brazilian_ecommerce.fact_order_items;