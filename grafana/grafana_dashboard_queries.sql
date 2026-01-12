-- ============================================
-- DASHBOARD 1: EXECUTIVE OVERVIEW
-- ============================================

-- KPI 1: Total Revenue
-- Panel Type: Stat
SELECT 
    sum(item_total_value) AS "Total Revenue"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
  AND order_status NOT IN ('canceled', 'unavailable');

-- KPI 2: Total Orders
-- Panel Type: Stat
SELECT 
    uniqExact(order_id) AS "Total Orders"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
  AND order_status NOT IN ('canceled', 'unavailable');

-- KPI 3: Average Order Value (AOV)
-- Panel Type: Stat
SELECT 
    sum(item_total_value) / uniqExact(order_id) AS "Avg Order Value"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
  AND order_status NOT IN ('canceled', 'unavailable');

-- KPI 4: Active Customers
-- Panel Type: Stat
SELECT 
    uniqExact(c.customer_unique_id) AS "Active Customers"
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_customers c ON f.customer_key = c.customer_key
WHERE $__timeFilter(f.purchase_timestamp)
  AND f.order_status NOT IN ('canceled', 'unavailable');

-- KPI 5: Total Items Sold
-- Panel Type: Stat
SELECT 
    count() AS "Items Sold"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
  AND order_status NOT IN ('canceled', 'unavailable');

-- Revenue Trend over Time
-- Panel Type: Time Series (Line Chart)
SELECT 
    $__timeInterval(purchase_timestamp) AS time,
    sum(item_total_value) AS "Total Revenue",
    sum(price) AS "Product Revenue",
    sum(freight_value) AS "Freight Value"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
  AND order_status NOT IN ('canceled', 'unavailable')
GROUP BY time
ORDER BY time

-- Order Status Distribution
-- Panel Type: Pie Chart or Donut Chart
SELECT 
    order_status AS "Status",
    uniqExact(order_id) AS "Orders"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
GROUP BY order_status
ORDER BY Orders DESC;

-- Revenue by Product Category
-- Panel Type: Horizontal Bar Chart
-- Show Top 10 categories
SELECT 
    p.category_name AS "Category",
    sum(f.item_total_value) AS "Revenue"
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_products p ON f.product_key = p.product_key
WHERE $__timeFilter(f.purchase_timestamp)
  AND f.order_status NOT IN ('canceled', 'unavailable')
  AND p.category_name IS NOT NULL
GROUP BY p.category_name
ORDER BY Revenue DESC
LIMIT 10;

-- Sales by Day of Week
-- Panel Type: Bar Chart
SELECT 
    d.day_of_week AS day_order,
    d.day_name AS "Day",
    sum(f.item_total_value) AS "Revenue"
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_dates d ON f.purchase_date_key = d.date_key
WHERE $__timeFilter(f.purchase_timestamp)
  AND f.order_status NOT IN ('canceled', 'unavailable')
GROUP BY d.day_of_week, d.day_name
ORDER BY day_order;

-- Revenue Distribution by State
-- Panel Type: Table
SELECT 
    c.state AS "State",
    uniqExact(f.order_id) AS "Orders",
    sum(f.item_total_value) AS "Revenue",
    sum(f.item_total_value) / uniqExact(f.order_id) AS "Avg Order Value",
    uniqExact(c.customer_unique_id) AS "Customers"
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_customers c ON f.customer_key = c.customer_key
WHERE $__timeFilter(f.purchase_timestamp)
  AND f.order_status NOT IN ('canceled', 'unavailable')
GROUP BY c.state
ORDER BY Revenue DESC
LIMIT 10;

-- ============================================
-- DASHBOARD 2: PRODUCT ANALYTICS
-- ============================================

-- Top 10 Products by Revenue
-- Panel Type: Table
SELECT 
    p.product_id AS "Product ID",
    p.category_name AS "Category",
    count() AS "Items Sold",
    sum(f.item_total_value) AS "Revenue",
    avg(f.price) AS "Avg Price"
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_products p ON f.product_key = p.product_key
WHERE $__timeFilter(f.purchase_timestamp)
  AND f.order_status NOT IN ('canceled', 'unavailable')
GROUP BY p.product_id, p.category_name
ORDER BY Revenue DESC
LIMIT 10;

-- Product Category Performance Table
-- Panel Type: Table
SELECT 
    p.category_name AS "Category",
    count() AS "Items Sold",
    sum(f.item_total_value) AS "Revenue",
    avg(f.price) AS "Avg Price",
    avg(f.freight_value) AS "Avg Freight Value",
    avg(p.weight_g) AS "Avg Weight (g)",
    sum(f.item_total_value) / count() AS "Revenue per Item"
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_products p ON f.product_key = p.product_key
WHERE $__timeFilter(f.purchase_timestamp)
  AND f.order_status NOT IN ('canceled', 'unavailable')
  AND p.category_name IS NOT NULL
GROUP BY p.category_name
ORDER BY Revenue DESC;

-- Freight to Price Ratio by Product Category
-- Panel Type: Bar Chart
SELECT 
    p.category_name AS "Category",
    (avg(f.freight_value) / nullIf(avg(f.price), 0)) * 100 AS "Freight/Price Ratio %",
    avg(f.freight_value) AS "Avg Freight",
    avg(f.price) AS "Avg Price"
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_products p ON f.product_key = p.product_key
WHERE $__timeFilter(f.purchase_timestamp)
  AND f.order_status NOT IN ('canceled', 'unavailable')
  AND p.category_name IS NOT NULL
GROUP BY p.category_name
HAVING count() > 10
ORDER BY "Freight/Price Ratio %" DESC
LIMIT 10;

-- Product Category by Weight
-- Panel Type: Bar Chart
SELECT 
    p.category_name AS "Category",
    avg(p.weight_g) AS "Avg Weight (g)",
    count() AS "Items Sold"
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_products p ON f.product_key = p.product_key
WHERE $__timeFilter(f.purchase_timestamp)
  AND f.order_status NOT IN ('canceled', 'unavailable')
  AND p.category_name IS NOT NULL
  AND p.weight_g IS NOT NULL
GROUP BY p.category_name
HAVING count() > 10
ORDER BY "Avg Weight (g)" DESC
LIMIT 10;

-- Freight vs Price Scatter Plot
-- Panel Type: Scatter plot
SELECT 
    p.category_name AS "Category",
    avg(f.price) AS "Avg Price",
    avg(f.freight_value) AS "Avg Freight Value",
    count() AS "Items Sold"
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_products p ON f.product_key = p.product_key
WHERE $__timeFilter(f.purchase_timestamp)
  AND f.order_status NOT IN ('canceled', 'unavailable')
  AND p.category_name IS NOT NULL
GROUP BY p.category_name
HAVING count() > 10
ORDER BY "Items Sold" DESC;

-- Freight vs Weight Scatter Plot
-- Panel Type: Scatter plot

SELECT 
    p.category_name AS "Category",
    avg(p.weight_g) AS "Avg Weight (g)",
    avg(f.freight_value) AS "Avg Freight Value",
    count() AS "Items Sold"
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_products p ON f.product_key = p.product_key
WHERE $__timeFilter(f.purchase_timestamp)
  AND f.order_status NOT IN ('canceled', 'unavailable')
  AND p.category_name IS NOT NULL
  AND p.weight_g IS NOT NULL
  AND p.weight_g > 0
GROUP BY p.category_name
HAVING count() > 10  -- Filter out categories with few items
ORDER BY "Avg Weight (g)" DESC;

-- Freight vs Volume Scatter Plot
-- Panel Type: Scatter plot

SELECT 
    p.category_name AS "Category",
    avg(p.length_cm * p.width_cm * p.height_cm) AS "Avg Volume (cm³)",
    avg(f.freight_value) AS "Avg Freight Value",
    count() AS "Items Sold"
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_products p ON f.product_key = p.product_key
WHERE $__timeFilter(f.purchase_timestamp)
  AND f.order_status NOT IN ('canceled', 'unavailable')
  AND p.category_name IS NOT NULL
  AND p.length_cm IS NOT NULL
  AND p.width_cm IS NOT NULL
  AND p.height_cm IS NOT NULL
  AND p.length_cm > 0 AND p.width_cm > 0 AND p.height_cm > 0
GROUP BY p.category_name
HAVING count() > 10  -- Filter out categories with few items
ORDER BY "Avg Volume (cm³)" DESC;

-- ============================================
-- DASHBOARD 3: CUSTOMER & GEOGRAPHIC ANALYTICS
-- ============================================

-- Customer Segmentation
-- Panel Type: Pie Chart
WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        uniqExact(f.order_id) AS order_count,
        sum(f.item_total_value) AS lifetime_value
    FROM brazilian_ecommerce.fact_order_items f
    JOIN brazilian_ecommerce.dim_customers c ON f.customer_key = c.customer_key
    WHERE $__timeFilter(f.purchase_timestamp)
      AND f.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
)
SELECT 
    CASE 
        WHEN order_count = 1 THEN '1 - One-time'
        WHEN order_count = 2 THEN '2 - Repeat'
        WHEN order_count BETWEEN 3 AND 5 THEN '3-5 - Regular'
        ELSE '6+ - Loyal'
    END AS "Customer Segment",
    count() AS "Customers",
    sum(lifetime_value) AS "Total Revenue"
FROM customer_orders
GROUP BY "Customer Segment"
ORDER BY "Customers" DESC;

-- Revenue by State
-- Panel Type: GeoMap or Table
SELECT 
    c.state AS "State",
    sum(f.item_total_value) AS "Revenue",
    uniqExact(f.order_id) AS "Orders",
    uniqExact(c.customer_unique_id) AS "Customers",
    avg(c.lat) AS "Latitude",
    avg(c.lng) AS "Longitude"
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_customers c ON f.customer_key = c.customer_key
WHERE $__timeFilter(f.purchase_timestamp)
  AND f.order_status NOT IN ('canceled', 'unavailable')
GROUP BY c.state
ORDER BY Revenue DESC;

-- Customer Lifetime Value (CLV) Distribution
-- Panel Type: Bar Chart (Histogram)
SELECT 
    c.customer_unique_id,
    sum(f.item_total_value) AS lifetime_value
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_customers c ON f.customer_key = c.customer_key
WHERE $__timeFilter(f.purchase_timestamp)
    AND f.order_status NOT IN ('canceled', 'unavailable')
GROUP BY c.customer_unique_id;

-- Customer Acquisition Over Time
-- Panel Type: Time Series
-- Note: This requires tracking first purchase per customer
WITH first_purchases AS (
    SELECT 
        c.customer_unique_id,
        min(f.purchase_timestamp) AS first_purchase_date
    FROM brazilian_ecommerce.fact_order_items f
    JOIN brazilian_ecommerce.dim_customers c ON f.customer_key = c.customer_key
    WHERE f.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
)
SELECT 
    $__timeInterval(first_purchase_date) AS time,
    count() AS "New Customers"
FROM first_purchases
WHERE $__timeFilter(first_purchase_date)
GROUP BY time
ORDER BY time;

-- Top 10 Cities by Revenue
-- Panel Type: Table
SELECT 
    c.city AS "City",
    c.state AS "State",
    uniqExact(c.customer_unique_id) AS "Customers",
    uniqExact(f.order_id) AS "Orders",
    sum(f.item_total_value) AS "Revenue",
    sum(f.item_total_value) / uniqExact(f.order_id) AS "Avg Order Value"
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_customers c ON f.customer_key = c.customer_key
WHERE $__timeFilter(f.purchase_timestamp)
  AND f.order_status NOT IN ('canceled', 'unavailable')
GROUP BY c.city, c.state
ORDER BY Revenue DESC
LIMIT 10;

-- ============================================
-- DASHBOARD 4: LOGISTICS & DELIVERY PERFORMANCE
-- ============================================

-- KPI: Average Delivery Lead Time
-- Panel Type: Stat
SELECT 
    avg(dateDiff('day', purchase_timestamp, order_delivered_timestamp)) AS "Avg Delivery Lead Time"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
  AND order_status = 'delivered'
  AND order_delivered_timestamp IS NOT NULL;

-- KPI: On-Time Delivery Rate
-- Panel Type: Stat (show as percentage)
SELECT 
    (countIf(order_delivered_timestamp <= estimated_delivery_date) / count()) * 100 AS "On-Time Rate %"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
  AND order_status = 'delivered'
  AND order_delivered_timestamp IS NOT NULL
  AND estimated_delivery_date IS NOT NULL;

-- KPI: Late Delivery Rate
-- Panel Type: Stat (show as percentage)
SELECT 
    (countIf(order_delivered_timestamp > estimated_delivery_date) / count()) * 100 AS "Late Delivery Rate %"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
  AND order_status = 'delivered'
  AND order_delivered_timestamp IS NOT NULL
  AND estimated_delivery_date IS NOT NULL;

-- Number of Orders by Status
-- Panel Type: Table or Funnel visualization
SELECT 
    order_status AS "Status",
    uniqExact(order_id) AS "Orders"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
GROUP BY order_status
ORDER BY 
    CASE order_status
        WHEN 'created' THEN 1
        WHEN 'approved' THEN 2
        WHEN 'invoiced' THEN 3
        WHEN 'processing' THEN 4
        WHEN 'shipped' THEN 5
        WHEN 'delivered' THEN 6
        WHEN 'canceled' THEN 7
        WHEN 'unavailable' THEN 8
        ELSE 9
    END;

-- Same State vs Cross State Delivery Performance
-- Panel Type: Table or Stat comparison
SELECT 
    CASE WHEN c.state = s.state THEN 'Same State' ELSE 'Cross State' END AS "Shipping Type",
    uniqExact(f.order_id) AS "Orders",
    avg(dateDiff('day', f.purchase_timestamp, f.order_delivered_timestamp)) AS "Avg Delivery Days",
    avg(f.freight_value) AS "Avg Freight Value",
    (countIf(f.order_delivered_timestamp > f.estimated_delivery_date) / count()) * 100 AS "Late Delivery Rate %"
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_customers c ON f.customer_key = c.customer_key
JOIN brazilian_ecommerce.dim_sellers s ON f.seller_key = s.seller_key
WHERE $__timeFilter(f.purchase_timestamp)
  AND f.order_status = 'delivered'
  AND f.order_delivered_timestamp IS NOT NULL
GROUP BY "Shipping Type"
ORDER BY Orders DESC;

-- Delivery Lead Time Distribution
-- Panel Type: Bar Chart (Histogram)
SELECT 
    dateDiff('day', purchase_timestamp, order_delivered_timestamp) AS days
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
    AND order_status = 'delivered'
    AND order_delivered_timestamp IS NOT NULL;

-- Delivery Performance Over Time
-- Panel Type: Time Series (Dual Axis)
SELECT 
    $__timeInterval(purchase_timestamp) AS time,
    avg(dateDiff('day', purchase_timestamp, order_delivered_timestamp)) AS "Avg Delivery Lead Time (Days)",
    (countIf(order_delivered_timestamp > estimated_delivery_date) / count()) * 100 AS "Late Delivery Rate %"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
  AND order_status = 'delivered'
  AND order_delivered_timestamp IS NOT NULL
  AND estimated_delivery_date IS NOT NULL
GROUP BY time
ORDER BY time;

-- Freight Value by Product Category
-- Panel Type: Bar Chart
SELECT 
    p.category_name AS "Category",
    sum(f.freight_value) AS "Total Freight",
    avg(f.freight_value) AS "Avg Freight per Item",
    count() AS "Items Shipped"
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_products p ON f.product_key = p.product_key
WHERE $__timeFilter(f.purchase_timestamp)
  AND f.order_status NOT IN ('canceled', 'unavailable')
  AND p.category_name IS NOT NULL
GROUP BY p.category_name
ORDER BY "Total Freight" DESC
LIMIT 10;

-- State Delivery Performance
-- Panel Type: Table
SELECT 
    c.state AS "State",
    uniqExact(f.order_id) AS "Delivered Orders",
    avg(dateDiff('day', f.purchase_timestamp, f.order_delivered_timestamp)) AS "Avg Delivery Lead Time (Days)",
    (countIf(f.order_delivered_timestamp > f.estimated_delivery_date) / count()) * 100 AS "Late Delivery %",
    sum(f.freight_value) AS "Total Freight Value",
    avg(f.freight_value) AS "Avg Freight Value"
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_customers c ON f.customer_key = c.customer_key
WHERE $__timeFilter(f.purchase_timestamp)
  AND f.order_status = 'delivered'
  AND f.order_delivered_timestamp IS NOT NULL
GROUP BY c.state
ORDER BY "Delivered Orders" DESC;

-- ============================================
-- DASHBOARD 5: DATA QUALITY & OPERATIONS
-- ============================================

-- KPI: % Records with Quality Issues
-- Panel Type: Stat
SELECT 
    (countIf(missing_required_timestamps = true OR 
             status_aware_ordering = false OR 
             delivered_status_with_missing_timestamp = true OR 
             delivered_timestamp_with_incorrect_status = true) / count()) * 100 AS "Quality Issue Rate %"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp);

-- KPI: Missing Timestamps Count
-- Panel Type: Stat
SELECT 
    countIf(missing_required_timestamps = true) AS "Missing Timestamps"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp);

-- KPI: Timestamp Ordering Violations
-- Panel Type: Stat
SELECT 
    countIf(status_aware_ordering = false) AS "Timestamp Ordering Violations"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp);

-- Missing Required Timestamps by Order Status
-- Panel Type: Stacked Bar Chart
SELECT 
    order_status AS "Status",
    countIf(missing_required_timestamps = true) AS "Missing Timestamps",
    countIf(missing_required_timestamps = false) AS "Complete Records"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
GROUP BY order_status
ORDER BY "Missing Timestamps" DESC;

-- Incorrect Timestamp Ordering by Order Status
-- Panel Type: Stacked Bar Chart
SELECT 
    order_status AS "Status",
    countIf(status_aware_ordering = false) AS "Incorrect Timestamp Ordering",
    countIf(status_aware_ordering = true) AS "Correct Timestamp Ordering"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
GROUP BY order_status
ORDER BY "Incorrect Timestamp Ordering" DESC;

-- Data Quality Issues Over Time
-- Panel Type: Time Series
SELECT 
    $__timeInterval(purchase_timestamp) AS time,
    countIf(missing_required_timestamps = true) AS "Missing Timestamps",
    countIf(status_aware_ordering = false) AS "Timestamp Ordering Violations",
    countIf(delivered_status_with_missing_timestamp = true) AS "Delivered Status with Missing Timestamp",
    countIf(delivered_timestamp_with_incorrect_status = true) AS "Delivered Timestamp with Incorrect Status"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
GROUP BY time
ORDER BY time;

-- Data Quality Checks Summary
-- Panel Type: Table
SELECT 
    'Missing Required Timestamps' AS "Quality Check",
    countIf(missing_required_timestamps = true) AS "Failed Count",
    count() AS "Total Records",
    (countIf(missing_required_timestamps = true) / count()) * 100 AS "Failure Rate %"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)

UNION ALL

SELECT 
    'Status Aware Ordering',
    countIf(status_aware_ordering = false),
    count(),
    (countIf(status_aware_ordering = false) / count()) * 100
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)

UNION ALL

SELECT 
    'Delivered Status Missing Timestamp',
    countIf(delivered_status_with_missing_timestamp = true),
    count(),
    (countIf(delivered_status_with_missing_timestamp = true) / count()) * 100
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)

UNION ALL

SELECT 
    'Delivered Timestamp Wrong Status',
    countIf(delivered_timestamp_with_incorrect_status = true),
    count(),
    (countIf(delivered_timestamp_with_incorrect_status = true) / count()) * 100
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)

-- Anomaly 1: Delivered status without delivery timestamp
-- Panel Type: Table (for investigation)
SELECT 
    order_id AS "Order ID",
    order_item_id AS "Order Item ID",
    order_status AS "Status",
    purchase_timestamp AS "Purchase Time",
    order_delivered_timestamp AS "Delivered Time",
    'Missing delivery timestamp' AS "Issue"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
  AND delivered_status_with_missing_timestamp = true
ORDER BY purchase_timestamp DESC
LIMIT 100;

-- Anomaly 2: Delivery timestamp without delivered status
-- Panel Type: Table (for investigation)
SELECT 
    order_id AS "Order ID",
    order_item_id AS "Order Item ID",
    order_status AS "Status",
    purchase_timestamp AS "Purchase Time",
    order_delivered_timestamp AS "Delivered Time",
    'Has delivery timestamp but wrong status' AS "Issue"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
  AND delivered_timestamp_with_incorrect_status = true
ORDER BY purchase_timestamp DESC
LIMIT 100;

-- ============================================
-- DASHBOARD 6: ADVANCED SALES ANALYTICS
-- ============================================

-- Items per Order KPI
-- Panel Type: Stat
SELECT 
    count() / uniqExact(order_id) AS "Avg Items per Order"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
  AND order_status NOT IN ('canceled', 'unavailable');

-- Revenue per Customer (RPC) KPI
-- Panel Type: Stat
SELECT 
    sum(f.item_total_value) / uniqExact(c.customer_unique_id) AS "Revenue per Customer"
FROM brazilian_ecommerce.fact_order_items f
JOIN brazilian_ecommerce.dim_customers c ON f.customer_key = c.customer_key
WHERE $__timeFilter(f.purchase_timestamp)
  AND f.order_status NOT IN ('canceled', 'unavailable');

-- Cancellation Rate over Time
-- Panel Type: Time Series
SELECT 
    $__timeInterval(purchase_timestamp) AS time,
    (countIf(order_status = 'canceled') / uniqExact(order_id)) * 100 AS "Cancellation Rate %",
    countIf(order_status = 'canceled') AS "Canceled Orders",
    uniqExact(order_id) AS "Total Orders"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
GROUP BY time
ORDER BY time;

-- Day of Week Sales Pattern
-- Panel Type: Heatmap
SELECT 
    toDayOfWeek(purchase_timestamp) AS day_of_week,
    uniqExact(order_id) AS "Orders"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
  AND order_status NOT IN ('canceled', 'unavailable')
GROUP BY day_of_week
ORDER BY day_of_week;

-- Hourly Sales Pattern
-- Panel Type: Heatmap
SELECT 
    toHour(purchase_timestamp) AS hour,
    uniqExact(order_id) AS "Orders"
FROM brazilian_ecommerce.fact_order_items
WHERE $__timeFilter(purchase_timestamp)
  AND order_status NOT IN ('canceled', 'unavailable')
GROUP BY hour
ORDER BY hour;




