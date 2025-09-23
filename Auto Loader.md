# Auto Loader

Auto Loader is a Databricks feature for incrementally and efficiently ingesting new data files from cloud storage (like AWS S3, Azure Data Lake Storage, or GCS) into Delta tables. It automatically detects new files as they arrive and processes them without needing manual tracking or batch reprocessing. 

Auto Loader is defined by **cloudFiles**.

Using it:

```
df = (spark.readStream
      .format("cloudFiles")
      .option("cloudFiles.format", "json")   # or csv, parquet, etc.
      .load("/mnt/raw/data"))

```
Then you write it out (typically into a Delta table):
```
(df.writeStream
   .format("delta")
   .option("checkpointLocation", "/mnt/checkpoints/data")
   .table("bronze_table"))

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
      .option("cloudFiles.schemaEvolutionMode", "addNewColumns")
      .load("/mnt/raw/"))
```
```
CREATE OR REFRESH STREAMING TABLE bronze
AS SELECT *
FROM cloud_files(
  '/mnt/raw/',
  'json',
  map('cloudFiles.schemaEvolutionMode', 'addNewColumns')
);
```

**Unexpected / Extra Fields (rescue them instead of losing)**

Any extra/unexpected fields go into the _rescued_data column (JSON string) instead of breaking the pipeline.
```
df = (spark.readStream
      .format("cloudFiles")
      .option("cloudFiles.format", "csv")
      .option("rescuedDataColumn", "_rescued_data")
      .load("/mnt/raw/"))

```
```
CREATE OR REFRESH STREAMING TABLE bronze
AS SELECT *
FROM cloud_files(
  '/mnt/raw/',
  'csv',
  map('rescuedDataColumn', '_rescued_data')
);
```

**Bad / Corrupted Records**

Corrupt rows are quarantined into /mnt/errors/ instead of failing the entire job.
```
df = (spark.readStream
      .format("cloudFiles")
      .option("cloudFiles.format", "json")
      .option("badRecordsPath", "/mnt/errors/")
      .load("/mnt/raw/"))
```
```
CREATE OR REFRESH STREAMING TABLE bronze
AS SELECT *
FROM cloud_files(
  '/mnt/raw/',
  'json',
  map('badRecordsPath', '/mnt/errors/')
);
```

**Enforcing Schema (strict mode)**

```
df = (spark.readStream
      .format("cloudFiles")
      .schema(userDefinedSchema)  # enforce schema
      .option("cloudFiles.schemaLocation", "/mnt/schema/")
      .load("/mnt/raw/"))
```
```
CREATE OR REFRESH STREAMING TABLE bronze
AS SELECT *
FROM cloud_files(
  '/mnt/raw/',
  'json',
  map('cloudFiles.schemaLocation', '/mnt/schema/')
);
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
```
CREATE OR REFRESH STREAMING TABLE bronze
AS SELECT *
FROM cloud_files(
  '/mnt/raw/',
  'parquet'
);

```
In the SQL query, cloud_files(path, format, options...)
- This is the SQL function wrapper around spark.readStream.format("cloudFiles").
- First arg = storage location.
- Second arg = file format (parquet, csv, json, etc.).
- You can pass extra options (like schema evolution, rescued data column).
- The checkpointing is handled automatically by the streaming table definition (you don’t have to specify it explicitly like in PySpark).


**Batch ingestion**
Auto Loader also has a trigger for batch (.trigger(once=True) or .trigger(availableNow=True)). This makes it run like a batch job: process all new files once, then stop.
```
(df.writeStream
   .format("delta")
   .option("checkpointLocation", "/mnt/chk")
   .trigger(availableNow=True)  # batch-like mode
   .table("bronze_batch"))
```

```
CREATE OR REFRESH STREAMING TABLE bronze_batch
AS COPY INTO bronze_batch
FROM cloud_files(
  '/mnt/raw/',
  'parquet'
);

```
In SQL the batch-like mode (trigger(availableNow=True)) is expressed using COPY INTO inside a streaming table definition.

**Pure One-Time Batch Ingestion**
```
df = (spark.read
      .format("parquet")
      .load("/mnt/raw/"))

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

If you want to ingest from databases, APIs, or Kafka, you need different connectors:
- Databases: JDBC connector in Spark. Works for batch ingestion (not continuous streaming).

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