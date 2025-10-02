# Data Analysis Project on Brazilian E-Commerce Dataset

## Exploratory Data Analysis (EDA)

### `orders` table

### `order_reviews` table

`review_id` and `order_id` on their own are not unique. `order_id` might not be unique because a single order can have multiple products and each of these products have their own reviews, leading to `order_id` being duplicated in the table. Also, a particular order can have a follow-up review. `review_id` may not be unique i.e. a particular `review_id` may be reused for differnt `order_id`. The reason is unknown but it could be due to efficiency when generating the ids; we only need to ensure that the `review_id` generated is unique within a particular order rather than globally. Thus, `(review_id, order_id)` is the composite primary key.

### `order_payments` table

`order_id` and `payment_sequential` on their own are not unique because the payment for a single order can be broken down into multiple installments. Thus, the same `order_id` can be present multiple times. However, each installment payment for an order should be unique which makes `(order_id, payment_sequential)` the composite primary key.

### `products` table

We note that `product_name_lenght` and `product_description_lenght` columns are misspelled which we need to do later when doing data modelling. The `product_category_name` is in Portuguese but a Portuguese-English mapping table `product_category_name_translation` is provided.

### `customers` table

`customer_id` is a temporary, unique identifier assigned to a customer for each specific order they place. Each `customer_id` appears only once in the system and is unique to a single order. The purpose is to link a specific order to a customer in the `orders` table.
`customer_unique_id` is an anonymized, persistent identifier for a single customer. This ID is the same for one customer, even if they place multiple orders. The purpose is to identify and analyze the behavior of individual customers, such as tracking repeat purchases. This explains why `customer_id` is unique in this table but `customer_unique_id` is not as a single customer could have placed multiple orders.

## Extract, Transform, Load (ETL)

We build dimension tables first because fact tables contain foreign keys that reference the primary keys of dimension tables, meaning the dimensional data must exist and be loaded first to ensure the fact table can properly link to its descriptive context.

### Building Fact Table

For `order_payments` table, we did not convert it to a dimension table because it contains information on the installment payments per order which we consider it to be a measure. Thus, we aggregated all the installment payments per `order_id` and kept only the `order_id`, `total_payment_value` and `payment_installments`. Thereafter, we will merge it into our `fact_order_items` table.

For `order_reviews` table, we also did not convert it to a dimension table because it contains review scores which we consider it to be a measure. However, a particular order can have multiple reviews so we need to take average of all the scores. However, an order can also have a follow-up review so we need to only consider the latest set of review scores before taking average. We are not interested in the text reviews since we are not doing sentiment analysis. Thus, we will only keep `order_id` and `average_review_score` before merging into our `fact_order_items` table.
