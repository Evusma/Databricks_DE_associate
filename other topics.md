
## Reason to restart cluster in a databricks notebook which is using multiple languages

Restarting a cluster in a Databricks notebook, especially when using multiple languages (such as Python, SQL, Scala, and R), is often necessary for the following reasons:

- Library and Environment Consistency: When you install or upgrade libraries (especially Python packages) during a session, the changes may not take effect until the Python process is restarted. This ensures that the new or updated libraries are correctly loaded and used in your current SparkSession. This is particularly important if you are specifying or updating versions of packages included in the Databricks Runtime, installing custom versions, or changing dependencies

- Kernel State Reset: Restarting the cluster (or the Python process) clears the current state, including all variables, imports, and cached data. This is crucial when switching between languages or running code that depends on a clean environment to avoid conflicts or unexpected behavior due to leftover state from previous executions

- Cross-Language Interoperability: In multi-language notebooks, changes in one language environment (e.g., updating a Python library) may not be reflected in another language's runtime until the cluster or process is restarted. Restarting ensures all language kernels are synchronized and using the latest environment configuration.

- Resolving Errors and Inconsistencies: If you encounter errors related to library versions, dependencies, or Spark context issues, restarting the cluster can often resolve these by reinitializing the environment and Spark context.

Best Practice: Databricks recommends installing all session-scoped libraries at the beginning of a notebook and running dbutils.library.restartPython() to clean up the Python process before proceeding, especially after making changes to the environment


## %run magic command
The `%run` magic command in Databricks notebooks is used to execute another notebook from within your current notebook. When you use `%run`, all the variables, functions, and classes defined in the target notebook become available in your current notebook’s scope. This is useful for code reuse, modularization, and sharing common logic (such as utility functions or configuration settings) across multiple notebooks.

Key points about `%run`:
- It executes the specified notebook as if its code were part of the current notebook.
- All variables and definitions from the run notebook are imported into the current notebook’s namespace.
- It is different from importing a Python module, as `%run` brings in all code, not just functions or classes.
- You can use relative or absolute paths to specify the notebook to run.

`%run /path/to/other_notebook`

Note: If the target notebook uses a different language (e.g., Scala or SQL), only the code in the same language as the calling notebook will be executed and imported. Cross-language variable sharing does not occur with `%run`. This means that if you define a variable in one language (e.g., Python) in a notebook and use `%run` to import that notebook into another notebook, you cannot directly access that variable in a different language context (e.g., Scala or SQL) in the calling notebook.


## How does the concept of a metastore contribute to data governance in databricks
The concept of a metastore in Databricks is central to data governance because it acts as a centralized repository for metadata about data assets (such as tables, schemas, and permissions). This metadata management enables organizations to control, audit, and secure access to data, which are key aspects of data governance.

Key contributions of a metastore to data governance in Databricks:

- Centralized Metadata Management: The metastore registers and manages metadata about data, AI assets, and permissions, providing a unified view of all data assets. This helps reduce duplication and data sprawl, making it easier to discover and manage data.

- Access Control: The metastore enables fine-grained access control by managing permissions at the catalog, schema, and table levels. This ensures that only authorized users can access sensitive data, supporting compliance and security requirements.

- Auditing and Monitoring: By tracking metadata changes and access patterns, the metastore supports auditing, allowing organizations to capture who accessed what data and when. This is crucial for regulatory compliance and internal governance policies. Since the metastore tracks table definitions and versions, it allows teams to understand where data came from, how it has changed over time, and who accessed it.

- Data Quality and Consistency: The metastore helps ensure data quality by maintaining consistent metadata definitions, which reduces errors and inconsistencies across different data consumers and platforms.

- Transition to Advanced Governance Models: While Databricks originally used the legacy Hive metastore, it now recommends Unity Catalog, which provides enhanced data governance features such as unified access control, better performance, and more robust auditing capabilities. Unity Catalog surfaces all data objects, including those from the legacy Hive metastore, in a unified interface, making it easier to manage governance across hybrid environments.

- Integration Across Workloads. Both batch (Spark jobs, SQL analytics) and streaming workloads rely on the metastore for table definitions. This ensures consistent behavior and governance regardless of the compute engine used.

In summary, the metastore is foundational for implementing robust data governance in Databricks by centralizing metadata, enabling access control, supporting auditing, and ensuring data quality and discoverability.

**Databricks-Specific Considerations:**

- Unity Catalog (Databricks’ modern metastore) adds fine-grained governance, including: Column-level permissions, Cross-workspace sharing, Lineage tracking. Unity Catalog serves as the modern metastore in Databricks, providing an account-level, centralized repository for metadata about data, AI assets, and permissions for catalogs, schemas, and tables. This centralization is crucial for consistent metadata management and governance across all workspaces

- Fine-grained governance: Unity Catalog enables administrators to manage permissions at scale, including column-level permissions, cross-workspace sharing, and lineage tracking. This ensures that only authorized users have access to sensitive data and that data access policies are enforced consistently across the organization

- Delta Lake integration: Delta Lake tables use the metastore to maintain transactional consistency and version history, supporting regulatory compliance and reproducible analytics.

- Delta Lake tables leverage the metastore to maintain transactional consistency and version history, which is critical for regulatory compliance and reproducible analytics.

- Central source of truth: The metastore acts as the authoritative source for all data assets, supporting access control, auditing, and standardization. This is essential for enforcing policies, tracking data lineage, and ensuring compliance in large-scale data environments

The metastore in Databricks is a central source of truth for all data assets. It enables consistent metadata management, access control, auditing, and standardization, which are all key pillars of data governance. Without it, enforcing policies, tracking data lineage, and ensuring compliance would be nearly impossible in large-scale data environments. Without a metastore, it would be extremely difficult to implement robust data governance, as there would be no unified way to manage metadata, permissions, or audit trails across the platform.


## Deduplicate rows
“Deduplicate rows” means removing duplicate records from a dataset so that each row is unique based on certain columns (or on all columns).

```
# Remove duplicates based on all columns
df_unique = df.dropDuplicates()

# Remove duplicates based on specific columns (e.g., Name and Age)
df_unique = df.dropDuplicates(['Name', 'Age'])
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
The Databricks Runtime version refers to the specific set of core components and libraries that run on Databricks clusters. Databricks Runtime includes Apache Spark and adds additional components and updates to improve usability, performance, and security for big data analytics. There are different runtime versions, including:
- Databricks Runtime: The standard runtime for general analytics and data engineering tasks.
- Databricks Runtime for Machine Learning (ML): Built on top of the standard runtime, this version includes prebuilt machine learning infrastructure and popular ML libraries such as TensorFlow, Keras, PyTorch, and XGBoost. It also offers pre-configured GPU support for deep learning workloads

When you create a cluster in Databricks, you can select the desired Databricks Runtime version from a drop-down menu. The version you choose determines the available features, libraries, and compatibility for your workloads.

To check or select the Databricks Runtime version:
- When creating a cluster, choose the runtime version from the drop-down menu.
- The selected runtime version appears next to the cluster name in the notebook interface.

Choosing the appropriate Databricks Runtime version is important for ensuring compatibility with your data processing, analytics, or machine learning tasks

In Databricks, a runtime version is essentially the pre-configured environment that your cluster uses, including the versions of Apache Spark, Python, Scala, Java, ML libraries (Pre-installed libraries like pandas, numpy, scikit-learn, MLlib), and other component (Databricks optimizations for performance, Optional GPU support for ML/AI workloads.). Choosing the right runtime version is important because it affects compatibility, performance, and available features.

Types of Databricks types of runtime environments to suit different workloads:
- Standard – general-purpose Spark workloads. For general-purpose Spark workloads, including batch and streaming jobs. It includes core Spark and Databricks optimizations
- ML Runtime – includes popular ML libraries like TensorFlow, PyTorch, XGBoost. Comes with pre-built machine learning and deep learning libraries such as TensorFlow, PyTorch, and XGBoost, and automates the creation of clusters with the necessary infrastructure for ML tasks.
- GPU ML Runtime – ML runtime optimized for GPUs. An extension of the ML Runtime, optimized for GPU workloads. It includes GPU hardware drivers and NVIDIA libraries like CUDA, and is designed for deep learning and other GPU-accelerated tasks
- Photon – Databricks’ next-gen engine for faster SQL & analytics. Databricks’ high-performance, vectorized query engine designed to accelerate SQL and analytics workloads on the platform
- Lightweight or Minimal – smaller footprint, fewer pre-installed packages. A smaller footprint runtime with fewer pre-installed packages, suitable for users who want more control over their environment or have minimal dependency requirements.

How to check or set runtime:
- In the Databricks UI: When creating a cluster, you can select the desired Databricks Runtime Version from a dropdown menu. This allows you to set the runtime environment for your cluster, which determines the available libraries and features
- Via API: You can use the Databricks REST API (such as clusters get) to retrieve information about a cluster, including its runtime version.
- In Python: You can check the runtime version from within a notebook using: `spark.conf.get("spark.databricks.clusterUsageTags.sparkVersion")`

Choosing a Runtime:
- Newer versions: include latest Spark, Python, and libraries. Usually better performance but may have breaking changes. Newer Databricks Runtime versions provide the latest versions of Spark, Python, and libraries, offering improved performance and new features, but may introduce breaking changes that could affect legacy code
- Older versions: more stable for legacy code. Older versions are more stable and are recommended for running legacy workloads that require compatibility and thorough testing before upgrading
- ML or GPU workloads: choose ML or GPU runtime accordingly. For machine learning (ML) or GPU workloads, you should select the ML or GPU-enabled runtime, which includes pre-installed ML libraries and, for GPU runtimes, the necessary hardware drivers and CUDA libraries
- Photon: better for SQL-heavy queries or large-scale analytics. Photon is recommended for SQL-heavy queries or large-scale analytics, as it provides fast query performance and is compatible with Spark SQL and DataFrame APIs. Photon is enabled by default in Databricks SQL warehouses and can be turned on for clusters to accelerate SQL and analytics workloads

Why it matters:
- Compatibility: Some libraries or APIs require certain Spark or Python versions. Certain libraries and APIs require specific versions of Spark or Python, which are tied to the Databricks Runtime version you select. Using the recommended or up-to-date runtime ensures that your code and dependencies are compatible and reduces the risk of version conflicts.
- Performance: Newer runtimes can leverage optimizations (Photon, Delta Lake enhancements). Newer runtimes often include performance improvements and optimizations, such as Photon and Delta Lake enhancements, which can lead to more efficient compute usage and cost savings for your workloads.
- Support: Older runtimes are eventually deprecated. Databricks regularly releases new runtimes and eventually deprecates older ones. Using supported runtimes ensures you receive updates, bug fixes, and security patches, while older runtimes may lose support over time.

Choosing the right Databricks Runtime version is essential for maintaining compatibility, maximizing performance, and ensuring ongoing support for your data and machine learning workloads.

Changing or updating the Databricks runtime is basically telling your cluster to use a different pre-configured environment. Here's how it works and what you need to know:
- Cluster restart required: When you change the Databricks Runtime, the platform will terminate your current cluster and start a new one with the selected runtime version. This is necessary because the runtime defines the entire software environment, including Spark, Python, and pre-installed libraries
- Libraries may need reinstallation: Any libraries you installed manually (via PyPI, Maven, CRAN, etc.) are not automatically carried over to the new runtime. You may need to reinstall them, as the new runtime could have different versions or compatibility requirements.
- Path and version changes: The versions of Python, Spark, and other components may change with the new runtime, which can impact your code and dependencies.
- Notebooks: The code in your notebooks remains unchanged, but runtime-specific behavior (such as available Spark functions or Python version differences) may affect execution results.
- Jobs: Any jobs that use the updated cluster will now run on the new runtime. If jobs depend on specific library versions or runtime behaviors, you should test them after the update to ensure compatibility.

Changing the Databricks Runtime is a powerful way to upgrade your environment, but it requires careful management of dependencies and testing to avoid disruptions.

Best practices before updating
- Test in a new cluster: Before updating your production cluster, create a temporary cluster with the new Databricks Runtime version to verify that your notebooks and jobs run as expected. This helps catch compatibility issues early and avoids disruptions to production workloads.
- Check dependencies: Ensure that all your dependencies (Python packages, JARs, R packages, etc.) are compatible with the new runtime. Some packages may require updates or configuration changes to work with newer versions of Spark, Python, or other components.
- Backup critical data: For long-running clusters, make sure your Delta tables, checkpoints, and other critical data are safely backed up before making changes. This is especially important if you rely on features like checkpointing for ML workflows or streaming jobs.

After the update
- After updating the Databricks Runtime, the cluster is essentially "new": all previous cluster state, including in-memory variables and any libraries installed directly on the cluster, is lost. You will need to reinstall any custom libraries and reinitialize variables as needed.
- Notebooks themselves remain intact; your code is not changed by the runtime update. However, if your code depends on specific runtime versions or library versions, you may need to make adjustments for compatibility.
- Delta tables and data stored in external storage (such as cloud object storage) are not affected by the runtime update; your data remains safe and accessible.

Updating the runtime on an existing cluster vs Creating a new cluster with the updated runtime:
- Updating the runtime on an existing cluster: When you edit an existing cluster to change its runtime version, the cluster retains its original ID and configuration settings (such as number of workers and autoscaling options). However, the cluster is restarted, so any installed libraries and in-memory state are lost and need to be reinstalled or reinitialized. This approach is convenient for keeping the same cluster configuration but does not preserve the previous environment state.
- Creating a new cluster with the updated runtime: When you create a new cluster and select the updated runtime, you get a completely fresh environment. This means all libraries, Python/Spark versions, and configurations start from scratch. There is no risk of interfering with jobs or state on your existing cluster, making this approach ideal for testing the new runtime before applying it to production workloads. It also allows you to run both old and new environments in parallel if needed.

Best practice
- Create a test cluster with the new runtime first: This allows you to safely verify that your code and dependencies work as expected in the new environment without impacting production workloads.
- Run critical notebooks/jobs to ensure compatibility: Testing your most important workflows helps catch any issues related to library compatibility, API changes, or runtime-specific behavior before rolling out changes to production.
- Once verified, either: Update the old cluster runtime if you want to maintain the same cluster ID and configuration, understanding that the cluster will restart and any in-memory state or manually installed libraries will be lost, or Replace the production cluster with the new cluster and update jobs to point to it, which is safer for production as it avoids interfering with running workloads and allows for a clean transition..

These steps help ensure a smooth and reliable upgrade process, minimizing the risk of disruptions to your production jobs and data pipelines




## DBFS
DBFS stands for Databricks File System. It is a distributed file system that Databricks uses to interact with cloud-based storage. DBFS provides a convenient way to read and write data within Databricks notebooks and jobs using paths like `dbfs:/`.

However, it's important to note that storing and accessing data using the DBFS root or DBFS mounts is now a deprecated pattern and not recommended by Databricks. Databricks advises against storing production data, libraries, or scripts in the DBFS root. Instead, you should use recommended alternatives for working with files, such as Unity Catalog volumes or direct access to cloud object storage (like AWS S3, Azure Data Lake, or Google Cloud Storage)

Key points:
- DBFS is still part of the Databricks platform and is used for interacting with cloud storage.
- The `dbfs:/` scheme is still supported, especially when working with Unity Catalog volumes.
- Avoid using DBFS root or DBFS mounts for production data or critical assets, as this pattern is deprecated
- DBFS (Databricks File System) is indeed a distributed file system used by Databricks to interact with cloud-based storage. It provides an abstraction layer so you can use familiar file system paths (like /dbfs/... in Python/Scala or dbfs:/... in Spark/SQL) to access your data.
- DBFS paths can refer to different storage areas, including the DBFS root and DBFS mounts. However, storing and accessing data using the DBFS root or DBFS mounts is now a deprecated pattern and not recommended by Databricks. Instead, Databricks recommends using Unity Catalog volumes or direct access to cloud object storage for production data and critical assets
- The underlying technology of DBFS is still part of the Databricks platform, and the dbfs:/ scheme is still supported, especially when working with Unity Catalog volumes

So, while DBFS does provide a convenient abstraction for accessing cloud storage, you should avoid using the DBFS root or mounts for production workloads and follow Databricks' latest recommendations for file management and storage. If you need to work with files in Databricks, refer to the latest recommendations for file management and storage to ensure best practices and future compatibility.

In Databricks, "mounted" refers to the legacy method of linking cloud object storage (such as S3, ADLS, or GCS) to the Databricks File System (DBFS) using a mount point, typically under the /mnt/ directory. This allows users to interact with cloud storage using familiar file paths as if the data were part of the local file system. However, it's important to note that mounts are now considered a legacy access pattern. Databricks recommends using Unity Catalog for managing all data access, as mounted data does not work with Unity Catalog and is not recommended for new workflows.

**Managed DBFS paths** are locations within the Databricks File System that are automatically managed by Databricks. When you create a managed table without specifying an external location, Databricks stores the underlying data files in a managed DBFS path (such as `/user/hive/warehouse/my_table/`). These paths are private to your workspace or table, and Databricks takes care of file organization, naming, and cleanup. When you drop a managed table, the files in the managed path are automatically deleted, so you don’t need to manage the physical storage location yourself. However, for new workloads, Databricks recommends using Unity Catalog managed tables and volumes, as they provide secure, fully managed storage locations and simplify configuration, optimization, and governance

- Managed DBFS paths are used for accessing data within Databricks.
- They are typically accessed using paths like /dbfs/... in Python/Scala or dbfs:/... in Spark or SQL.
- Managed DBFS paths are part of the Databricks File System and are managed within the Databricks environment.
- However, it's important to note that storing and accessing data using the DBFS root or DBFS mounts is now a deprecated pattern and not recommended by Databricks for new workflows

**External paths** in Databricks refer to locations in cloud storage (such as Azure Data Lake, S3, or GCS) that you access using explicit cloud storage URIs like `abfss://<container>@<storage-account>.dfs.core.windows.net/<path>/`. When you use external tables or volumes with these paths, Databricks does not manage the underlying files—you are responsible for managing the storage and files yourself. Dropping an external table does not delete the files in the external location; you must manage those files directly through your cloud storage provider.

Databricks supports accessing data in external volumes and external tables using direct cloud storage URIs. When working with Unity Catalog, you can use path-based access with cloud storage URIs for external tables and volumes. However, Databricks recommends that users interact with Unity Catalog tables using table names and access data in volumes using /Volumes paths for ease of use and governance. Still, direct access via cloud storage URIs is fully supported and governed by Unity Catalog privileges

- External paths are used to access data stored externally, such as in cloud storage (e.g., Azure Data Lake Storage, AWS S3, Google Cloud Storage).
- They are accessed using cloud storage URIs, such as abfss://... for Azure Data Lake Storage.
- External paths point to data that is stored outside of the Databricks environment and are typically used for accessing data from external sources. This approach is commonly used for integrating and managing data from external sources within Databricks

Managed DBFS paths
- Example: `/user/hive/warehouse/my_table/` they are the default storage locations for managed tables when you do not specify a LOCATION in your CREATE TABLE statement. 
- Databricks owns and manages the files, and when you drop the table, Databricks automatically deletes the associated files.
- If you drop a table, Databricks also deletes the files.
- Default when you don’t specify a LOCATION in CREATE TABLE.
- This behavior is standard for managed tables registered to the Hive metastore, with `/user/hive/warehouse` being the default directory for such data

External paths
- Example: Cloud bucket: `s3://my-bucket/...` Mounted path: `/mnt/my_mount/...` refer to files that reside in your own cloud storage (S3, ADLS, GCS). 
- Files live in your cloud storage (S3, ADLS, GCS).
- Databricks does not delete them if you drop the table. Databricks does not manage or delete these files if you drop the table; you are responsible for managing the lifecycle of the files yourself.
- This is a standard approach for external tables and volumes, where the data remains under your direct control rather than being managed by Databricks.

**Volume path.** A volume path is a managed DBFS path within Unity Catalog. Managed volumes are Unity Catalog-governed storage created within the managed storage location of the containing schema. You do not need to specify a location when creating a managed volume (Unity Catalog handles the storage location automatically), and all file access for data in managed volumes is through paths managed by Unity Catalog. For Unity Catalog volumes, you do not need to create a mount. Volumes are natively accessible at standard path. It provides:
- standard path for file access: `/Volumes/<catalog>/<schema>/<volume>/<path>/<file-name>`. These paths can also be accessed using the `dbfs:/Volumes/<catalog>/<schema>/<volume>/<path>/<file-name>` scheme if preferred. 
- Fine-grained access control managed by Unity Catalog
- You can use these paths in SQL, Python, or Spark to access files in the volume. This approach is consistent across languages and provides secure, governed access to your data

Unity Catalog volumes are part of the Unity Catalog three-level namespace (catalog, schema, volume) and provide a path-based access to data in cloud storage. The path format for accessing volumes is `/Volumes/<catalog>/<schema>/<volume>/<path>/<file-name>` or `dbfs:/Volumes/<catalog>/<schema>/<volume>/<path>/<file-name>`. Volumes are securable objects that most Azure Databricks users should use to interact directly with non-tabular data in cloud object storage.


## transaction log 
 The transaction log (the _delta_log/ directory) is a fundamental component of Delta tables in Databricks. It records all changes to the table—including inserts, updates, deletes, and schema modifications—which enables ACID transactions, time travel, and concurrent reads and writes, ensuring data consistency and reliability.

For external Delta tables, the _delta_log/ directory is stored alongside the data files in your specified external cloud storage location. This log tracks all changes and enables Delta Lake features such as ACID transactions and time travel. Importantly, if you drop an external Delta table, only the table metadata is removed from the metastore; the actual data files and the _delta_log/ transaction log in the external storage location are not deleted—you are responsible for managing those files yourself. This behavior ensures that your data and its history are preserved until you explicitly delete them from storage.

## VACUUM 
The VACUUM command in Databricks Delta is used to remove data files that are no longer referenced by the Delta table's transaction log (files that are no longer needed for query) and are older than a specified retention threshold. This helps optimize storage and maintain performance. The default retention threshold is 7 days, meaning files required for time travel queries within the last 7 days are preserved, but older unused files are deleted. After running VACUUM, you cannot time travel to versions older than the retention period, as the necessary files will have been permanently removed. 

This means that by default, the VACUUM command will retain data files for up to 7 days before cleaning up the unused files to optimize storage and performance. After running VACUUM, files older than the retention period are permanently deleted. You cannot use time travel to access data versions that depend on those deleted files.

If you want to run the VACUUM command on a Delta table in Databricks SQL, you can use the following syntax: `VACUUM <table_identifier> RETAIN <num HOURS | num DAYS>;`

```
-- Example: After this, time travel to versions older than 7 days is not possible
VACUUM my_table;

VACUUM my_table RETAIN 100 HOURS;
```

## Z-ordering
Z-ordering is a data layout optimization for Delta tables that co-locates related information in the same set of files based on the values of one or more columns. This improves data skipping and query performance, especially for queries that filter on those columns. You can apply Z-ordering using the OPTIMIZE command with the ZORDER BY clause, as in the example:
```
OPTIMIZE catalog.schema_test.my_table
ZORDER BY (column1, column2);
```
This technique is particularly effective when the columns used in ZORDER BY are frequently used in query predicates and have high cardinality

## Service principal
A service principal in Azure Databricks is a specialized security identity used by applications, services, or automation tools to access Databricks resources programmatically. It is created in Microsoft Entra ID (formerly Azure AD) and can be assigned roles and permissions to control access to Databricks resources. Service principals are commonly used for running jobs, automation, and secure API access, providing greater security and stability than using individual user accounts. 

You use these credentials to authenticate your automation scripts or tools with Azure Databricks, instead of using a user account.

## Time travel feature
The time travel feature in Delta Lake allows you to query previous versions of a Delta table by specifying either a version number or a timestamp. This capability is unique to Delta tables and is not available for tables created with formats like CSV. Time travel is useful for recreating analyses, auditing, debugging, and recovering from accidental data changes.

This is only available for Delta tables, not for tables created with the CSV format.

You can use the following syntax to query a Delta table using time travel:
```
SELECT * FROM my_table VERSION AS OF 10;
SELECT * FROM my_table TIMESTAMP AS OF '2023-01-01 12:00:00';
```
