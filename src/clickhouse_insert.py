import clickhouse_connect
import pandas as pd

def main():
    # Connect to ClickHouse server
    # Ensure that ClickHouse is running and the database 'brazilian_ecommerce' exists before running this script
    client = clickhouse_connect.get_client(
        host='localhost', 
        port=8123, 
        username='admin', 
        password='admin', 
        database='brazilian_ecommerce'
    )

    try:
        # Read CSV file into DataFrame
        dim_customers = pd.read_csv('data/processed/dim_customers.csv')
        dim_sellers = pd.read_csv('data/processed/dim_sellers.csv')
        dim_products = pd.read_csv('data/processed/dim_products.csv')
        fact_order_items = pd.read_csv('data/processed/fact_order_items.csv')

        # Start transaction
        client.command('BEGIN TRANSACTION')

        # Insert DataFrames into ClickHouse tables
        # The column names in the DataFrames must match the column names in the ClickHouse tables
        client.insert_df('dim_customers', dim_customers)
        client.insert_df('dim_sellers', dim_sellers)
        client.insert_df('dim_products', dim_products)
        client.insert_df('fact_order_items', fact_order_items)

        # Commit transaction
        client.command('COMMIT')

        print("Data inserted successfully.")

    except Exception as e:
        # Rollback transaction in case of error
        client.command('ROLLBACK')
        print("Transaction rolled back due to error:", e)

    finally:
        # Close the client connection
        client.close()

if __name__ == "__main__":
    main()