
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

## transaction log , VACUUM, Z-ordering