## Volume

In Databricks, a volume is essentially an abstraction over cloud storage, but with some additional management features.

A volume is a managed storage location that your Databricks workspace can read from and write to. Volumes are backed by cloud storage: for example, AWS S3, Azure Data Lake Storage (ADLS), or Google Cloud Storage (GCS) depending on your cloud provider. You can think of a volume as a persistent file system that your notebooks and jobs can access across clusters. A Databricks volume is just a storage location, so you can store any file format you want, including: CSV (.csv), JSON (.json), Parquet (.parquet),  Delta Lake (.delta), Avro, ORC, or even plain text files. So the format of the data is independent of the volume itself—the volume just holds the files.

Databricks managed DBFS paths (/dbfs/...) include both temporary and persistent storage. A volume is persistent and can be shared across clusters or attached to a Unity Catalog table. It allows fine-grained access control with Unity Catalog.

Direct cloud storage (like an S3 bucket) can be accessed via APIs, but: You must manage credentials and access yourself, you might have inconsistent paths and naming across clusters.

Databricks volumes provide: A simpler mount point (/Volumes/...), persistent access without mounting manually every time, integration with Databricks permissions and Unity Catalog

### Files of the volume
You can use them in Spark or SQL directly from the volume, for example:

```
# Reading CSV from a volume
df_csv = spark.read.csv("/Volumes/my_volume/data.csv", header=True, inferSchema=True)

# Reading JSON from a volume
df_json = spark.read.json("/Volumes/my_volume/data.json")

# Reading Parquet from a volume
df_parquet = spark.read.parquet("/Volumes/my_volume/data.parquet")
```

```
-- Reading CSV from a volume and creating a table
CREATE TABLE my_csv_table
USING CSV
OPTIONS (
  path "/Volumes/my_volume/data.csv",
  header "true",
  inferSchema "true"
);

-- Reading JSON from a volume and creating a table
CREATE TABLE my_json_table
USING JSON
OPTIONS (
  path "/Volumes/my_volume/data.json"
);

-- Reading Parquet from a volume and creating a table
CREATE TABLE my_parquet_table
USING PARQUET
OPTIONS (
  path "/Volumes/my_volume/data.parquet"
);
```

In Databricks SQL, you can query files directly from a volume without creating a table using the SELECT * FROM with the USING clause. For example:

```
-- Query CSV directly
SELECT *
FROM csv.`/Volumes/my_volume/data.csv`
OPTIONS (header "true", inferSchema "true");

-- Query JSON directly
SELECT *
FROM json.`/Volumes/my_volume/data.json`;

-- Query Parquet directly
SELECT *
FROM parquet.`/Volumes/my_volume/data.parquet`;
```

### How querying a volume folder directly compares with creating a Delta table

**Quering**

Pros:
- Quick and easy for ad-hoc queries.
- No table creation needed.
- Flexible: can read from any folder or file.

Cons:
- No indexing or optimization.
- Every query reads all files from scratch → slower on large datasets.
- Limited ACID guarantees.

**Creating table**
Pros:
- Optimized for performance: supports Delta caching, Z-ordering, and partition pruning.
- ACID transactions: safe concurrent reads/writes.
- Easier to update, delete, or merge data.
- Works well for streaming ingestion or incremental updates.

Cons:
- Requires one-time table creation.
- Slightly more setup than direct file queries.

## Updating a Delta table created by volume files (or by external files from a external cloud storage)
**Folder of parquet files**

When you create a Delta table on a folder of Parquet files, you are not just reading the Parquet files directly anymore. Delta adds a transaction log (_delta_log/) that keeps track of all changes.

UPDATE or INSERT: Delta does not modify the existing Parquet files in-place. Instead, it: Writes new Parquet files with the updated or inserted data. Updates the transaction log to point to the new files and mark old files as obsolete. Your Delta table always shows the latest state, but the original Parquet files that were there when you created the table may remain unchanged (they are just no longer referenced in the active Delta table view). Old parquet files are cleaned up later via VACUUM. Directly modifying files in the volume (outside Delta) can break the Delta table consistency.

**Folder of other format files**

When you create a Delta table from CSV files, for example: Delta reads the CSV files once when creating the table. Internally, Delta converts the data into Parquet files in the same folder (or a Delta-managed folder if location is not explicitly given). After creation: Any INSERT, UPDATE, or DELETE operates on the Parquet files that Delta manages, not the original CSV files. The original CSV files remain unchanged (Delta does not overwrite them). The Delta table keeps a transaction log in _delta_log/ and references the new Parquet files.

Rule of thumb: After creating a Delta table from any file format (CSV, JSON, Parquet) and whether from a volume or external storage, all changes happen in Delta-managed Parquet files, never in the original CSV/JSON files.


## DBFS
In Databricks, DBFS (Databricks File System) is the distributed file system that sits on top of your cloud storage. Within DBFS, there are different types of paths, and managed paths are one of them.

DBFS is a layer that lets you access your cloud storage (S3, ADLS, GCS) as if it were a regular file system (via /dbfs/... in Python/Scala or dbfs:/... in Spark or SQL). 

**Managed DBFS** paths are locations managed by Databricks itself, usually when you create tables without specifying a location (Databricks automatically stores the underlying files in a managed DBFS path, typically under: `/user/hive/warehouse/my_table/` or `/user/<workspace-user>/...`). These paths are private to your workspace or table and managed by Databricks: You don’t need to know the physical storage location in the cloud. Databricks handles file naming, organization, and cleanup. When you drop the table, the files in the managed path are automatically deleted.

**External paths** are when you explicitly provide a cloud storage location, e.g.: `LOCATION '/Volumes/my_volume/my_table/'` Here, Databricks does not manage the files; you are responsible for the storage. Dropping the table does not delete the files in the location.

Managed DBFS paths
- Example: /user/hive/warehouse/my_table/
- Databricks owns and manages the files.
- If you drop a table, Databricks also deletes the files.
- Default when you don’t specify a LOCATION in CREATE TABLE.

External paths
- Example: Cloud bucket: `s3://my-bucket/...` Mounted path: `/mnt/my_mount/...` Volume path: `/Volumes/<catalog>/<schema>/<volume>/... `
- Files live in your cloud storage (S3, ADLS, GCS).
- Databricks does not delete them if you drop the table.
- You manage lifecycle of the files.

A volume in Unity Catalog is a managed path. Managed volumes are Unity Catalog-governed storage created within the managed storage location of the containing schema. You do not need to specify a location when creating a managed volume, and all file access for data in managed volumes is through paths managed by Unity Catalog. It provides:
- standard path for file access: `/Volumes/<catalog>/<schema>/<volume>/<path>/<file-name>`
- Fine-grained access control managed by Unity Catalog
- You can use these paths in SQL, Python, or Spark to access files in the volume.


### Managed Delta table from CSV in a Volume
Managed tables: Unity Catalog manages both the governance and the underlying data files. Data is stored in a Unity Catalog-managed location in your cloud storage. Managed tables always use the Delta Lake format and benefit from features like auto compaction, auto optimize, and metadata caching. They are recommended for most use cases

Here we read the CSV in the volume, but when we create the Delta table **we do not specify a LOCATION**. Databricks will copy the data into a managed DBFS path (not in the volume anymore).
```
-- Managed delta table: data copied into Databricks-managed storage
CREATE TABLE managed_customers
USING DELTA
AS
SELECT *
FROM csv.`/Volumes/catalog/schema/volume/raw/customers.csv`
OPTIONS (header "true", inferSchema "true");
```
Result:
- The data is stored in Unity Catalog managed storage, not at the original CSV location.
- The table is governed as a managed table, not an external table.
- You do not specify a LOCATION clause; Databricks manages the storage location.
- The original CSV file is only used as a data source during table creation.
- Table stored in Databricks-managed path (like /user/hive/warehouse/managed_customers/).
- Dropping the table deletes both metadata + data.
- Original CSV in the volume remains untouched.

### External Delta table from CSV in a volume
External tables: Unity Catalog manages access, but the data lifecycle and file layout are managed outside Databricks (by your cloud provider or other platforms). You must specify a location that is defined as a Unity Catalog external location. External tables support multiple formats and are useful when you need to register existing data or require access from outside Databricks. Databricks recommends eventually migrating external tables to managed tables for full governance and performance benefits.

You cannot create an external table in a volume. Volumes are managed storage abstractions in Unity Catalog, and you should not use the CREATE TABLE ... LOCATION syntax to create external tables inside a volume path. Instead, you can create a managed table from data stored in a volume, or use external locations for external table

```
-- External table: data stays in the external path
CREATE [EXTERNAL] TABLE external_customers
USING DELTA
LOCATION '/aws/customers_delta/';

INSERT INTO external_customers
SELECT *
FROM csv.`/aws/raw/customers.csv`
OPTIONS (header "true", inferSchema "true");
```
Or
```
CREATE TABLE my_csv_table
USING CSV
OPTIONS (
  header "true",
  inferSchema "true"
)
LOCATION 'abfss://<container>@<storage-account>.dfs.core.windows.net/<path>/data.csv';
```
You cannot create an external table using the CSV data source and specify a LOCATION that is different from the actual CSV file path. The LOCATION clause should point directly to the CSV file or directory containing CSV files in your external storage. The path option is not needed when you use the LOCATION clause.

Result:
- Delta transaction log + Parquet files live in /Volumes/catalog/schema/volume/customers_delta/.
- Dropping the table deletes only metadata — data files remain in the volume.
- Original CSV in /raw/ stays untouched.

Managed table → Delta files live in Databricks-managed DBFS; drop = data gone and metadata removed.

External table → Delta files live in your Volume; drop = only metadata removed, data remains.


## Managed table VS Managed Delta table
This query creates a managed table called my_table in Unity Catalog. The table is populated with the data from the specified CSV file in the volume, using the provided options to infer the schema and treat the first row as a header. The data is copied into Unity Catalog managed storage, and the table is governed as a managed table. You can insert data into the managed table using standard INSERT INTO statements. But inserting data into the managed table does not modify the source CSV file. The table stores its data separately in Unity Catalog managed storage. The original CSV remains unchanged.
```
CREATE TABLE my_table
USING CSV
OPTIONS (header "true", inferSchema "true")
AS SELECT * FROM csv.`/Volumes/<catalog>/<schema>/<volume>/path/to/file.csv`;
```

This query creates amanaged Delta table. The data from the CSV file in the volume is copied into Unity Catalog managed storage, and Unity Catalog manages both the table metadata and the underlying data files. The table is not external and does not reference the original CSV file after creation. For full ACID capabilities and best performance, it is recommended to use Delta tables
```
CREATE TABLE my_table
USING DELTA
AS SELECT * FROM csv.`/Volumes/<catalog>/<schema>/<volume>/path/to/file.csv`;
```


You cannot create a managed table in Unity Catalog using the CSV format. Managed tables in Unity Catalog must use Delta or Iceberg formats. To create a managed table from a CSV, use Delta as the format: