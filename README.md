# Data Analysis Project on Brazilian E-Commerce Dataset

## Project Overview

## 🐍 Python Environment Setup

```bash
git clone https://github.com/zzhenjie01/brazilian-ecommerce.git
```

```bash
uv sync
```

## 🐳 Docker Setup

- [ClickHouse Network Ports](https://clickhouse.com/docs/guides/sre/network-ports)
- [ClickHouse Official Image](https://hub.docker.com/_/clickhouse)

Make sure Docker Desktop is running in the background. Then `cd` into `docker/` folder.

```bash
cd docker
```

Then, run the following command to start the ClickHouse and Grafana Docker containers.

```bash
docker-compose --project-name brazilian-ecommerce up -d
```

**Useful Docker commands:**

```bash
docker-compose stop           # Stop
docker-compose down           # Stop and remove
docker-compose logs -f        # View logs
docker-compose restart        # Restart
```

We can then use tools like DbVisualizer to connect to the Dockerized ClickHouse container at `http://localhost:8132`.

Default Credentials:

- Username: `default_write`
- Password: `default_write`

Be sure to set the display timezone to UTC-3 Brazil Standard Time to prevent confusion. In DbVisualzier it is "Tools" > "Tool Properties".

![dbvisualizer_1](./attachments/dbvisualizer_1.png)
![dbvisualizer_2](./attachments/dbvisualizer_2.png)

## ⭐ Create Tables

We can run `src/clickhouse_ddl.sql` in DbVisualizer connected to ClickHouse to create the fact and dimension tables definitions.

![dbvisualizer_3](./attachments/dbvisualizer_1.png)
![dbvisualizer_4](./attachments/dbvisualizer_2.png)
![dbvisualizer_5](./attachments/dbvisualizer_3.png)

## 💽 Data Ingestion

To insert the fact and dimension tables into ClickHouse, run the Python script `src/clickhouse_insert.py`. In general, it is better to run python script as it allows automation.

Go to the project root directory and run the following

```bash
python src/clickhouse_insert.py
```

Using the following commands to insert will result in error because the parquet files lives locally. When the clickhouse client in the Docker container tries to find the file on its own file system, it won't be able to find it.

```bash
docker exec -i clickhouse clickhouse-client --query="INSERT INTO brazilian_ecommerce.fact_order_items FORMAT Parquet" < data/model/fact_order_items.parquet
```

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

## 🔌 Ports Used

- Grafana: `3000`
- ClickHouse HTTP: `8123`
- ClickHouse Client: `9000`
