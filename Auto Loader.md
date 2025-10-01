# Auto Loader

Auto Loader is a Databricks feature for incrementally and efficiently ingesting new data files from cloud storage (like AWS S3, Azure Data Lake Storage, or GCS) into Delta tables. It automatically detects new files as they arrive and processes them without needing manual tracking or batch reprocessing. 

Auto Loader is defined by **cloudFiles**.

Using it:

```
from pyspark.sql.types import StructType, StructField, StringType, IntegerType

# set up data structure
schema = StructType([
   StructField("Id", IntegerType(), True),
   StructField("name", StringType(), True),
   StructField("age", IntegerType(), True),
   StructField("money", IntegerType(), True),
   StructField("sales", IntegerType(), True),
   StructField("units", IntegerType(), True),
])

df = (spark.readStream
      .format("cloudFiles")
      .option("cloudFiles.format", "csv")   # or csv, parquet, etc.
      .option("header", "true")
      .schema(schema)  # Schema Enforcement
      .load("/mnt/raw/data"))

```
Then you write it out (typically into a Delta table):
```
(df.writeStream
   .format("delta")
   .option("checkpointLocation", "/mnt/checkpoints/data")
   .outputMode("append")
   .table("bronze_table"))

# Continuous running streaming Job

# the streaming query is managed through a StreamingQuery object, not the DataFrame.
# To stop the stream 
for q in spark.streams.active:
    q.stop()
```

## Benefits

Efficient incremental ingestion:
- Processes only new or changed files (uses a file notification service or a listing mode with checkpointing).
- Avoids rescanning entire directories every time.

Scalability:
- Can handle billions of files with scalable metadata management.

Schema Evolution & Inference:
- Auto-detects schema and can evolve when new fields arrive (.option("cloudFiles.schemaEvolutionMode", "addNewColumns")).
- This is super useful for semi-structured data (JSON, CSV).

Data consistency & reliability:
- Uses checkpoints and transaction logs to ensure: No file is processed twice (idempotency). No file is missed.
- Works seamlessly with Delta Lake’s ACID guarantees.

## Handling Data Inconsistencies

Schema drift / evolution:
- New columns appear in source → Auto Loader can add them without failing (addNewColumns).
- Example: yesterday’s JSON has {id, name}, today’s has {id, name, age} → it handles it.

Corrupted / malformed records:
- Option: .option("badRecordsPath", "/mnt/errors/") → sends bad rows to quarantine for inspection.
- You don’t lose the whole job just because of one bad record.

Late arriving files / out-of-order data:
- With incremental load + Delta Lake merges, you can handle late-arriving data without full reprocessing.

Duplicate ingestion prevention:
- Checkpointing ensures that even if the job restarts, already-processed files won’t be reloaded.

Schema validation:
- You can enforce a schema and reject anything that doesn’t match (rescuedDataColumn captures unexpected fields).
- This helps detect upstream issues early without breaking your pipeline.

## Options of Auto Loader

**Schema Drift (new columns appear in source data)**

If a new column shows up in the JSON, Auto Loader adds it automatically instead of failing.

```
df = (spark.readStream
      .format("cloudFiles")
      .option("cloudFiles.format", "json")
      .option("multiLine", "true")  # to read the json without problems
      .option("cloudFiles.schemaLocation", "/mnt/autoloader/_schemas_json")  # needed
      .option("cloudFiles.schemaEvolutionMode", "addNewColumns")  # needed
      .load("/mnt/raw/"))
```
*With SQL, Auto Loader appears only in Lakeflow Declarative pipelines*
[auto loader examples](https://docs.databricks.com/aws/en/ingestion/cloud-object-storage/auto-loader/patterns?language=Python)
```
CREATE OR REFRESH STREAMING TABLE autoloder_sql
AS SELECT *
FROM STREAM read_files(
  '/mnt/raw/',
  format => 'json',
  multiline => 'true'
);
```

**Unexpected / Extra Fields (rescue them instead of losing)**

Any extra/unexpected fields go into the _rescued_data column (JSON string) instead of breaking the pipeline.
```
df = (spark.readStream
      .format("cloudFiles")
      .option("cloudFiles.format", "csv")
      .option("rescuedDataColumn", "_rescued_data")  ##
      .load("/mnt/raw/"))

```

**Bad / Corrupted Records**

Corrupt rows are quarantined into /mnt/errors/ instead of failing the entire job.
```
df = (spark.readStream
      .format("cloudFiles")
      .option("cloudFiles.format", "json")
      .option("badRecordsPath", "/mnt/errors/")  ##
      .load("/mnt/raw/"))
```

**Enforcing Schema (strict mode)**
```
df = (spark.readStream
      .format("cloudFiles")
      .schema(Schema)  # enforce schema
      .option("cloudFiles.schemaLocation", "/mnt/schema/")
      .load("/mnt/raw/"))
```


## stream vs batch tables

Auto Loader itself is a streaming source (spark.readStream.format("cloudFiles")).

**Streaming ingestion**
This is how you usually populate streaming (incremental) tables like Bronze.
```
df = (spark.readStream
      .format("cloudFiles")
      .option("cloudFiles.format", "parquet")
      .load("/mnt/raw/"))

(df.writeStream
   .format("delta")
   .option("checkpointLocation", "/mnt/chk")
   .table("bronze"))

```


**Batch ingestion**
Auto Loader also has a trigger for batch (.trigger(once=True) or .trigger(availableNow=True)). This makes it run like a batch job: process all new files once, then stop.
```
(df.writeStream
   .format("delta")
   .option("checkpointLocation", "/mnt/chk")
   .trigger(availableNow=True)  ## batch-like mode
   .table("bronze_batch"))
```

**Pure One-Time Batch Ingestion**
```
df = (spark.read
      .format("json")
      .option("multiLine", True)
      .load("/mnt/raw/"))

display(df_json)

df.write.format("delta").mode("append").saveAsTable("bronze_batch_once")
```

```
COPY INTO bronze_batch_once
FROM '/mnt/raw/'
FILEFORMAT = PARQUET;

```
One-time batch → plain COPY INTO (or spark.read.format)


## Checkpoint

Checkpoints are a core part of Auto Loader. A checkpoint is a folder in cloud storage where Spark/Databricks saves streaming state metadata.
It ensures the job can restart safely without losing track of what it already processed.

For Auto Loader (and any streaming job), the checkpoint directory keeps:
- Source progress: Which files have already been processed. Prevents duplicates if the job restarts.
- Offsets: Position in the data stream (like Kafka offsets, but here it’s file names).
- Schema info (if schema inference is used): Auto Loader can write schema snapshots to the checkpoint (or you can externalize via cloudFiles.schemaLocation).
- Watermark state (if using late data handling): To drop old data once you’ve processed up to a certain event-time.

In PySpark: `df.writeStream.format("delta").option("checkpointLocation", "/mnt/chk/bronze").table("bronze")` /mnt/chk/bronze is the checkpoint folder.
In SQL: You don’t need to specify checkpointLocation — SQL streaming tables handle it for you.

Why checkpoints matter (especially with data inconsistencies)
- Idempotency → prevents reprocessing the same file twice.
- Fault tolerance → pipeline resumes from last good state.
- Schema evolution tracking → keeps track of historical schema snapshots.
- Consistency → ensures Delta table writes are atomic (no partial file loads).


## DataStreamWriter.trigger
DataStreamWriter.trigger(*, processingTime=None, once=None, continuous=None, availableNow=None)

Set the trigger for the stream query. If this is not set it will run the query as fast as possible, which is equivalent to setting the trigger to processingTime='0 seconds'.
- processingTime: a processing time interval as a string, e.g. ‘1 minute’. Set a trigger that runs a microbatch query periodically based on the processing time, e.g. every minute.
- once: if set to True, set a trigger that processes only one batch of data in a streaming query then terminates the query. 
- continuous: a time interval as a string, e.g. ‘5 seconds’, ‘1 minute’. Set a trigger that runs a continuous query with a given checkpoint interval.
- availableNow: if set to True, set a trigger that processes all available data in multiple batches then terminates the query.


## Summary Auto Loader:
Auto Loader is designed for production-grade ingestion of streaming/batch files. Its key advantage while handling data inconsistencies is:
- Capturing bad records instead of failing,
- Managing schema drift,
- Avoiding duplicates or missed files,
- Enforcing consistent, incremental data ingestion with Delta’s reliability.

Scope of Auto Loader:
- Auto Loader is only for ingesting data files from cloud object storage (S3, ADLS, GCS).
- It’s not for Kafka, Kinesis, or JDBC sources → those you handle with other Spark connectors.

- ✅ Auto Loader = just for data files in cloud storage.
- ✅ It feeds into streaming tables (continuous ingestion) or batch tables (one-off loads).
- ❌ It does not read from databases, APIs, Kafka, etc.

- Normal Spark readers (spark.read.format("parquet")) just scan files — they don’t remember what they processed.
- Auto Loader (cloudFiles) keeps state (via checkpoints), detects new files, and ensures consistency (no duplicates, no missed files).
- That’s why it’s the backbone for ingestion into streaming or batch tables.

Whenever you see "cloudFiles" (PySpark) or cloud_files() (SQL) → that’s Auto Loader in action.

## DB, API
If you want to ingest from databases, APIs, or Kafka, you need different connectors:
- Databases: JDBC connector in Spark. Works for batch ingestion (not continuous streaming).
[configure DB connector](https://spark.apache.org/docs/latest/sql-data-sources-jdbc.html#data-source-option)
```
jdbcDF = (spark.read
    .format("jdbc")
    .option("url", "jdbc:postgresql://host:5432/db")
    .option("dbtable", "public.sales")
    .option("user", "username")
    .option("password", "password")
    .load())
```
```
SELECT *
FROM jdbc(
  'jdbc:postgresql://host:5432/db',
  'public.sales',
  'user' 'username',
  'password' 'password'
);
```
- APIs (REST / Web services): Spark does not have a direct REST API connector. Use requests library in Python to pull data, then parallelize into a DataFrame; Use a connector like Autoloader → ingest raw JSON dumps from API to storage; Use external ETL tools (e.g., Fivetran, Airbyte, StreamSets) to push API data into cloud storage or databases, then read with Spark.
- Kafka (true streaming): Use the Kafka Structured Streaming connector (format("kafka")).

## Example of Auto Loader with PySpark

```
# Set Up Auto Loader Configuration
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("AutoLoaderExample").getOrCreate()

# Define the path where new data files will arrive
path = "/mnt/raw_data/"

# Define the Auto Loader options
autoLoaderOptions = {
  "cloudFiles.format": "json",
  "cloudFiles.maxFilesPerTrigger": 1
}

# Create a streaming DataFrame using Auto Loader
streamingDF = (
    spark.readStream
    .format("cloudFiles")
    .options(**autoLoaderOptions)
    .load(path)
)

# Example processing logic
processedDF = streamingDF.select("column1", "column2")

# Start the Streaming Query
query = (
     processedDF.writeStream
    .format("delta")
    .outputMode("append")
    .option("checkpointLocation", "/mnt/checkpoint/")
    .start("/mnt/delta_output/")
)

query.awaitTermination()

```

