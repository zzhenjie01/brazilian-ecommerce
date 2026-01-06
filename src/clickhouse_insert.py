import os
import clickhouse_connect
from dotenv import load_dotenv

def main():
    # Load environment variables from .env file
    load_dotenv()

    CLICKHOUSE_WRITE_USER = os.getenv("CLICKHOUSE_WRITE_USER")
    CLICKHOUSE_WRITE_PASSWORD = os.getenv("CLICKHOUSE_WRITE_PASSWORD")
    CLICKHOUSE_DB = os.getenv("CLICKHOUSE_DB")
    
    # Connect to ClickHouse
    client = clickhouse_connect.get_client(
        host='localhost',
        port=8123,
        username=CLICKHOUSE_WRITE_USER,
        password=CLICKHOUSE_WRITE_PASSWORD,
        database=CLICKHOUSE_DB
    )

    # Set current script as working directory
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    # Paths to your Parquet files
    tables = {
        "dim_dates": "../data/model/dim_dates.parquet",
        "dim_customers": "../data/model/dim_customers.parquet",
        "dim_sellers": "../data/model/dim_sellers.parquet",
        "dim_products": "../data/model/dim_products.parquet",
        "fact_order_items": "../data/model/fact_order_items.parquet"
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
