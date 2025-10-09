import os
import clickhouse_connect

def main():
    # Connect to ClickHouse
    client = clickhouse_connect.get_client(
        host='localhost',
        port=8123,
        username='admin',
        password='admin',
        database='brazilian_ecommerce'
    )

    # Set current script as working directory
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    # Paths to your Parquet files
    tables = {
        "dim_customers": "../data/processed/dim_customers.parquet",
        "dim_sellers": "../data/processed/dim_sellers.parquet",
        "dim_products": "../data/processed/dim_products.parquet",
        "fact_order_items": "../data/processed/fact_order_items.parquet"
    }

    try:
        # Insert each Parquet file
        for table_name, parquet_path in tables.items():
            print(f"Inserting {table_name} from {parquet_path} ...")
            with open(parquet_path, 'rb') as f:
                client.command(
                    f"INSERT INTO {table_name} FORMAT Parquet",
                    data=f.read()
                )
            print(f"{table_name} inserted successfully.")

        print("All data inserted successfully.")

    except Exception as e:
        print("Error while inserting data:", e)

    finally:
        client.close()

if __name__ == "__main__":
    main()
