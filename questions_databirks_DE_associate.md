# Databricks Data Engineer Associate Practice Exam Questions

## **Question**
A data organization leader is upset about the data analysis team’s reports being different from the data engineering team’s reports. The leader believes the siloed nature of their organization’s data engineering and data analysis architectures is to blame. Which of the following describes how a data lakehouse could alleviate this issue?

*Response*

Both teams would use the same source of truth for their work

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data engineer has three notebooks in an ELT pipeline. The notebooks need to be executed in a specific order for the pipeline to complete successfully. The data engineer would like to use Delta Live Tables to manage this process. Which of the following steps must the data engineer take as part of implementing this pipeline using Delta Live Tables?

*Response*

They need to create a Delta Live Tables pipeline from the Jobs page.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A dataset has been defined using Delta Live Tables and includes an expectations clause:
```CONSTRAINT valid_timestamp EXPECT (timestamp > '2020-01-01')```
What is the expected behavior when a batch of data containing data that violates these constraints is processed?

*Response*

Records that violate the expectation are added to the target dataset and recorded as invalid in the event log.

**Explanation:** This is the default behavior when using the EXPECT clause without specifying an action like ON VIOLATION DROP ROW or ON VIOLATION FAIL UPDATE.

Optional behaviors:

Drop records → `ON VIOLATION DROP ROW`

Fail pipeline → `ON VIOLATION FAIL UPDATE`

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data engineer has written the following query:

```
SELECT *
FROM json.`/path/to/json/file.json`;
```

The data engineer asks a colleague for help to convert this query for use in a Delta Live Tables (DLT) pipeline. The query should create the first table in the DLT pipeline.
Which of the following describes the change the colleague needs to make to the query?

*Response*

They need to add a CREATE LIVE TABLE table_name AS line at the beginning of the query.

**Explanation:** To convert a standard SQL query into a Delta Live Tables (DLT) SQL pipeline, you must define a live table using the CREATE LIVE TABLE syntax. This tells DLT to treat the result of the query as a managed table in the pipeline.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data engineering team has created a series of tables using Parquet data stored in an external system. The team is noticing that after appending new rows to the data in the external system, their queries within Databricks are not returning the new rows. They identify the caching of the previous data as the cause of this issue. Which of the following approaches will ensure that the data returned by queries is always up-to-date?

*Response*

The tables should be converted to the Delta format

**Explanation:** When using external Parquet tables, Spark SQL may cache metadata and data, leading to stale query results if the underlying files are updated outside of Spark. Delta Lake solves this by:
- Tracking metadata and schema changes
- Supporting ACID transactions
- Automatically handling data consistency
- Enabling time travel and data skipping

By converting the tables to Delta format, the data engineering team ensures that queries always reflect the latest data, even after appends or updates.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
Which of the following Structured Streaming queries is performing a hop from a Bronze table to a Silver table?

*Response*

```
(spark.table("sales")
.withColumn("avgPrice", col("sales") / col("units"))
.writeStream
.option("checkpointLocation", checkpointPath)
.outputMode("append")
.table("cleanedSales"))
```

**Explanation:** This query represents a hop from a Bronze table to a Silver table in the medallion architecture:
- Bronze layer: Contains raw, ingested data (e.g., sales table).
- Silver layer: Contains cleaned and enriched data, such as derived columns, filtered records, or joined datasets.

In this case:
- The sales table is assumed to be raw data (Bronze).
- The transformation adds a new column avgPrice, which is a form of data enrichment.
- The result is written to a new table cleanedSales, which fits the Silver layer.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A table customerLocations exists with the following schema:
```
id STRING,
date STRING,
city STRING,
country STRING
A senior data engineer wants to create a new table from this table using the following command:
CREATE TABLE customersPerCountry AS
SELECT country,
COUNT(*) AS customers
FROM customerLocations
GROUP BY country;
```
A junior data engineer asks why the schema is not being declared for the new table.
Which of the following responses explains why declaring the schema is not necessary?

*Response*

CREATE TABLE AS SELECT statements adopt schema details from the source table and query.

**Explanation:** When using a CREATE TABLE AS SELECT (CTAS) statement in Spark SQL (and Databricks), the schema of the new table is automatically inferred from the result of the SELECT query. This means: You don’t need to declare the schema manually. Spark uses the column names and data types from the query result to define the schema of the new table

-------------------------------------------------------------------------------------------------------------------------
## **Question**
Which of the following commands will return records from an existing Delta table my_table where duplicates have been removed?

*Response*

`SELECT DISTINCT * FROM my_table;`

**Explanation:** To remove duplicates from the result set of a query in Spark SQL (or Databricks SQL), you use the SELECT DISTINCT statement. This returns only unique rows from the table, effectively filtering out duplicates without modifying the underlying table.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data engineer wants to horizontally combine two tables as a part of a query. They want to use a shared column as a key column, and they only want the query result to contain rows whose value in the key column is present in both tables. Which of the following SQL commands can they use to accomplish this task?

*Response*

INNER JOIN

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A junior data engineer has ingested a JSON file into a table raw_table with the following schema:

```
cart_id STRING,
items ARRAY<item_id:STRING>
```

The junior data engineer would like to unnest the items column in raw_table to result in a new table with the following schema:

```
cart_id STRING,
item_id STRING
```

Which of the following commands should the junior data engineer run to complete this task?

*Response*

```
SELECT cart_id, explode(items) AS item_id FROM raw_table;
```

**Explanation:** To unnest or flatten an array column in Spark SQL (or Databricks SQL), you use the EXPLODE() function. It transforms each element in the array into a separate row, which is exactly what's needed 

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data engineer has ingested a JSON file into a table raw_table with the following schema:
```
transaction_id STRING,
payload ARRAY<customer_id:STRING, date:TIMESTAMP, store_id:STRING>
```
The data engineer wants to efficiently extract the date of each transaction into a table with the following schema:
```
transaction_id STRING,
date TIMESTAMP
```
Which of the following commands should the data engineer run to complete this task?

*Response*

```
SELECT transaction_id, payload.date FROM raw_table;
```

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data analyst has provided a data engineering team with the following Spark SQL query:
```
SELECT district,
avg(sales)
FROM store_sales_20220101
GROUP BY district;
```
The data analyst would like the data engineering team to run this query every day. The date at the end of the table name (20220101) should automatically be replaced with the current date each time the query is run.
Which of the following approaches could be used by the data engineering team to efficiently automate this process?

*Response*

They could wrap the query using PySpark and use Python’s string variable system to automatically update the table name.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data engineer has ingested data from an external source into a PySpark DataFrame raw_df. They need to briefly make this data available in SQL for a data analyst to perform a quality assurance check on the data. Which of the following commands should the data engineer run to make this data available in SQL for only the remainder of the Spark session?

*Response*

`raw_df.createOrReplaceTempView("raw_df")`

**Explanation:** This command registers the PySpark DataFrame raw_df as a temporary view named "raw_df" that can be queried using Spark SQL within the current Spark session. The view only lasts for the duration of the Spark session — perfect for short-term tasks like QA checks.
- `raw_df.createTable("raw_df")`  Not a valid PySpark method.
- `raw_df.write.save("raw_df")`   Saves data to storage, not for SQL querying.
- `raw_df.saveAsTable("raw_df")`  Creates a permanent table, not temporary.

-------------------------------------------------------------------------------------------------------------------------
## **Question**

A data engineer needs to dynamically create a table name string using three Python variables: region, store, and year. An example of a table name is below when region = "nyc", store = "100", and year = "2021": nyc100_sales_2021 Which of the following commands should the data engineer use to construct the table name in Python?

*Response*

`f"{region}{store}sales{year}"`

-------------------------------------------------------------------------------------------------------------------------
## **Question**

A data engineer has developed a code block to perform a streaming read on a data source. The code block below is returning an error:
```
(spark
.read
.schema(schema)
.format("cloudFiles")
.option("cloudFiles.format", "json")
.load(dataSource)
)
```
Which of the following changes should be made to the code block to configure the block to successfully perform a streaming read?

*Response*

The .read line should be replaced with .readStream.

**Explanation:** To perform a streaming read in PySpark using Auto Loader (cloudFiles), you must use: spark.readStream instead of: spark.read. This tells Spark that you're initiating a structured streaming job, which is required for reading data continuously from a source like cloud storage.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data engineer has configured a Structured Streaming job to read from a table, manipulate the data, and then perform a streaming write into a new table.
The code block used by the data engineer is below:
```
(spark.table("sales")
.withColumn("avg_price", col("sales") / col("units"))
.writeStream
.option("checkpointLocation", checkpointPath)
.outputMode("complete")
._____
.table("new_sales")
)
```
If the data engineer only wants the query to execute a single micro-batch to process all of the available data, which of the following lines of code should the data engineer use to fill in the blank?

*Response*

`trigger(once=True)`

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data engineering team is in the process of converting their existing data pipeline to utilize Auto Loader for incremental processing in the ingestion of JSON files. One data engineer comes across the following code block in the Auto Loader documentation:
```
(streaming_df = spark.readStream.format("cloudFiles")
.option("cloudFiles.format", "json")
.option("cloudFiles.schemaLocation", schemaLocation)
.load(sourcePath))
```
Assuming that schemaLocation and sourcePath have been set correctly, which of the following changes does the data engineer need to make to convert this code block to use Auto Loader to ingest the data?

*Response*

There is no change required. The inclusion of format("cloudFiles") enables the use of Auto Loader.

**Explanation:** Auto Loader is activated in Databricks by using: `format("cloudFiles")`
This tells Spark to use Databricks' Auto Loader for incremental and efficient ingestion of files from cloud storage (e.g., S3, ADLS, GCS). The .option("cloudFiles.format", "json") specifies the format of the incoming files.
As long as:
- schemaLocation is set to a valid path for storing inferred schemas (this is the location where auto loader track schema evolution and avoid re-infering the schema every time the stream starts, it should be a persistent path, ideally in DBFS or mounted cloud storage)
- sourcePath points to the correct cloud directory (this is the location of the data files you want to ingest, it points to a directory in cloud storage eg S3, ADLS or DBFS where new files are expected to arrive)

...then no additional changes are needed to use Auto Loader.

sourcePath ->	Where the data files are located	-> "s3://my-bucket/data/json/"

schemaLocation ->	Where schema metadata is stored ->	"dbfs:/schemas/json_ingest/"

-------------------------------------------------------------------------------------------------------------------------
## **Question**
Which of the following data workloads will utilize a Bronze table as its source?

*Response*

A job that enriches data by parsing its timestamps into a human-readable format

**Explanation:** In the medallion architecture used in the Databricks Lakehouse Platform, data is typically organized into three layers:
- Bronze: Raw, ingested data—often semi-structured or unstructured, and ingested from streaming or batch sources. This layer captures data as-is, with minimal transformation.
- Silver: Cleaned and enriched data—includes filtering, joins, and parsing.
- Gold: Aggregated and business-level data—used for reporting, dashboards, and ML features.

So, a job that ingests raw data from a streaming source fits the Bronze layer, as it’s the first step in the pipeline.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
Which of the following data workloads will utilize a Silver table as its source?

*Response*

A job that aggregates cleaned data to create standard summary statistics

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data engineer is overwriting data in a table by deleting the table and recreating the table. Another data engineer suggests that this is inefficient and the table should simply be overwritten instead. Which of the following reasons to overwrite the table instead of deleting and recreating the table is incorrect?

*Response*

Overwriting a table results in a clean table history for logging and audit purposes.

**Explanation:** This statement is incorrect because overwriting a Delta table does not result in a clean history. In fact, one of the key features of Delta Lake is that it preserves the table history, even when you overwrite the data. This allows for: Time Travel to previous versions, Auditability of changes, Debugging and rollback capabilities

-------------------------------------------------------------------------------------------------------------------------
## **Question**
Which of the following statements describes Delta Lake?

*Response*

Delta Lake is an open format storage layer that delivers reliability, security, and performance.

**Explanation:** Delta Lake is an open-source storage layer that brings ACID transactions, schema enforcement, time travel, and scalable metadata handling to data lakes. It enhances reliability and performance for big data workloads on platforms like Databricks.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
Which of the following approaches can the data engineer use to obtain a version-controllable configuration of the Job's schedule and configuration?

*Response*

They can download the JSON equivalent of the job from the Job's page

**Explanation:** Databricks allows data engineers to export the JSON configuration of a job directly from the job's UI. This JSON includes: Job name, Schedule, Tasks, Cluster configuration, Libraries, Parameters. By downloading and version-controlling this JSON (e.g., storing it in a Git repository), engineers can: Track changes over time, Reuse or redeploy jobs programmatically via the Databricks Jobs API, Integrate with CI/CD pipelines

-------------------------------------------------------------------------------------------------------------------------
## **Question**
Which of the following benefits of using the Databricks Lakehouse Platform is provided by Delta Lake?

*Response*

The ability to support batch and streaming workloads

**Explanation:** This is a key benefit of the data lakehouse architecture that is not available in traditional data warehouses:
- A data lakehouse combines the scalability and flexibility of data lakes with the structured data management and performance of data warehouses.
- It supports both batch and streaming data processing on the same platform and data, enabling real-time analytics and historical reporting together.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
Which of the following code blocks will remove the rows where the value in column age is greater than 25 from the existing Delta table my_table and save the updated table?

*Response*

`DELETE FROM my_table WHERE age > 25;`

-------------------------------------------------------------------------------------------------------------------------
## **Question**
Which part of the Databricks Platfrom can a data engineer use to revoke permissions from users on tables?

*Response*

Data Explorer (Catalog Explorer)

-------------------------------------------------------------------------------------------------------------------------
## **Question**
Which of the following data lakehouse features results in improved data quality over a traditional data lake?

*Response*

A data lakehouse supports ACID-compliant transactions.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data architect is designing a data model that works for both video-based machine learning workloads and highly audited batch ETL/ELT workloads. Which of the following desctibes how using a data lakehouse can help the data architect meet the needs of both workloads?

*Response*

A data lakehouse stores unstructured data and is ACID-complaint.

**Explanation:** This statement highlights a unique benefit of the data lakehouse architecture:
- A data lakehouse can store unstructured data (like video, images, logs) in open formats such as Parquet, making it suitable for machine learning workloads.
- At the same time, it provides ACID transaction guarantees through technologies like Delta Lake, which is essential for audited batch ETL/ELT workloads.
- This combination of flexibility (for ML) and reliability (for ETL) is not available in traditional data warehouses, which typically only support structured data and lack native support for unstructured formats.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
In the Databricks environment, when working with Delta tables to ensure data consistency, which specific command allows you to write data into a Delta table while preventing the inclusion of duplicate records?

*Response*
MERGE

**Explanation:** The MERGE command in Databricks is used to merge a source DataFrame into a target Delta table. It allows you to insert new records and update or delete existing ones based on a condition. This helps in avoiding the writing of duplicate records by ensuring that only new or modified records are inserted or updated, respectively.

MERGE command is used to write data into a Delta table while avoiding the writing of duplicate records. It allows to perform an "upsert" operation, which means that it will insert new records and update existing records in the Delta table based on a specified condition. This helps maintain data integrity and avoid duplicates when adding new data to the table.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
In which of the following scenarios should a data engineer use the MERGE INTO command instead of the INSERT INTO command?

*Response*

When the target table cannot contain duplicate records

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data analyst has successfully created a Delta table named sales, which is extensively used by the entire data analysis team for various reporting and analytical tasks. Seeking to maintain the integrity and cleanliness of this data, they have requested assistance from the data engineering team to implement a suite of thorough data validation tests. Notably, while the data analyst team primarily leverages SQL for their operations, the data engineering team prefers using Python within the PySpark framework for their testing procedures. Considering this context, which command should the data engineering team utilize to access the sales Delta table in PySpark?

*Response*

`Spark.table(“sales”)`

**Explanation:** The command `spark.table("sales")` is used in PySpark to access a table named 'sales'. This method is appropriate for use by the data engineering team that prefers Python over SQL. 
- Option `SELECT * FROM sales` is a SQL query and not valid in a PySpark context. 
- Option `spark.sql("sales")` is incorrect because it seems to be incorrectly formatted for querying a table using spark.sql() which requires a SQL statement. 
- Option `spark.delta.table("sales")`, is not a valid PySpark method.

spark.table() function in PySpark allows access to a registered table within the SparkSession.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
In a scenario where a data engineer initiates the creation of a new database using the command:
`CREATE DATABASE IF NOT EXISTS customer360;`
Determine the default location where the 'customer360' database will be stored within the Databricks environment.


*Response*

Dbfs:/user/hive/warehouse

**Explanation:** By default, databases created in Databricks are stored in the Hive warehouse directory, which is typically 'dbfs:/user/hive/warehouse'. This is the default location used to store the metadata for databases and tables unless explicitly specified otherwise when creating the database.

[Databricks Data Engineering Preparation Question 8: Where Does Your Databricks Database Live? | by THE BRICK LEARNING | Towards Data Engineering | Medium](https://medium.com/towards-data-engineering/databricks-data-engineering-preparation-question-8-where-does-your-databricks-database-live-67b86f8d9843)

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data engineer needs to create a database called customer360 at the location /customer/customer360. The data engineer is unsure if one of their colleagues has already created the database. Which of the following commands should the data engineer run to complete this task?

*Response*

`CREATE DATABASE IF NOT EXISTS customer360 LOCATION '/customer/customer360';`

-------------------------------------------------------------------------------------------------------------------------
## **Question**
In a scenario where a data engineer is working with Spark SQL and attempts to delete a table named 'my_table' by executing the command: DROP TABLE IF EXISTS my_table;, the engineer observes that both the data files and metadata files related to the table are removed from the file system. What is the underlying reason for the deletion of all associated files?

*Response*

The table was managed

**Explanation:** When a managed table is dropped in Spark SQL, both the data files and the metadata are deleted from the file system. This is because managed tables are fully controlled by Spark, including their storage locations and lifecycle.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A junior data engineer needs to create a Spark SQL table my_table for which Spark manages both the data and the metadata. The metadata and data should also be stored in the Databricks Filesystem (DBFS). Which of the following commands should a senior data engineer share with the junior data engineer to complete this task?

*Response*

`CREATE TABLE my_table (id STRING, value STRING);`

**Explanation:** This command creates a managed Spark SQL table in Databricks. In a managed table:
- Spark manages both the data and the metadata
- The data is stored in the Databricks Filesystem (DBFS) under the default warehouse location (usually /user/hive/warehouse)
- You don’t need to specify a path or format — Spark handles it automatically

incorrect:
- USING org.apache.spark.sql.parquet OPTIONS (PATH …): Creates an external table, not managed.
- CREATE MANAGED TABLE … OPTIONS (PATH …): Invalid syntax—managed tables don’t use OPTIONS(PATH …). 
- CREATE MANAGED TABLE …: Not valid SQL syntax; MANAGED is not a keyword in Spark SQL.
- USING DBFS: DBFS is not a valid format specifier.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
In the context of executing a CREATE TABLE AS SELECT statement in Databricks, what is one advantage of creating an external table using Parquet format over using CSV format?

*Response*

Parquet files have a well-defined schema

**Explanation:** While Parquet files can indeed be optimized and partitioned, the key benefit mentioned in the context of using a CREATE TABLE AS SELECT statement is that Parquet files have a well-defined schema. This allows for better schema enforcement and metadata handling compared to CSV files, which do not natively include schema information.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
As a data engineer, you are given a table named stores that contains a column named city, which holds string values representing the names of cities. You need to apply some custom logic to the city column as part of a specific data processing use case. To implement this custom logic efficiently across the dataset within Databricks, you want to create a SQL user-defined function (UDF). Which of the following code blocks will allow you to create this SQL UDF?

*Response*

`CREATE FUNCTION custom_logic(city STRING) RETURNS STRING RETURN UPPER(city);`

**Explanation:** The correct way to define a SQL user-defined function (UDF) in Databricks is by using the CREATE FUNCTION syntax. This option follows this syntax correctly by creating a function named custom_logic, taking a string argument city, and returning the uppercase version of the input string. 

Other options either use incorrect syntax (e.g., CREATE UDF instead of CREATE FUNCTION) or incorrect logic (e.g., RETURNS CASE WHEN).

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data engineer needs to apply custom logic to string column city in table stores for a specific use case. In order to apply this custom logic at scale, the data engineer wants to create a SQL user-defined function (UDF).
Which of the following code blocks creates this SQL UDF?

*Response*

![UDF](./images/udf.png)

**Explanation:**

[Introducing SQL User-Defined Functions | Databricks Blog](https://www.databricks.com/blog/2021/10/20/introducing-sql-user-defined-functions.html)

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data analyst is working with a SQL program that consists of a series of queries. The requirement is to automate the execution of this program on a daily basis. However, there is a specific condition: the final query within the program should only be executed on Sundays. The data analyst has reached out to the data engineering team for assistance in implementing this scheduling logic. Which of the following approaches can the data engineering team utilize to achieve this goal?

*Response*

They could wrap the queries using PySpark and use Python’s control flow system to determine when to run the final query

**Explanation:** Wrapping the queries using PySpark and using Python's control flow system to determine when to run the final query is the most feasible solution. This approach allows precise control over which part of the code runs and when, which fits the requirement of running the final query only on Sundays. 

Other options like submitting a feature request, running the entire program on Sundays, restricting access to the source table, or redesigning the data model are either not practical, overly complex, or do not address the requirement directly.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data engineer is responsible for executing a daily operation that involves copying sales data from the previous day into a table named transactions. The sales data for each day is stored in separate files located in the directory "/transactions/raw". To perform today’s data copying task, the data engineer runs a specific command. However, after executing the command, the data engineer observes that the number of records in the transactions table remains unchanged. 
 
![copy into](./images/copy_into.png)

Which of the following could explain why the command did not add any new records to the table

*Response*

The previous day’s file has already been copied into the table.

**Explanation:** The COPY INTO statement is generally used to copy data from files or a location into a table. If the data engineer runs this statement daily to copy the previous day's sales into the 'transactions' table and the number of records hasn't changed after today's execution, it is possible that the data from today's file might not have differed from the data already present in the table. The COPY INTO operation is idempotent, meaning that files already loaded will be skipped. Hence, if the previous day's file has already been copied into the table, no new records will be added.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data engineer has to create a table named new_employees_table in Databricks, utilizing data from their organization’s existing SQLite database. The following command is executed: 

```
CREATE TABLE new_employees_table 
USING _____ 
OPTIONS ( 
    url '<jdbc_url>',
    dbtable '<table_name>', 
    user '<username>', 
    password '<password>' 
    ) 
    AS SELECT * FROM employees_table_vw
```
Which line of code correctly fills in the blank to allow the successful creation of the table?

*Response*

Org.apache.spark.sql.jdbc

**Explanation:** To create a table in Databricks from an existing SQLite database, the appropriate connector for JDBC must be specified. The correct line to fill in the blank is 'org.apache.spark.sql.jdbc', which allows Databricks to read from JDBC-compliant databases. 

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data engineering team manages retail transaction data across different months. They have two specific tables: the first table, named march_transactions, contains all retail transactions recorded in the month of March, and the second table, named april_transactions, holds all retail transactions for the month of April. It is assured that there are no duplicate records between these two tables. To consolidate this data, which of the following commands should be executed to create a new table all_transactions that combines all records from both march_transactions and april_transactions, ensuring there are no duplicate records?

*Response*
```
CREATE TABLE all_transaction AS 
    SELECT * FROM march_transactions 
    UNION 
    SELECT * FROM April_transactions;
```

**Explanation:** The UNION operator combines the result sets of two or more queries, and it automatically removes duplicate records from the results. Given that the two tables, march_transactions and april_transactions, have no duplicate records within themselves, using UNION will create a new table all_transactions that includes all records from both months without any duplicates. 

Other options like INNER JOIN, OUTER JOIN, INTERSECT, and MERGE do not provide the necessary functionality to combine the two tables while removing duplicates.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data engineer has a Python variable table_name that they would like to use in a SQL query. They want to construct a Python code block that will run the query using table_name.
They have the following incomplete code block: 
```
____(f"SELECT customer_id, spend FROM {table_name}")
```

Which of the following can be used to fill in the blank to successfully complete the task?

*Response*

Spark.sql

-------------------------------------------------------------------------------------------------------------------------
## **Question**
A data engineer is working on a Python program and intends to execute a specific block of code only under certain conditions. The criteria for executing this block are that the variable day_of_week must be equal to 1, and another variable, review_period, must be set to True. Given this scenario, which of the following control flow statements should the data engineer use to initiate this conditional execution of the code block?

*Response*

`If day_of_week == 1 and review_period:`

**Explanation:** The correct control flow statement to begin the conditionally executed code block would be: if day_of_week == 1 and review_period:. This statement checks if the variable day_of_week is equal to 1 and if the variable review_period evaluates to a truthy value. 

The use of the double equal sign (==) in the comparison of day_of_week is crucial, as a single equal sign (=) would assign a value to the variable instead of checking its value.

-------------------------------------------------------------------------------------------------------------------------
## **Question**
In the context of managing a Spark SQL table named my_table, a data engineer wants to completely remove the table along with all its associated metadata and data. They use the command DROP TABLE IF EXISTS my_table. Although the table is no longer listed when they execute SHOW TABLES, they notice that the data files still persist. What is the reason that the data files remain in place while the metadata files were deleted?

*Response*

The table was external

**Explanation:** The reason why the data files still exist while the metadata files were deleted is because the table was external. When a table is external in Spark SQL (or in other database systems), it means that the table metadata (such as schema information and table structure) is managed externally, and Spark SQL assumes that the data is managed and maintained outside of the system. Therefore, when you execute a DROP TABLE statement for an external table, it removes only the table metadata from the catalog, leaving the data files intact. On the other hand, for managed tables, Spark SQL manages both the metadata and the data files. When you drop a managed table, it deletes both the metadata and the associated data files, resulting in a complete removal of the table.

-------------------------------------------------------------------------------------------------------------------------
## **Question**

*Response*

**Explanation:**

-------------------------------------------------------------------------------------------------------------------------
## **Question**

*Response*

**Explanation:**

-------------------------------------------------------------------------------------------------------------------------