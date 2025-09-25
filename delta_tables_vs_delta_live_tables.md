## Difference between Delta Tables and  Delta Live Tables.


### Delta Tables
Delta Tables are a storage format built on top of Parquet that adds powerful features like (Delta table = transaction layer + Parquet files):
- ACID transactions
- Time travel (query past versions)
- Schema enforcement and evolution
- Efficient upserts/merges (no need to rewrite entire files)
- Data skipping and Z-ordering

You can use Delta Tables in batch and streaming workloads with Spark, and they are the foundation of the Lakehouse architecture.

✅ Delta Tables are about how data is stored and managed (Data storage & management)
- Storage format based on Delta Lake.
- They are tables stored in your data lake (e.g., in S3, ADLS, GCS) using Parquet + a transaction log (_delta_log).

Use case:
- Reliable, versioned, transactional tables in your lakehouse.
- You query them directly (SQL, Spark, pandas API on Spark).

Think of Delta tables as the storage layer that makes your data lake behave like a data warehouse.


### Delta Live Tables
Delta Live Tables is a managed framework for building data (ETL) pipelines on top of Delta Tables. It provides:
- Declarative pipeline development using SQL or Python
- Automatically handles dependency resolution, job orchestration, retries, monitoring
- Automatic dependency tracking between tables
- Built-in data quality checks (EXPECT clauses for constraints and rules)
- Orchestration and monitoring
- Incremental processing for both batch and streaming
- Continuous or triggered mode for streaming + batch unification
- Versioning and lineage tracking
- Automatic creation of underlying Delta tables as pipeline outputs

DLT simplifies the creation and maintenance of ELT pipelines, and it automatically handles many operational concerns like retries, schema inference, and scaling.

✅ Delta Live Tables are about how data pipelines are built and executed (Pipeline orchestration & logic)

Use case:
- When you want to transform raw data → silver → gold in a production-ready, managed, and monitored way.
- DLT handles the complexity of scheduling, orchestration, data quality enforcement, and logging.

Think of Delta Live Tables as the pipeline service, and it produces/maintains Delta tables as outputs.


![key differences](./images/key_diff.png)


## Delta Table Example (Storage Layer)
You can create and query a Delta table directly in Databricks (SQL or PySpark).

**SQL**

```
-- Create a Delta table
CREATE TABLE sales_delta
USING DELTA
AS
SELECT * FROM parquet.`/mnt/raw/sales_data/`;

-- Query the table
SELECT product_id, SUM(amount) AS total_sales
FROM sales_delta
GROUP BY product_id;
```

**PySpark**

```
from pyspark.sql import SparkSession

spark = SparkSession.builder.getOrCreate()

# Read raw parquet
df = spark.read.parquet("/mnt/raw/sales_data/")

# Write as Delta table
df.write.format("delta").mode("overwrite").saveAsTable("sales_delta")

# Query
result = spark.sql("SELECT COUNT(*) FROM sales_delta")
result.show()
```


## Delta Live Tables example (Pipeline Framework)
With DLT, you don’t just create a table—you define a pipeline of transformations.

**SQL (DLT Pipeline)**

```
CREATE OR REFRESH LIVE TABLE bronze_sales
AS SELECT * FROM cloud_files("/mnt/raw/sales/", "json");

CREATE OR REFRESH LIVE TABLE silver_sales
AS SELECT product_id, CAST(amount AS DOUBLE) AS amount, date
FROM LIVE.bronze_sales;

CREATE OR REFRESH LIVE TABLE gold_sales_summary
AS SELECT product_id, SUM(amount) AS total_sales
FROM LIVE.silver_sales
GROUP BY product_id;
```
- **LIVE** keyword → managed by DLT.
- The dependencies are automatic: gold depends on silver, silver depends on bronze.
- If bronze updates, DLT will trigger downstream tables.

**PySpark**

Using the DLT library
```
import dlt
from pyspark.sql.functions import col

@dlt.table
def bronze_sales():
    return (
        spark.readStream
        .format("json")
        .load("/mnt/raw/sales/")
    )

@dlt.table
@dlt.expect("valid_amount", "amount > 0")  # data quality check
def silver_sales():
    return (
        dlt.read("bronze_sales")
        .withColumn("amount", col("amount").cast("double"))
    )

@dlt.table
def gold_sales_summary():
    return (
        dlt.read("silver_sales")
        .groupBy("product_id")
        .sum("amount")
    )
```
Without the DLT library
```
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum as _sum

# Create a Spark session
spark = SparkSession.builder.appName("DeltaLiveTablesExample").getOrCreate()

# Define a Delta Live Table for streaming ingestion
bronze_sales = (
    spark.readStream.format("cloudFiles")
    .option("cloudFiles.format", "json")
    .load("/mnt/raw/sales/")
)

# Define a Delta Live Table for data transformation and quality checks
silver_sales = (
    bronze_sales
    .filter(col("amount") > 0)
    .select(
        col("product_id"),
        col("amount").cast("double").alias("amount"),
        col("date").cast("date").alias("date")
    )
)

# Define a Delta Live Table for batch aggregation
gold_sales_summary = (
    silver_sales
    .groupBy("product_id")
    .agg(_sum("amount").alias("total_sales"))
)

# Start the streaming query for bronze_sales
query = (
    bronze_sales
    .writeStream
    .format("delta")
    .outputMode("append")
    .option("checkpointLocation", "/mnt/checkpoint/bronze_sales")
    .start("/mnt/delta/bronze_sales")
)

# Wait for the streaming query to finish
query.awaitTermination()
```
Other example:
```
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("DeltaPipeline").getOrCreate()

# Define the schema for the streaming data
schema = "product_id STRING, amount DOUBLE, date DATE"

# Read streaming data from a JSON source
bronze_sales = (
    spark.readStream.format("json")
    .schema(schema)
    .load("/mnt/raw/sales/")
)

# Write the streaming data to a Delta table
bronze_sales.writeStream
    .format("delta")
    .outputMode("append")
    .option("checkpointLocation", "/mnt/checkpoint/bronze_sales")
    .start("/mnt/delta/bronze_sales")

# Read data from the Bronze Delta table
bronze_sales = spark.read
    .format("delta")
    .load("/mnt/delta/bronze_sales")

# Clean and transform the data
silver_sales = bronze_sales
    .withColumn("amount", col("amount").cast("double"))
    .withColumn("date", col("date").cast("date"))

# Write the transformed data to a Delta table
silver_sales.write
    .format("delta")
    .mode("overwrite")
    .save("/mnt/delta/silver_sales")

# Read data from the Silver Delta table
silver_sales = spark.read
    .format("delta")
    .load("/mnt/delta/silver_sales")

# Perform batch aggregation
gold_sales_summary = silver_sales
    .groupBy("product_id")
    .sum("amount")
    .withColumnRenamed("sum(amount)", "total_sales")

# Write the aggregated data to a Delta table
gold_sales_summary.write
    .format("delta")
    .mode("overwrite")
    .save("/mnt/delta/gold_sales_summary")
```


- DLT manages orchestration between bronze → silver → gold.
- It enforces data quality rules (expect) and drops/bad-record handling automatically.
- The underlying tables are stored as Delta tables.


So the difference in code:
- Delta Tables → you write/read them like any database table.
- Delta Live Tables → you declare a pipeline of transformations, and Databricks manages the orchestration, quality, and produces Delta tables as the output.


## The bronze table of DLT
The bronze table can be created from either batch or streaming data, depending on how you set it up in the DLT pipeline.

**Stream**

```
@dlt.table
def bronze_sales():
    return spark.readStream.format("json").load("/mnt/raw/sales/")
```
Because we used readStream, the bronze layer ingests streaming data (e.g., new JSON files landing continuously in /mnt/raw/sales/). That means every time new files arrive, DLT will pick them up and update downstream silver/gold tables.

**Batch**

```
@dlt.table
def bronze_sales():
    return spark.read.format("json").load("/mnt/raw/sales/")
```
Now, bronze ingests a static batch snapshot of all files in /mnt/raw/sales/. You could trigger the pipeline on a schedule (e.g., once per day) to refresh it.

Streaming mode vs batch mode
- Batch mode → good for daily/weekly refresh, historical datasets, or when latency doesn’t matter.
- Streaming mode → good when you need near real-time updates (new files, Kafka messages, etc.).


## Stream vs batch
when you create streaming tables in DLT (like your bronze and silver), they are still Delta tables under the hood, so they live in the catalog just like batch Delta tables.

By default, DLT creates them in the hive_metastore unless you specify a different catalog/schema.

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

**PySpark**

```
import dlt
from pyspark.sql.functions import col, sum as _sum

# --------------------------
# Bronze: Streaming ingestion
# --------------------------
@dlt.table
def bronze_sales():
    """
    Ingest raw JSON sales data continuously
    """
    return (
        spark.readStream.format("json")
        .load("/mnt/raw/sales/")
    )

# --------------------------
# Silver: Streaming clean & quality
# --------------------------
@dlt.table
@dlt.expect("valid_amount", "amount > 0")  # Data quality rule
def silver_sales():
    """
    Clean data: cast types, enforce quality rules
    """
    return (
        dlt.read_stream("bronze_sales")  # streaming read from bronze
        .withColumn("amount", col("amount").cast("double"))
        .withColumn("date", col("date").cast("date"))
    )

# --------------------------
# Gold: Batch aggregation
# --------------------------
@dlt.table(
    comment="Daily sales summary",
    table_properties={"pipelines.autoOptimize.managed": "true"}
)
def gold_sales_summary():
    """
    Aggregate silver data in batch mode.
    You can run this on schedule or manually.
    """
    return (
        dlt.read("silver_sales")  # batch read from silver
        .groupBy("product_id")
        .agg(_sum("amount").alias("total_sales"))
    )
```

**SQL**

```
-- --------------------------
-- Bronze: Streaming ingestion
-- --------------------------
CREATE OR REFRESH LIVE TABLE bronze_sales
COMMENT "Streaming raw JSON sales data"
AS
SELECT *
FROM cloud_files("/mnt/raw/sales/", "json");  -- streaming source

-- --------------------------
-- Silver: Streaming clean & quality
-- --------------------------
CREATE OR REFRESH LIVE TABLE silver_sales
COMMENT "Cleaned sales data with quality checks"
AS
SELECT *
FROM LIVE.bronze_sales
WHERE amount > 0  -- Data quality check
-- Cast types
SELECT product_id,
       CAST(amount AS DOUBLE) AS amount,
       CAST(date AS DATE) AS date
FROM LIVE.bronze_sales
WHERE amount > 0;

-- --------------------------
-- Gold: Batch aggregation
-- --------------------------
CREATE OR REFRESH LIVE TABLE gold_sales_summary
COMMENT "Daily sales summary (batch)"
AS
SELECT product_id,
       SUM(amount) AS total_sales
FROM LIVE.silver_sales  -- batch read from silver
GROUP BY product_id;
```

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

