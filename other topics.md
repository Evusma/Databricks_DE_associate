
## Reason to restart cluster in a databricks notebook which is using multiple languages

In a Databricks notebook that uses multiple languages (like Python, SQL, R, Scala), there are several situations where you might want to restart the cluster. Here are the main reasons:

- Language Kernel Conflicts: When you switch languages in a notebook using magic commands (%python, %sql, %r, %scala), sometimes the underlying language interpreters or libraries may conflict. Restarting clears the state and ensures each language starts fresh.

- Memory Leaks or High Resource Usage: Long-running notebooks or heavy operations (large DataFrames, complex ML training) can consume memory. If memory usage grows too high, restarting frees memory and resets Spark executors.

- Library or Package Changes: If you install a new library using %pip install or %conda install, it often requires a cluster restart to take effect across all nodes.

- Stale or Corrupted Spark Context: Errors in Spark operations (e.g., failed jobs, executor crashes) can leave the Spark context in a bad state. Restarting ensures a clean Spark session.

- Configuration Changes: Changes to cluster configuration (Spark settings, environment variables) may require a restart to apply.

- Clearing Global State: Variables, temporary tables, UDFs, or broadcast variables persist across cells. Restarting ensures all state is cleared, which is important if previous runs interfere with current execution.

- Switching Languages or Using Multi-Language Features: While Databricks supports multiple languages, some inter-language operations (like using Python variables in SQL via spark.sql) may behave unexpectedly after extended usage. A restart helps.


## %run magic command
The %run magic command is used to include or run another notebook inside the current notebook (it executes another notebook.). Essentially, it allows you to reuse code from another notebook, like importing a module.

`%run /path/to/other_notebook`

When you run %run: The code in the referenced notebook is executed immediately. Any functions, classes, or variables defined in that notebook become available in the current notebook.


## How does the concept of a metastore contribute to data governance in databricks
The metastore plays a central role in managing and governing data.

A metastore is essentially a central repository of metadata about your data. Metadata includes:
- Table names, schemas, and column types;
- Table locations (where the data physically resides, e.g., in a Delta Lake or S3 bucket);
- Partitions and their structure;
- Access permissions and ownership information;
- Data versions (for Delta tables);

In Databricks, this is typically implemented via Hive Metastore or the Unity Catalog.

**How It Contributes to Data Governance**

Data governance involves managing who can access data, how data is structured, and ensuring data quality and compliance. The metastore contributes to this in several ways:

- Centralized Metadata Management: By storing all table schemas, partitions, and locations in one place, the metastore ensures that all users and tools are working with consistent metadata. This prevents issues like schema drift or users querying outdated datasets.

- Access Control: Through Unity Catalog or Hive Metastore, you can define permissions at the table, schema, and column level. This enables role-based access control (RBAC), which is crucial for GDPR, HIPAA, or internal compliance policies.

- Data Lineage & Auditing. Since the metastore tracks table definitions and versions, it allows teams to understand where data came from, how it has changed over time, and who accessed it. This supports auditing, compliance, and reproducibility.

- Integration Across Workloads. Both batch (Spark jobs, SQL analytics) and streaming workloads rely on the metastore for table definitions. This ensures consistent behavior and governance regardless of the compute engine used.

- Enforcing Standards and Quality: By centralizing metadata, the metastore allows organizations to enforce naming conventions, schema validation, and standardized partitioning. This reduces errors and improves the reliability of downstream analytics and ML workflows.

**Databricks-Specific Considerations:**

- Unity Catalog (Databricks’ modern metastore) adds fine-grained governance, including: Column-level permissions, Cross-workspace sharing, Lineage tracking

- Delta Lake tables leverage the metastore to maintain transactional consistency and version history, which is critical for regulatory compliance and reproducible analytics.

The metastore in Databricks is a central source of truth for all data assets. It enables consistent metadata management, access control, auditing, and standardization, which are all key pillars of data governance. Without it, enforcing policies, tracking data lineage, and ensuring compliance would be nearly impossible in large-scale data environments.


## Deduplicate rows
“Deduplicate rows” means removing duplicate records from a dataset so that each row is unique based on certain columns (or on all columns).

```
# Remove duplicates based on all columns
df_unique = df.drop_duplicates()

# Remove duplicates based on specific columns (e.g., Name and Age)
df_unique = df.drop_duplicates(subset=['Name', 'Age'])
```

```
-- Remove duplicates using DISTINCT
SELECT DISTINCT Name, Age, City
FROM my_table;

-- Or use ROW_NUMBER() if you want to keep one row per group
WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY Name, Age ORDER BY City) AS rn
    FROM my_table
)
SELECT *
FROM cte
WHERE rn = 1;
```
- `ROW_NUMBER() OVER(...)` assigns a unique number to each row within a partition.
- `PARTITION BY Name, Age` means the numbering restarts for each unique combination of Name and Age.

![original](/images/original.png)
```
WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY Name, Age ORDER BY City) AS rn
    FROM my_table
)
```
![cte](/images/cte.png)

```
SELECT *
FROM cte
WHERE rn = 1;
```
![query](/images/query.png)


## Databricks runtime version.
In Databricks, a runtime version is essentially the pre-configured environment that your cluster uses, including the versions of Apache Spark, Python, Scala, Java, ML libraries (Pre-installed libraries like pandas, numpy, scikit-learn, MLlib), and other component (Databricks optimizations for performance, Optional GPU support for ML/AI workloads.). Choosing the right runtime version is important because it affects compatibility, performance, and available features.

Types of Databricks Runtimes:
- Standard – general-purpose Spark workloads.
- ML Runtime – includes popular ML libraries like TensorFlow, PyTorch, XGBoost.
- GPU ML Runtime – ML runtime optimized for GPUs.
- Photon – Databricks’ next-gen engine for faster SQL & analytics.
- Lightweight or Minimal – smaller footprint, fewer pre-installed packages.

How to check or set runtime:
- In Databricks UI: when creating a cluster, there’s a “Databricks Runtime Version” dropdown.
- Via API: you can retrieve cluster info with databricks clusters get to see its runtime.
- Example in Python: `spark.conf.get("spark.databricks.clusterUsageTags.sparkVersion")`

Choosing a Runtime:
- Newer versions: include latest Spark, Python, and libraries. Usually better performance but may have breaking changes.
- Older versions: more stable for legacy code.
- ML or GPU workloads: choose ML or GPU runtime accordingly.
- Photon: better for SQL-heavy queries or large-scale analytics.

Why it matters:
- Compatibility: Some libraries or APIs require certain Spark or Python versions.
- Performance: Newer runtimes can leverage optimizations (Photon, Delta Lake enhancements).
- Support: Older runtimes are eventually deprecated.

Changing or updating the Databricks runtime is basically telling your cluster to use a different pre-configured environment. Here's how it works and what you need to know:
- Cluster restart required: When you change the runtime, Databricks will terminate your current cluster and start a new one with the new runtime.
- Libraries may need reinstallation: Any libraries you installed manually (PyPI, Maven, CRAN, etc.) may need to be reinstalled, because the new runtime has a different environment.
- Path and version changes: Python, Spark, and other components might change versions, which can affect your code.
- Notebooks: The code itself stays the same, but runtime-specific behavior might change (e.g., new Spark functions, Python version differences).
- Jobs: Any jobs pointing to the cluster will run on the new runtime after the update. Some jobs may fail if they rely on older dependencies.

Best practices before updating
- Test in a new cluster: Create a temporary cluster with the new runtime to verify your notebooks run correctly.
- Check dependencies: Ensure all Python packages, JARs, or R packages are compatible with the new runtime.
- Backup critical data: For long-running clusters, make sure your Delta tables or checkpoints are safe.

After the update
- Cluster is “new”: All previous cluster state (variables, installed libraries in the cluster environment) is lost.
- Notebooks remain intact: Your code is unaffected unless it depends on specific runtime versions.
- Delta tables and external storage: These are not affected; your data stays safe.

Updating the runtime on an existing cluster vs Creating a new cluster with the updated runtime:

- Updating the runtime on an existing cluster: You edit the cluster and change its runtime version, cluster keeps the same ID and configuration (number of workers, autoscaling settings, etc.), installed libraries may be lost, any cluster-specific state is lost.

- Creating a new cluster with the updated runtime: You create a completely new cluster and select the desired runtime version, everything is fresh: libraries, Python/Spark versions, environment. No risk of interfering with your existing cluster’s jobs or state. Can test new runtime without affecting production.

Best practice
- Create a test cluster with the new runtime first.
- Run critical notebooks/jobs to ensure compatibility.
- Once verified, either: Update the old cluster runtime (if you want to maintain cluster ID), or replace production cluster with the new cluster and update jobs to point to it.


## DBFS
In Databricks, DBFS (Databricks File System) is the distributed file system that sits on top of your cloud storage. Within DBFS, there are different types of paths: managed paths and external paths. DBFS is an abstraction layer that allows you to access your cloud storage (such as Azure Data Lake Storage, S3, GCS) using familiar file system paths like /dbfs/... in Python/Scala or dbfs:/... in Spark or SQL. DBFS paths are used to access data within Databricks and are typically mounted on top of cloud storage. 
However, for Unity Catalog and production workloads, Databricks recommends using Unity Catalog volumes or direct cloud URIs (like abfss://...) instead of DBFS paths, as DBFS mounts and root are deprecated for new workflows.

In Databricks, "mounted" typically refers to the legacy practice of linking cloud storage to the Databricks File System (DBFS) using a mount point (like /mnt/...). This allows you to access cloud storage as if it were part of the local file system

**Managed DBFS** are paths that are managed within Databricks File System (DBFS) and are typically used for accessing data within Databricks (so locations managed by Databricks itself). Usually when you create tables without specifying a location, Databricks automatically stores the underlying files in a managed DBFS path, typically under: `/user/hive/warehouse/my_table/` or `/user/<workspace-user>/...`. These paths are private to your workspace or table and managed by Databricks: You don’t need to know the physical storage location in the cloud. Databricks handles file naming, organization, and cleanup. When you drop the table, the files in the managed path are automatically deleted.

- Managed DBFS paths are used for accessing data within Databricks.
- They are typically accessed using paths like /dbfs/... in Python/Scala or dbfs:/... in Spark or SQL.
- Managed DBFS paths are part of the Databricks File System and are managed within the Databricks environment.


**External paths** are paths that point to data stored externally, such as in cloud storage, and are accessed using cloud storage URIs (so when you explicitly provide a cloud storage location, e.g.: `abfss://<container>@<storage-account>.dfs.core.windows.net/<path>/`). Here, Databricks does not manage the files; you are responsible for the storage. Dropping the table does not delete the files in the location.

Direct cloud URIs are used to access data in external locations using cloud storage URIs. Databricks supports accessing data in external volumes using cloud storage URIs. When working with external tables and external volumes, Databricks recommends reading and writing data using cloud storage URIs. Unity Catalog supports path-based access to external tables and external volumes using cloud storage URIs

- External paths are used to access data stored externally, such as in cloud storage (e.g., Azure Data Lake Storage, AWS S3, Google Cloud Storage).
- They are accessed using cloud storage URIs, such as abfss://... for Azure Data Lake Storage.
- External paths point to data that is stored outside of the Databricks environment and are typically used for accessing data from external sources.


Managed DBFS paths
- Example: /user/hive/warehouse/my_table/
- Databricks owns and manages the files.
- If you drop a table, Databricks also deletes the files.
- Default when you don’t specify a LOCATION in CREATE TABLE.

External paths
- Example: Cloud bucket: `s3://my-bucket/...` Mounted path: `/mnt/my_mount/...`
- Files live in your cloud storage (S3, ADLS, GCS).
- Databricks does not delete them if you drop the table.
- You manage lifecycle of the files.

**Volume path.** A volume path is a managed DBFS path within Unity Catalog. Managed volumes are Unity Catalog-governed storage created within the managed storage location of the containing schema. You do not need to specify a location when creating a managed volume, and all file access for data in managed volumes is through paths managed by Unity Catalog. For Unity Catalog volumes, you do not need to create a mount. Volumes are natively accessible at standard path. It provides:
- standard path for file access: `/Volumes/<catalog>/<schema>/<volume>/<path>/<file-name>`
- Fine-grained access control managed by Unity Catalog
- You can use these paths in SQL, Python, or Spark to access files in the volume.

Unity Catalog volumes are part of the Unity Catalog three-level namespace and provide a path-based access to data in cloud storage. The path format for accessing volumes is `/Volumes/<catalog>/<schema>/<volume>/<path>/<file-name>` or `dbfs:/Volumes/<catalog>/<schema>/<volume>/<path>/<file-name>`. Volumes are securable objects that most Azure Databricks users should use to interact directly with non-tabular data in cloud object storage.


## transaction log 
Delta tables maintain a transaction log (the _delta_log/ directory) that records all changes to the table, including inserts, updates, deletes, and schema changes. This log enables ACID transactions, time travel, and concurrent reads/writes, ensuring data consistency and reliability.

For external Delta tables, the transaction log (_delta_log/ directory) is stored alongside the data files in the specified external cloud storage location. This log tracks all changes and enables Delta Lake features such as ACID transactions and time travel. For external Delta tables, if you drop the table, only the table metadata is removed; the data files and the _delta_log/ transaction log in the external storage location are not deleted.


## VACUUM 
The VACUUM command in Databricks Delta is used to clean up the transaction log by removing files that are no longer needed for query processing and are older than a retention threshold. This helps optimize the performance and manage the storage of Delta tables.

If you want to run the VACUUM command on a Delta table in Databricks SQL, you can use the following syntax: `VACUUM <table_identifier> RETAIN <num HOURS | num DAYS>;`

The default retention threshold for the VACUUM command in Databricks Delta is 7 days. This means that by default, the VACUUM command will retain data files for up to 7 days before cleaning up the unused files to optimize storage and performance. After running VACUUM, files older than the retention period are permanently deleted. You cannot use time travel to access data versions that depend on those deleted files.
```
-- Example: After this, time travel to versions older than 7 days is not possible
VACUUM my_table;
```

## Z-ordering
Z-ordering is a data layout optimization for Delta tables that co-locates related information in the same set of files by multi-column values. It improves data skipping and query performance, especially for queries filtering on those columns. To Z-ORDER a Delta table:
```
OPTIMIZE dataops_dev.schema_test.my_table
ZORDER BY (column1, column2);
```

## Service principal
A service principal in Azure Databricks is a security identity used by applications, services, or automation tools to access Databricks resources programmatically. It is created in Microsoft Entra ID (formerly Azure AD) and can be assigned roles and permissions to control access. Service principals are commonly used for running jobs, automation, and secure API access. A service principal is an identity used for automation and programmatic access in Azure Databricks. 

You use these credentials to authenticate your automation scripts or tools with Azure Databricks, instead of using a user account.

## Time travel feature
Time travel in Delta Lake allows you to query previous versions of a Delta table using a version number or timestamp. This is only available for Delta tables, not for tables created with the CSV format.