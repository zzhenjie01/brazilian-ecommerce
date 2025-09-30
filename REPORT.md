# Data Analysis Project on Brazilian E-Commerce Dataset

## Extract, Transform, Load (ETL)

### Exploratory Data Analysis (EDA)

#### `orders` table

#### `order_reviews` table

`review_id` and `order_id` on their own are not unique. `order_id` might not be unique because a single order can have multiple products and each of these products have their own reviews, leading to `order_id` being duplicated in the table. `review_id` may not be unique i.e. a particular `review_id` may be reused for differnt `order_id`. The reason is unknown but it could be due to efficiency when generating the ids; we only need to ensure that the `review_id` generated is unique within a particular order rather than globally. Thus, `(review_id, order_id)` is the composite primary key.

#### `order_payments` table

`order_id` and `payment_sequential` on their own are not unique because the payment for a single order can be broken down into multiple installments. Thus, the same `order_id` can be present multiple times. However, each installment payment for an order should be unique which makes `(order_id, payment_sequential)` the composite primary key.

### `products` table

We note that `product_name_lenght` and `product_description_lenght` columns are misspelled which we need to do later when doing data modelling. The `product_category_name` is in Portuguese but a Portuguese-English mapping table `product_category_name_translation` is provided.

