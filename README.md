# brazilian-ecommerce

## Dataset

The dataset used in this project is the Brazilian E-commerce Dataset by Olist on [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce/data). The dataset has information of 100k orders from 2016 to 2018 made at multiple marketplaces in Brazil.

## Dataset Context

This dataset is provided by Olist, the largest department store in Brazilian marketplaces. Olist connects small businesses from all over Brazil to channels without hassle and with a single contract. Those merchants are able to sell their products through the Olist Store and ship them directly to the customers using Olist logistics partners.

After a customer purchases the product from Olist Store a seller gets notified to fulfill that order. Once the customer receives the product, or the estimated delivery date is due, the customer gets a satisfaction survey by email where he can give a note for the purchase experience and write down some comments.

## Raw Dataset Schema

![brazilian_ecommerce_raw_schema](attachments/brazilian_ecommerce_raw_schema.png)

### orders

- "order_id","customer_id","order_status","order_purchase_timestamp","order_approved_at","order_delivered_carrier_date","order_delivered_customer_date","order_estimated_delivery_date"
- `orders.order_id` relates to `order_reviews.order_id`
- `orders.order_id` relates to `order_payments.order_id`
- `orders.order_id` relates to `order_items.order_id`
- `orders.customer_id` relates to `customers.customer_id`

### order_reviews

- "review_id","order_id","review_score","review_comment_title","review_comment_message","review_creation_date","review_answer_timestamp"

### order_payments

- "order_id","payment_sequential","payment_type","payment_installments","payment_value"

### order_items

- "order_id","order_item_id","product_id","seller_id","shipping_limit_date","price","freight_value"
- `order_items.product_id` relates to `products.product_id`
- `order_items.seller_id` relates to `sellers.seller_id`

### products

- "product_id","product_category_name","product_name_lenght","product_description_lenght","product_photos_qty","product_weight_g","product_length_cm","product_height_cm","product_width_cm"

### sellers

- "seller_id","seller_zip_code_prefix","seller_city","seller_state"
- `sellers.seller_zip_code_prefix` relates to `geolocation.geolocation_zip_code_prefix`

### customers

- "customer_id","customer_unique_id","customer_zip_code_prefix","customer_city","customer_state"
- `customers.customer_zip_code_prefix` relates to `geolocation.geolocation_zip_code_prefix`

### geolocation

- "geolocation_zip_code_prefix","geolocation_lat","geolocation_lng","geolocation_city","geolocation_state"
