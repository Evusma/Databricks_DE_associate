## Difference between Databricks DLT (Delta Live Tables) and Workflows.

They’re both orchestration/automation tools in Databricks, but they serve different purposes:


### Delta Live Tables (DLT)

What it is: A framework for declarative data pipelines. Instead of writing procedural ETL jobs, you define what tables you want and how they are derived, and DLT manages the execution.

When you create a Delta Live Tables (DLT) pipeline, you define your transformations in SQL or Python (via PySpark).

Main focus: Data pipeline development and reliability.

Features:

- Handles incremental processing natively with Delta Lake.
- Automatic data quality enforcement (with expectations).
- Built-in lineage tracking.
- Auto-scaling and recovery if a pipeline fails.
- Best when you want to manage Bronze → Silver → Gold tables in a Medallion architecture.

Analogy: Think of it like dbt inside Databricks, but with runtime management, scaling, and error handling baked in.

Pipeline definition is always tied to a notebook or a Python script.
- You define your transformations in SQL or Python inside a notebook (or optionally, a .py script from Repos).
- Without that, the pipeline has nothing to run — because DLT is declarative and must know your table definitions.

Notebook (or .py file) is required.


## Databricks Workflows

What it is: A general-purpose orchestration tool for any jobs in Databricks.

Main focus: Job scheduling and orchestration (not just data pipelines).

Features:

- Run any type of task: notebooks, Spark jobs, SQL queries, ML model training, Python scripts, even external tasks.
- Build multi-task workflows with dependencies (like Airflow or Prefect, but inside Databricks).
- Can include DLT pipelines as a task in the workflow.
- Good for orchestrating end-to-end processes: ingestion → transformation (maybe via DLT) → ML scoring → dashboard refresh.

Analogy: Think of it as Airflow built into Databricks, but with native integration.

✅ Does not require a notebook. You can orchestrate without ever touching one.
Much more flexible: Can run a notebook task, Or run a Python script, JAR, SQL statement, dbt task, or shell command.


## Key Difference

DLT = specialized for data pipelines (transformations + quality + lineage).

Workflows = general orchestration tool (runs DLT pipelines and any other tasks).


## Example Use Case:

Use DLT to create your Silver and Gold tables with expectations for data quality.

Use Workflows to:
- Trigger the DLT pipeline,
- Run ML training on the Gold table,
- Send notifications if something fails,
- Refresh dashboards afterwards.


## Languages Supported in DLT

SQL

- You can create tables with CREATE LIVE TABLE ... AS SELECT ...
- Perfect for declarative transformations.

Example:
```
CREATE LIVE TABLE silver_orders
COMMENT "Cleaned orders data"
AS SELECT *
FROM live.bronze_orders
WHERE status IS NOT NULL;
```

Python (PySpark or SQL inside Python)

You write functions that return a DataFrame and decorate them with @dlt.table (or @dlt.view).

Example:
```
import dlt
from pyspark.sql.functions import col

@dlt.table(
    comment="Filtered orders with non-null status"
)
def silver_orders():
    return (
        dlt.read("bronze_orders")
          .where(col("status").isNotNull())
    )
```

Not Supported: Scala, R, Raw Spark jobs outside of PySpark/SQL context

DLT is intentionally restricted to SQL + Python so it can:
- Track lineage automatically,
- Apply data quality expectations,
- Optimize execution,
- Make pipelines declarative and reproducible.


## Languages Supported in Databricks Workflows

Workflows are not tied to one language. Instead, they can orchestrate any type of task you can run in Databricks.

Supported task types (and thus languages):
- Databricks Notebook → can be in Python, SQL, Scala, or R (depending on cluster/runtime).
- DLT Pipeline → (which itself is SQL/Python, as we said).
- Python Script (from DBFS, Repos, or remote source).
- Spark JAR task → for Scala/Java.
- SQL task → runs SQL queries directly in a SQL warehouse.
- dbt task → if you integrate dbt with Databricks.
- Shell command task → for system-level commands.

You could create a Workflow that:
- Runs a Python notebook to ingest data,
- Triggers a DLT pipeline (SQL/Python) to process raw → silver → gold,
- Runs a Scala JAR task for complex ML feature engineering,
- Runs a SQL task to refresh a dashboard table,
- Sends a Slack notification with a Python script.

Comparison with DLT
- DLT: SQL & Python only → specialized for declarative pipelines.
- Workflows: Language-agnostic → orchestrates any task type (Python, SQL, Scala, R, Java, dbt, shell, etc.).


## Databricks UI

When you go to the Jobs & Pipelines tab, you’ll see options like:
- Ingestion pipeline
- ETL pipeline
- Job


-> DLT Pipelines

If you click Ingestion pipeline or ETL pipeline, you are creating a Delta Live Tables (DLT) pipeline.

Both options bring you to the same DLT creation flow — the only difference is the preset template:
- Ingestion pipeline → usually preconfigures Auto Loader for streaming ingestion into a Bronze table.
- ETL pipeline → gives you a blank DLT pipeline where you define your own Bronze → Silver → Gold logic.


-> Jobs

If you click Job, you’re creating a Databricks Workflow job.
This is for orchestrating notebooks, JARs, SQL tasks, Python scripts, etc.
Not a DLT pipeline (though you can call a DLT pipeline as a task inside a Workflow).