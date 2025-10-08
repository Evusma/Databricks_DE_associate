## External DBs in Databricks

https://docs.databricks.com/aws/en/query-federation/postgresql?language=SQL

To introduce external tables from a PostgreSQL database into Unity Catalog in Azure Databricks, you have three main options:

1. **Using JDBC with a Foreign Catalog (Recommended for Read-Only Access):**

- Create a connection to your PostgreSQL database in Databricks.
- Create a foreign catalog using that connection. This mirrors the external PostgreSQL database in Unity Catalog.
- All tables in the external database become available as read-only tables in the foreign catalog. No need to register each table individually.
- Manage access and governance for these external tables using Unity Catalog.
- Avoid duplicating or moving data into Databricks storage.
- Query the external tables directly from Databricks, with query pushdown to the source system..
- Best for: Seamless, secure, and managed access to external data with Unity Catalog governance and permissions.
- How-to: Use the Catalog Explorer UI or SQL commands to create the connection and catalog.

```
CREATE CONNECTION IF NOT EXISTS connection 
TYPE postgresql
OPTIONS (
  host 'host',
  port 'port',
  user 'user',
  password 'password'
);

CREATE FOREIGN CATALOG IF NOT EXISTS catalog USING CONNECTION connection
OPTIONS (database 'database');
```

or

```
spark.sql(f"""
CREATE CATALOG IF NOT EXISTS <catalog_name>
USING 'jdbc'
OPTIONS (
    url 'jdbc:postgresql://<hostname>:<port>/<database>',
    user 'user',
    password 'password',
    driver 'driver'
    )
""")
```


2. **Using a Catalog only for the JDBC external tables (Read-Only Access):**
- Create a standard Unity Catalog catalog, not a foreign catalog.
- Manage access and governance for these external tables using Unity Catalog.
- Avoid duplicating or moving data into Databricks storage.
- Register the external table `USING JDBC` in Unity Catalog (that points to a PostgreSQL table using the JDBC data source). This creates a pointer in Unity Catalog, and queries on this table are pushed down to PostgreSQL; no data is ingested into Databricks storage.

If the catalog already contains Delta tables, you cannot use the USING JDBC approach to register external tables in the same schema as those Delta tables. Unity Catalog does not allow mixing managed (Delta/Iceberg) tables and external JDBC tables in the same schema or catalog. Attempting to do so will result in an error.

```
# Create a Unity Catalog catalog if it does not exist
spark.sql("CREATE CATALOG IF NOT EXISTS catalog")

# Set the current catalog context
spark.sql("USE CATALOG catalog")

# Create a schema (database) in the catalog if it does not exist
spark.sql("CREATE SCHEMA IF NOT EXISTS my_schema")

# Register an external table in the schema, pointing to a PostgreSQL table via JDBC
spark.sql(f"""
CREATE TABLE IF NOT EXISTS catalog.my_schema.table
USING JDBC
OPTIONS (
    url 'jdbc:postgresql://host:port/database',
    dbtable 'table',
    user '<username>',
    password '<password>',
    driver 'org.postgresql.Driver'
  )
""")
```
- The table is not ingested into Databricks; queries are pushed down to PostgreSQL.
- You must not mix managed (Delta) tables and JDBC external tables in the same schema.
- This approach is for registering a single external table, not for mirroring an entire external database as a foreign catalog


3. **Ingest Data via JDBC and Register as Managed/External Table:**

- Read data from PostgreSQL using Spark’s JDBC connector.
- Write the DataFrame as a managed or external table in a Unity Catalog catalog.
- Tables are now stored in Databricks (not live-linked to PostgreSQL).
- Best for: When you want to copy data from PostgreSQL into Databricks for further processing or analytics.
How-to:

```
df = spark.read.format("jdbc").options(
      url="jdbc:postgresql://<host>:<port>/<database>",
      dbtable="<schema>.<table>",
      user="<user>",
      password="<password>",
      driver="org.postgresql.Driver"
  ).load()

df.write.saveAsTable("your_catalog.your_schema.your_table")
```
or
```
jdbc_url = "jdbc:postgresql://<hostname>:<port>/<database>"
connection_properties = {
    "user": "<username>",
    "password": "<password>",
    "driver": "org.postgresql.Driver"
}

df = spark.read.jdbc(
    url=jdbc_url,
    table="<schema>.<table>",
    properties=connection_properties
)

df.write.saveAsTable("your_catalog.your_schema.your_table")
```


To summarise, to register a PostgreSQL table in the Databricks catalog without ingesting the data, you should use a JDBC connection. In Databricks, this is done using a foreign catalog or an external table with a JDBC data source in a dedicated catalog.


## JDBC feature
The JDBC table feature in Databricks Unity Catalog allows you to register external tables that reference data in JDBC-accessible databases (like PostgreSQL) **without ingesting the data into Databricks storage.** This feature **must be enabled in your workspace** to use SQL statements like `CREATE TABLE ... USING JDBC ...` that register external tables in Unity Catalog and push queries down to the source database.

To check or enable this feature, you need to:
- Be on a supported Databricks Runtime.
- Have Unity Catalog enabled in your workspace.
- Have the JDBC table feature enabled by your Databricks admin.

This is a workspace-level setting that may require admin action. If you do not see errors when running `CREATE TABLE ... USING JDBC ...`, the feature is likely enabled. If you are unsure, contact your Databricks workspace admin to confirm that the JDBC table feature is enabled for Unity Catalog in your workspace.


## csv files in spark
If you want to use a csv file with Spark, you should upload it to DBFS or to a volum. Having the file in the same worksapce directory as your notebook is not sufficient. You can do this by:

- Using the Databricks UI "Upload Data" button and selecting "DBFS" as the destination.
- Using %fs cp or dbutils.fs.cp to copy from workspace to DBFS.

For example, to copy a file from the workspace to DBFS:
```
%python
dbutils.fs.cp(
    "file:/databricks/driver/your_file.csv",
    "dbfs:/FileStore/your_file.csv"
)
```
After copying, you will be able to see and access your file in DBFS using dbutils.fs.ls("dbfs:/FileStore/") and read it with Spark.

In your notebook:
```
%sh
ls
```
You see the file in the workspace directory, but Spark cannot access it directly from there.

To read the CSV file with Spark, you need to use the DBFS path:
```python
df = spark.read.csv("dbfs:/FileStore/your_file.csv", header=True, inferSchema=True)
```
