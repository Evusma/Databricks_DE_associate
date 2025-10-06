## External DBs in Databricks
To register a PostgreSQL table in the Databricks catalog without ingesting the data, you should create an external table using a JDBC connection. In Databricks (especially with Unity Catalog), this is done using a foreign catalog or an external table with a JDBC data source.

You need to create a catalog using JDBC in Databricks Unity Catalog if you want to make external databases (like PostgreSQL) accessible as part of your Databricks catalog structure, without ingesting the data. This allows you to:
- Query external tables directly from Databricks using Spark SQL or Python, with query pushdown to the source system.
- Manage access and governance for these external tables using Unity Catalog.
- Avoid duplicating or moving data into Databricks storage.

Creating a JDBC catalog is the recommended way to register and organize external data sources in Unity Catalog, so you can treat them similarly to native Databricks tables and schemas

Here is how you can register the table using SQL (recommended for Unity Catalog):
```
%sql
CREATE CATALOG IF NOT EXISTS pg_catalog
USING 'jdbc'
OPTIONS (
  url 'jdbc:postgresql://<hostname>:<port>/<database>',
  user '${secrets/my_scope/pg_user}',
  password '${secrets/my_scope/pg_password}',
  driver 'org.postgresql.Driver'
);
```
Then, create an external table referencing your PostgreSQL table:
```
%sql
CREATE TABLE IF NOT EXISTS pg_catalog.<schema>.<table>
USING JDBC
OPTIONS (
  url 'jdbc:postgresql://<hostname>:<port>/<database>',
  dbtable '<schema>.<table>',
  user '${secrets/my_scope/pg_user}',
  password '${secrets/my_scope/pg_password}',
  driver 'org.postgresql.Driver'
);
```
This approach registers the table in the Databricks catalog and queries will be pushed down to PostgreSQL, so data is not ingested into Databricks storage.

You can register a PostgreSQL table in the Databricks catalog as an external table using Python by executing the relevant SQL with spark.sql:
```
spark.sql("""
CREATE TABLE IF NOT EXISTS <catalog>.<schema>.<table>
USING JDBC
OPTIONS (
  url 'jdbc:postgresql://<hostname>:<port>/<database>',
  dbtable '<schema>.<table>',
  user '<username>',
  password '<password>',
  driver 'org.postgresql.Driver'
)
""")
```

The JDBC table feature in Databricks Unity Catalog allows you to register external tables that reference data in JDBC-accessible databases (like PostgreSQL) **without ingesting the data into Databricks storage.** This feature **must be enabled in your workspace** to use SQL statements like `CREATE TABLE ... USING JDBC ...` that register external tables in Unity Catalog and push queries down to the source database.

To check or enable this feature, you need to:

- Be on a supported Databricks Runtime.
- Have Unity Catalog enabled in your workspace.
- Have the JDBC table feature enabled by your Databricks admin.

This is a workspace-level setting that may require admin action. If you do not see errors when running `CREATE TABLE ... USING JDBC ...`, the feature is likely enabled.

If you are unsure, contact your Databricks workspace admin to confirm that the JDBC table feature is enabled for Unity Catalog in your workspace.


## csv files in spark
If you want to use a csv file with Spark, you should upload it to DBFS. Having the file in the same worksapce directory as your notebook is not sufficient. You can do this by:

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
