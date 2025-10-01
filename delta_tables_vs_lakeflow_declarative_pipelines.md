## Difference between Delta Tables and Lakeflow Declarative Pipelines in Databricks.


### Delta Tables
Delta Tables are a storage format built on top of Parquet that adds powerful features like (Delta table = transaction layer + Parquet files). Delta Tables are indeed a storage format built on top of Parquet files, enhanced with a transaction log (the "transaction layer") that provides several advanced features:
- ACID transactions: Delta Lake ensures that all operations on Delta tables are atomic, consistent, isolated, and durable, making data management reliable even in concurrent environments.
- Time travel (query past versions): ou can query previous versions of your data, enabling rollback and historical analysis.
- Schema enforcement and evolution: Delta Lake enforces schemas and allows for schema changes over time, making it easier to manage evolving data structures.
- Efficient upserts/merges (no need to rewrite entire files): Delta Lake supports efficient upserts and merges, so you don't need to rewrite entire files when updating data
- Data skipping and Z-ordering: These features optimize query performance by skipping irrelevant data and clustering related information together for faster access

You can use Delta Tables in batch and streaming workloads with Spark, and they are the foundation of the Lakehouse architecture. Delta Tables are designed to support both batch and streaming workloads seamlessly with Apache Spark. They serve as the foundational storage layer for the Lakehouse architecture, enabling unified analytics and data management. Delta Lake’s deep integration with Spark Structured Streaming allows you to efficiently read and write streaming data, maintain exactly-once processing, and handle both incremental and real-time data pipelines. This makes Delta Tables ideal for building robust, scalable, and reliable data lakes that support a wide range of analytics use cases


Delta Tables are about how data is stored and managed (Data storage & management). Delta Tables define how data is stored and managed in a data lake environment:
- Storage format based on Delta Lake. Delta Tables use the Delta Lake open-source storage layer, which extends Parquet files with a transaction log for ACID transactions and scalable metadata handling
- They are tables stored in your data lake (e.g., in S3, ADLS, GCS) using Parquet + a transaction log (_delta_log). Delta Tables are stored as directories of files in your cloud object storage (such as S3, ADLS, or GCS). The data itself is in Parquet format, and each table directory contains a special subdirectory called _delta_log that holds the transaction log files
- Transaction log (_delta_log): This log tracks all changes to the table, enabling features like ACID transactions, time travel, and efficient schema evolution

Use case:
- Reliable, versioned, transactional tables in your lakehouse.
- You query them directly (SQL, Spark, pandas API on Spark).  You can query Delta Tables directly using SQL, Apache Spark, or the pandas API on Spark, making them accessible for a wide range of analytics and data science workloads

Think of Delta tables as the storage layer that makes your data lake behave like a data warehouse.


### Lakeflow Declarative Pipelines in Databricks.
The product provides a managed, declarative framework for building robust ETL pipelines on top of Delta Tables. It provides:
- Declarative pipeline development: You can define pipelines using SQL or Python, specifying what you want to compute, not how, which simplifies ETL development
- Automatic dependency resolution and orchestration: The framework automatically tracks dependencies between tables and manages the execution order, job orchestration, retries, and monitoring for you
- Data quality checks: You can define data quality constraints using EXPECT clauses (in SQL) or decorators like @dp.expect in Python, ensuring data integrity at every stage of the pipeline. Built-in data quality checks (EXPECT clauses for constraints and rules)
- Incremental processing: Supports both batch and streaming data, enabling incremental updates and efficient processing for both modes.
- Continuous or triggered mode: Pipelines can run continuously (for streaming) or on a schedule (for batch), unifying both paradigms in a single framework.
- Versioning and lineage tracking: The system tracks versions and lineage of tables, making it easy to audit and understand data flows.
- Automatic creation of Delta tables: All pipeline outputs are stored as Delta tables, leveraging the reliability and performance of the Delta Lake storage layer.


Lakeflow Declarative Pipelines (formerly DLT) is the recommended way to build production-grade, maintainable, and observable ETL pipelines on Databricks, with strong support for both batch and streaming workloads. It simplifies the creation and maintenance of ELT pipelines, and it automatically handles many operational concerns like retries, schema inference, and scaling. It's all about how data pipelines are built and executed (Pipeline orchestration & logic)

Lakeflow Declarative Pipelines (formerly Delta Live Tables or DLT) are focused on how data pipelines are built, orchestrated, and executed—not just how data is stored. They provide a managed, declarative framework for defining ELT/ETL pipelines, and they handle many operational aspects automatically, including:
- Pipeline orchestration & logic: You define the logic and dependencies between tables and transformations, and Lakeflow Declarative Pipelines orchestrate the execution for you.
- Automatic retries and error handling: The system manages retries and error recovery, reducing manual intervention.
- Schema inference and evolution: Pipelines can automatically infer schema from data and adapt to schema changes, minimizing manual schema management.
- Autoscaling and resource management: Especially with serverless compute, scaling is handled automatically to meet workload demands.
- Data quality enforcement: Built-in support for data quality checks (expectations) ensures that only valid data flows through your pipeline.
- Incremental and streaming processing: Supports both batch and streaming data, enabling unified, incremental data processing.
- Monitoring and lineage: Provides built-in monitoring, event logs, and lineage tracking for operational transparency.

Use case:
- When you want to transform raw data → silver → gold in a production-ready, managed, and monitored way.
- Pipelines handles the complexity of scheduling, orchestration, data quality enforcement, and logging.

Think of it as the pipeline service, and it produces/maintains Delta tables as outputs.



## Delta Table Example (Storage Layer)
You can create and query a Delta table directly in Databricks (SQL or PySpark).

**SQL**

```
-- Create a Delta table
CREATE OR REPLACE TABLE sales_delta
USING DELTA
AS
SELECT * FROM read_files(
    `/mnt/raw/sales_data/`,
    format => 'csv',
    header => 'true'
);

-- Query the table
SELECT product_id, SUM(amount) AS total_sales
FROM sales_delta
GROUP BY product_id;
```

**PySpark**

```

# Read raw parquet
df = spark.read.parquet("/mnt/raw/sales_data/")

# Write as Delta table
df.write.format("delta").mode("overwrite").saveAsTable("sales_delta")

# Query
result = spark.sql("SELECT COUNT(*) FROM sales_delta")
result.show()
```


## Lakeflow Declarative Pipelines (Pipeline Framework)
You don’t just create a table, you define a pipeline of transformations.

**SQL Pipeline**

```
CREATE OR REFRESH STREAMING TABLE bronze_sales
AS
SELECT 
*,
current_timestamp() AS processing_time,
_metadata.file_name AS file
 FROM STREAM read_files(
  '/Volumes/sales/json/',
  format => 'json',
  multiline => 'true'
);

CREATE OR REFRESH MATERIALIZED VIEW silver_sales
AS SELECT Id, CAST(money AS DOUBLE) AS money, processing_time, file
FROM bronze_sales;

CREATE OR REFRESH MATERIALIZED VIEW gold_sales_summary
AS SELECT Id, SUM(money) AS total_sales
FROM silver_sales
GROUP BY Id;
```

- The dependencies are automatic: gold depends on silver, silver depends on bronze.
- If bronze updates, the pipeline will trigger downstream tables.

**PySpark**

Using the DP library (dlt is depreciated)
```
from pyspark import pipelines as dp
from pyspark.sql.functions import col
from pyspark.sql.functions import sum as _sum
from pyspark.sql.types import StructType, StructField, StringType, IntegerType

schema = StructType([
   StructField("Id", IntegerType(), True),
   StructField("name", StringType(), True),
   StructField("age", IntegerType(), True),
   StructField("money", IntegerType(), True),
   StructField("sales", IntegerType(), True),
   StructField("units", IntegerType(), True),
])

@dp.table
def bronze_sales():
    return (
        spark.readStream
        .format("json")
        .option("multiLine", True)
        .schema(schema)
        .load("/Volumes/delta_tables/json/")
    )

@dp.table
@dp.expect("valid_amount", "money > 0")  # data quality check
def silver_sales():
    return (
        dp.read("bronze_sales")
        .withColumn("money", col("money").cast("double"))
    )

@dp.table
def gold_sales_summary():
    return (
        dp.read("silver_sales")
        .groupBy("Id")
        .agg(
            _sum("money").alias("total_money")
        )
    )
```

Without the DP library: example of a streaming pipeline using only PySpark DataFrame and Structured Streaming APIs
```
from pyspark.sql.functions import col, sum as _sum
from pyspark.sql.types import StructType, StructField, StringType, IntegerType

schema = StructType([
   StructField("Id", IntegerType(), True),
   StructField("name", StringType(), True),
   StructField("age", IntegerType(), True),
   StructField("money", IntegerType(), True),
   StructField("sales", IntegerType(), True),
   StructField("units", IntegerType(), True),
])

# Ingest streaming data from JSON files
bronze_sales_spark = (
        spark.readStream
        .format("cloudFiles")
        .option("cloudFiles.format", "json")
        .option("multiLine", True)
        .schema(schema)
        .load("/Volumes/delta_tables/json/")
        .na.drop()
    )

# Data transformation and quality checks
silver_sales_spark = (
        bronze_sales_spark
        .filter(col("money") > 0)
        .select(
            col("Id"),
            col("money").cast("double")
        )
    )

# Define a dataframe for batch aggregation
gold_sales_summary_spark = (
        silver_sales_spark
        .groupBy("Id")
        .agg(
            _sum("money").alias("total_money")
        )
    )

# Start the streaming query for bronze layer to Delta
bronze_query = (
    bronze_sales_spark
    .writeStream
    .format("delta")
    .outputMode("append")
    .option("checkpointLocation", "/Volumes/checkpoints_bronze_spark")
    .toTable("bronze_sales_spar2")
)

# Start the streaming query for silver layer to Delta
silver_query = (
    silver_sales_spark
    .writeStream
    .format("delta")
    .outputMode("append")
    .option("checkpointLocation", "/Volumes/checkpoints_silver_spark")
    .toTable("silver_sales_spar2")
)

# Start the streaming query for golden layer to Delta
gold_query = (
    gold_sales_summary_spark
    .writeStream
    .format("delta")
    .outputMode("append")
    .option("checkpointLocation", "/Volumes/checkpoints_golden_spark")
    .toTable("gold_sales_summary_spark2")
)

# Wait for all streaming queries to finish
bronze_query.stop()
silver_query.stop()
gold_query.stop()
```


- DP manages orchestration between bronze → silver → gold.
- It enforces data quality rules (expect) and drops/bad-record handling automatically.
- The underlying tables are stored as Delta tables.


So the difference in code:
- Delta Tables → you write/read them like any database table.
- Lakeflow Declarative Pipelines → you declare a pipeline of transformations, and Databricks manages the orchestration, quality, and produces Delta tables as the output.


## The bronze table 
The bronze table can be created from either batch or streaming data, depending on how you set it up in the pipeline.

**Stream**

```
@dp.table
def bronze_sales():
    return spark.readStream.format("json").load("/mnt/raw/sales/")
```
Because we used readStream, the bronze layer ingests streaming data (e.g., new JSON files landing continuously in /mnt/raw/sales/). That means every time new files arrive, the pipeline will pick them up and update downstream silver/gold tables.

**Batch**

```
@dp.table
def bronze_sales():
    return spark.read.format("json").load("/mnt/raw/sales/")
```
Now, bronze ingests a static batch snapshot of all files in /mnt/raw/sales/. You could trigger the pipeline on a schedule (e.g., once per day) to refresh it.

Streaming mode vs batch mode
- Batch mode → good for daily/weekly refresh, historical datasets, or when latency doesn’t matter.
- Streaming mode → good when you need near real-time updates (new files, Kafka messages, etc.).


## Stream vs batch
when you create streaming tables in the pipeline (like your bronze and silver), they are still Delta tables under the hood, so they live in the catalog just like other Delta tables.

By default, the pipeline creates them in the hive_metastore unless you specify a different catalog/schema.

You can query them with SQL or PySpark: `SELECT * FROM bronze_sales;`

The streaming nature is only about how they are updated (via Structured Streaming in the pipeline). Once materialized, they look and behave like any other Delta table in the catalog.
You can use them in:
- Databricks SQL queries
- BI tools (Power BI, Tableau, etc.)
- Other notebooks

*Bronze Layer*
Streaming ingestion (readStream): 
- New files/events arrive continuously (e.g., IoT sensors, Kafka, event hubs, logs landing in cloud storage).
- Bronze is usually a raw append-only Delta table capturing the data as-is, in near real-time.

Batch ingestion (read)
- Data arrives periodically (e.g., daily sales extracts, monthly reports, static CSV dumps).
- Bronze just loads the batch into the Delta table.

*Silver Layer*
This is your cleaned & conformed data:
- If bronze is streaming, silver can also be streaming to keep low-latency.
- If bronze is batch, silver often stays batch (daily refresh).
- Sometimes you do hybrid: bronze is streaming but silver runs in triggered batch mode (e.g., update every hour).

*Gold Layer*
This is aggregated, business-ready data:
- Often batch because business users don’t need second-by-second updates (e.g., daily sales summary).
- But in real-time analytics use cases (fraud detection, IoT dashboards, stock trading) → gold might also be streaming.

Rule of Thumb:
- Use streaming when: you need fresh/real-time data and the source supports incremental arrival (files, Kafka, IoT).
- Use batch when: data comes in bulk, latency isn’t critical, or historical backfills are needed.
- Mix when: bronze is streaming for raw capture, but silver/gold are batch for easier aggregation and cost control.


## Batch mode in DLT
DLT settings: pipeline mode triggered (batch) or continuoius (stream) -> chosse the pipeline mode based on the latency and cost requirements.

- Triggered pipelines update once and then shut down the cluster until the next manual or scheduled update.
- Continuous pipelines keep an always running cluster that ingests new data as it arrives.

In batch mode, each run processes only new data since the last successful run → that’s the auto-incremental behavior (only processes new data). When you define a batch pipeline, DLT automatically processes only the delta (incremental changes).

This is similar to how structured streaming does incremental processing.

How to schedule batches (e.g., every 30 minutes): You don’t set this inside the SQL/Python code itself. The schedule is defined in the DLT pipeline settings in the Databricks UI


Example: Gold every 30 minutes
- Bronze (streaming)
- Silver (streaming)
- Gold (batch aggregation every 30 min)

You’d configure the pipeline schedule:
- Bronze & Silver → continuously updated because they are streaming tables.
- Gold → defined as a normal LIVE table (batch mode). DLT will refresh it on each scheduled run (every 30 minutes).

So, the gold table will always be snapshotted & re-aggregated every half hour.

