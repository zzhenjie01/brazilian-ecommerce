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

There is a missing payment in `order_payments` based on `order_id` that is not present in `order_items`. Also we note that there are some null values in some datetime columns and also payment value columns in the fact table. One explanation is that some of these records are orders that are just placed and are either:

1) waiting for customer payment (missing `total_payment_value` and `payment_installments`)
2) or waiting for order to be approved by platform (missing `order_approved_at`)
3) or waiting for seller's packed parcel to arrive at logistics partner warehouse (missing `order_delivered_carrier_date`)
4) or waiting for customer to receive the parcel (missing `order_delivered_customer_date`)

We may not want to fill these missing values with a value because substituting a zero for missing price or payment values may inaccurately skew aggregate calculations such as `AVG()`.

We casted columns in Pandas to match the datatype that is required by the ClickHouse schema. Also, we note that `int32` is different from `Int32`. The former is NumPy's `int32` data type which cannot hold nulls while the latter is Pandas' dedicated Int32Dtype ExtensionDtype which is a newer, nullable integer data type introduced in Pandas to address the issue of NaN forcing integer columns to become floats. For `float64` columns we don't have to cast anything as `float64` can store `NaN`.

## ClickHouse

Primary keys in ClickHouse define the sort order of data parts on disk and create a sparse primary index. This index is used to efficiently locate blocks of rows for queries that filter on the primary key columns. However, unlike traditional relational databases, a ClickHouse primary key does not enforce uniqueness. Duplicate values are allowed in primary key columns. The primary key is crucial for query performance, especially for range queries and filters on the primary key columns.

[Official ClickHouse Docs](https://clickhouse.com/docs/best-practices/choosing-a-primary-key)

ClickHouse explicitly does not support foreign key constraints. This means there are no mechanisms to enforce referential integrity between tables at the database level. Thus, when working with ClickHouse, we typically manage relationships between tables through application-level logic or by designing denormalized tables to minimize the need for joins.

ClickHouse does not support transactional semantics `BEGIN`, `COMMIT`, `ROLLBACK` in the same way that SQL databases like PostgreSQL or MySQL do. At the time of writing, the support is only in experimental stage. ClickHouse inserts are atomic per query — each `INSERT` is its own “transaction.” So, if one table fails to insert, the others will not be rolled back automatically, but the failed one simply won’t insert anything.

### DDL

Dimension Tables:

- For the keys, we use `UInt64` instead of `UInt32` because we forsee that in the future, there may be many more records.
- For lattitudes and longitudes, we chose `Float64` as it is more precise than `Float32` which may matter when doing geospatial visualization on only a single country.

Fact Table:

- Used `Datetime` instead of `Datetime64` as the timestamp data is only up till precision level of seconds instead of milliseconds or nanoseconds.
- Set `DateTime` to be Sao Paulo although the best practice is to store in UTC time in database which requires converstion during ETL and conversion in the application layer. This introduces overhead.
- For monetary quantities like `price`, we use `Decimal(15, 2)` datatype since floats are inaccurate in representing money. We assume that the largest money we are going to handle is 1 tillion which has 15 digits including the 2 decimal digits.

## Errors

Occured when I try to convert the timestamp in string to actual datetime datatype localized to Sao Paulo time. This is due to Brazil using Daylight Savings Time (DST) for certain periods of the year.

```text
---------------------------------------------------------------------------
AmbiguousTimeError                        Traceback (most recent call last)
Cell In[14], line 14
     12     fact_order_items[col] = pd.to_datetime(fact_order_items[col], errors="coerce") # coerce errors/nuls to NaT
     13     # Assign Sao Paulo timezone without shifting
---> 14     fact_order_items[col] = fact_order_items[col].dt.tz_localize("America/Sao_Paulo")
     16 fact_order_items["payment_installments"] = fact_order_items["payment_installments"].astype("UInt32")
     17 fact_order_items["average_review_score"] = fact_order_items["average_review_score"].astype("float32")

File c:\Users\zzhen\projects\brazilian-ecommerce\.venv\Lib\site-packages\pandas\core\accessor.py:112, in PandasDelegate._add_delegate_accessors.<locals>._create_delegator_method.<locals>.f(self, *args, **kwargs)
    111 def f(self, *args, **kwargs):
--> 112     return self._delegate_method(name, *args, **kwargs)

File c:\Users\zzhen\projects\brazilian-ecommerce\.venv\Lib\site-packages\pandas\core\indexes\accessors.py:132, in Properties._delegate_method(self, name, *args, **kwargs)
    129 values = self._get_values()
    131 method = getattr(values, name)
--> 132 result = method(*args, **kwargs)
    134 if not is_list_like(result):
    135     return result

File c:\Users\zzhen\projects\brazilian-ecommerce\.venv\Lib\site-packages\pandas\core\indexes\datetimes.py:293, in DatetimeIndex.tz_localize(self, tz, ambiguous, nonexistent)
    286 @doc(DatetimeArray.tz_localize)
    287 def tz_localize(
    288     self,
   (...)    291     nonexistent: TimeNonexistent = "raise",
...
   1098 dtype = tz_to_dtype(tz, unit=self.unit)

File pandas/_libs/tslibs/tzconversion.pyx:371, in pandas._libs.tslibs.tzconversion.tz_localize_to_utc()

AmbiguousTimeError: Cannot infer dst time from 2018-02-17 23:50:41, try using the 'ambiguous' argument
```