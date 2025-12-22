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

## Python Setup

```bash
git clone https://github.com/zzhenjie01/brazilian-ecommerce.git
```

```bash
uv sync
```

## ClickHouse Docker Setup

- [ClickHouse Network Ports](https://clickhouse.com/docs/guides/sre/network-ports)
- [ClickHouse Official Image](https://hub.docker.com/_/clickhouse)

Make sure Docker Desktop is running in the background. Then `cd` into `docker/` folder and run the following command to start the docker container.

```bash
docker-compose --project-name brazilian-ecommerce up -d
```

We can then use tools like DbVisualizer to connect to the Dockerized ClickHouse container at `http://localhost:8132`

We can run `src/clickhouse_ddl.sql` in DbVisualizer connected to ClickHouse to create the fact and dimension tables.

To insert the fact and dimension tables into ClickHouse, we can either doing via command line or run a python script. In general, it is better to run python script as it allows automation.

Make sure you are at the project root directory and run the following commands.

```bash
docker exec -i clickhouse clickhouse-client --query="INSERT INTO ecommerce.dim_customers FORMAT CSV" < data/processed/dim_customers.csv
docker exec -i clickhouse clickhouse-client --query="INSERT INTO ecommerce.dim_sellers FORMAT CSV" < data/processed/dim_sellers.csv
docker exec -i clickhouse clickhouse-client --query="INSERT INTO ecommerce.dim_products FORMAT CSV" < data/processed/dim_products.csv
docker exec -i clickhouse clickhouse-client --query="INSERT INTO ecommerce.fact_order_items FORMAT CSV" < data/processed/fact_order_items.csv
```

To use run the python script, 

To stop ClickHouse, run the following command in terminal.

```bash
docker-compose stop
```

```bash
docker-compose down           # Stop and remove
docker-compose logs -f        # View logs
docker-compose restart        # Restart
```

Default Credentials:

- Username: `default_write`
- Password: `default_write`

### Create an admin user

These will copy the user configuration files of ClickHouse to local `docker/` folder for editing.

```bash
docker cp clickhouse:/etc/clickhouse-server/users.xml .
docker cp clickhouse:/etc/clickhouse-server/users.d .
```

Upon inspection, we see that we only need to modify the `user.d/default-user.xml` file since it overrides the settings in `users.xml` file. This is because we specify the `CLICKHOUSE_USER` and `CLICKHOUSE_PASSWORD` environment variables in our docker-compose file.

Modify/Update the `user.d/default-user.xml` file with the following lines. The intention is to modify the default user to enable SQL mode so that it can later create an administrator account with full administrative rights. [Official Docs](https://clickhouse.com/docs/operations/access-rights#enabling-access-control)

```xml
<access_management>1</access_management>
<named_collection_control>1</named_collection_control>
<show_named_collections>1</show_named_collections>
<show_named_collections_secrets>1</show_named_collections_secrets>
```

Save and then copy the `user.d/default-user.xml` file back to ClickHouse container.

```bash
docker cp users.d/default-user.xml clickhouse:/etc/clickhouse-server/users.d/default-user.xml
```

Enter the Clickhouse container in Docker

```bash
docker exec -it clickhouse bash
```

Login using default credentials

```bash
clickhouse-client --user default_write --password default_write
```

Create an admin account

```sql
CREATE USER admin_user IDENTIFIED BY 'admin_user';
```

Grant admin with full administrative rights

```sql
GRANT ALL ON *.* TO admin_user WITH GRANT OPTION;
```

Exit the clickhouse-client and Docker container.

```bash
exit
exit
```

Now we modify the `user.d/default-user.xml` file in our local directory back to the original one. Change the following 

```xml
<access_management>1</access_management>
<named_collection_control>1</named_collection_control>
<show_named_collections>1</show_named_collections>
<show_named_collections_secrets>1</show_named_collections_secrets>
```

to the original configuration to remove the default user's ability to create or modify user permissions.

```xml
<access_management>0</access_management>
```

### Create Read-only User

Enter Clickhouse Docker container.

```bash
docker exec -it clickhouse bash
```

Login with the admin credentials

```bash
clickhouse-client --user admin_user --password admin_user
```

Create a read-only profile with a default maximum execution time of 60 seconds. According to the [Official Grafana Docs](https://grafana.com/grafana/plugins/grafana-clickhouse-datasource/), we need to ensure that the read-only user have sufficient permissions to modify the `max_execution_time` setting required by the underlying clickhouse-go client.

Alternative is to set `readonly = 2`. Then we don't have to set the `max_execution_time CHANGEABLE_IN_READONLY`.

```sql
CREATE SETTINGS PROFILE readonly_profile SETTINGS readonly = 1, max_execution_time = 60;
```

```sql
ALTER SETTINGS PROFILE readonly_profile MODIFY SETTINGS max_execution_time CHANGEABLE_IN_READONLY;
```

Create read-only user

```sql
CREATE USER readonly_user IDENTIFIED BY 'readonly_user';
-- If you want the password to be hashed
-- CREATE USER readonly_user IDENTIFIED WITH sha256_password BY 'readonly_user';
```

Assign profile to read-only user

```sql
ALTER USER readonly_user SETTINGS PROFILE readonly_profile;
```

Grant `SELECT` privileges on the brazilian ecommerce database to the read-only user because by default, a new user has no access to any databases or tables. Must explicitly grant `SELECT` privileges to specific databases or tables.

```sql
GRANT SELECT ON brazilian_ecommerce.* TO readonly_user;
```

Exit the Clickhouse container

```bash
exit
exit
```

Once done we can delete the `users.xml` and `users.d/default-user.xml` files from our local `docker/` folder.

## Grafana

Once the container for Grafana is setup, we can access it at `http://localhost:3000`

We can login with the following [default credentials](https://grafana.com/docs/grafana/latest/setup-grafana/sign-in-to-grafana/)

Credentials for first time login

- Username: `admin`
- Password: `admin`

If we are logging in for first time, we will be prompted to change the password. For simplicity for this project, we can just change it to `admin123`. 

Update credentials

- Username: `admin`
- Password: `admin123`

Once logged in, we should install the plugin for ClickHouse. Go to "Connections" > "Add new connection". Then find ClickHouse and install it.

## Ports Used

- Grafana: `3000`
- ClickHouse HTTP: `8123`
- ClickHouse Client: `9000`

## To Do

- Slowly Changing Dimensions
- Materialization
- Data Lineage & Documentation
- ~~Surrogate Key~~
