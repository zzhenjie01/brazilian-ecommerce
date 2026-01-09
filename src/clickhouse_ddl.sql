-- Dates Dimension Table
CREATE TABLE IF NOT EXISTS brazilian_ecommerce.dim_dates
(
    date_key UInt32,
    date Date,
    year UInt16,
    quarter UInt8,
    month UInt8,
    month_name String,
    week_of_year UInt8,
    day_of_month UInt8,
    day_of_week UInt8,
    day_name String,
    is_weekend Bool
)
ENGINE = MergeTree
ORDER BY date_key;

-- Customers Dimension Table
CREATE TABLE IF NOT EXISTS brazilian_ecommerce.dim_customers
(
    customer_key UInt64,
    customer_id String,
    customer_unique_id String,
    zip_code_prefix String,
    city String,
    state String,
    lat Nullable(Float64),
    lng Nullable(Float64)
)
ENGINE = MergeTree
ORDER BY customer_key;

-- Sellers Dimension Table
CREATE TABLE IF NOT EXISTS brazilian_ecommerce.dim_sellers
(
    seller_key UInt64,
    seller_id String,
    zip_code_prefix String,
    city String,
    state String,
    lat Nullable(Float64),
    lng Nullable(Float64)
)
ENGINE = MergeTree
ORDER BY seller_key;

-- Products Dimension Table
CREATE TABLE IF NOT EXISTS brazilian_ecommerce.dim_products
(
    product_key UInt64,
    product_id String,
    category_name Nullable(String),
    name_length Nullable(UInt32),
    description_length Nullable(UInt32),
    photos_quantity Nullable(UInt16),
    weight_g Nullable(Float64),
    length_cm Nullable(Float64),
    height_cm Nullable(Float64),
    width_cm Nullable(Float64)
)
ENGINE = MergeTree
ORDER BY product_key;

-- Orders Fact Table
CREATE TABLE IF NOT EXISTS brazilian_ecommerce.fact_order_items
(
    -- Grain (Degenerate dimension)
    order_id String,
    order_item_id UInt32,

    -- Surrogate keys
    customer_key UInt64,
    seller_key UInt64,
    product_key UInt64,
    purchase_date_key UInt32,

    -- Measures
    price Decimal(10, 2),
    freight_value Decimal(10, 2),
    item_total_value Decimal(10, 2),

    -- Core attributes
    order_status String,
    purchase_timestamp DateTime('UTC'),
    approved_timestamp Nullable(DateTime('UTC')),
    ship_out_deadline Nullable(DateTime('UTC')),
    carrier_received_timestamp Nullable(DateTime('UTC')),
    order_delivered_timestamp Nullable(DateTime('UTC')),
    estimated_delivery_date Nullable(Date),

    -- Data quality flags
    missing_required_timestamps Bool,
    status_aware_ordering Bool,
    delivered_status_with_missing_timestamp Bool,
    delivered_timestamp_with_incorrect_status Bool
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(purchase_timestamp) -- partition by month for performance
ORDER BY (purchase_date_key, order_id, order_item_id);


/*
Used to drop tables to start fresh
*/

-- DROP TABLE IF EXISTS brazilian_ecommerce.dim_dates;
-- DROP TABLE IF EXISTS brazilian_ecommerce.dim_customers;
-- DROP TABLE IF EXISTS brazilian_ecommerce.dim_sellers;
-- DROP TABLE IF EXISTS brazilian_ecommerce.dim_products;
-- DROP TABLE IF EXISTS brazilian_ecommerce.fact_order_items;

/*
Used to delete all data without dropping the table definitions
*/

-- TRUNCATE TABLE IF EXISTS brazilian_ecommerce.dim_dates;
-- TRUNCATE TABLE IF EXISTS brazilian_ecommerce.dim_customers;
-- TRUNCATE TABLE IF EXISTS brazilian_ecommerce.dim_sellers;
-- TRUNCATE TABLE IF EXISTS brazilian_ecommerce.dim_products;
-- TRUNCATE TABLE IF EXISTS brazilian_ecommerce.fact_order_items;