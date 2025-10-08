## From June 2025, Databricks introduced new naming for both DLT and Jobs/Workflows.

Databricks Jobs (i.e. Workflows) is now called Lakeflow Jobs
- June 11, 2025
- The product known as Databricks Jobs is now Lakeflow Jobs. No migration is required to use Lakeflow Jobs.

DLT (Delta Live Tables) is now called Lakeflow Declarative Pipelines
- June 11, 2025
- The product known as DLT is now Lakeflow Declarative Pipelines. No migration is required to use Lakeflow Declarative Pipelines.

Reference: https://docs.databricks.com/gcp/en/release-notes/product/2025/june


Implications

- The functionality of DLT / Jobs is preserved; this is more of a branding & naming change, though some new features accompany it. 
- “No migration required” language is used: you don’t need to manually remap everything; it’s mostly a rename under the hood. 
- Some API changes (e.g. AUTO CDC replacing APPLY CHANGES) are being encouraged in Lakeflow Declarative Pipelines. 


## Difference between Databricks Lakeflow Declarative Pipelines and Workflows.

They’re both orchestration/automation tools in Databricks, but they serve different purposes:


### Lakeflow Declarative Pipelines

What it is: A framework for declarative data pipelines. Instead of writing procedural ETL jobs, you define what tables you want and how they are derived, and pipelines manages the execution.

When you create a Lakeflow Declarative Pipelines, you define your transformations in SQL or Python (via PySpark).

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
- Without that, the pipeline has nothing to run — because it is declarative and must know your table definitions.

Notebook (or .py file) is required.


## Databricks Workflows

What it is: A general-purpose orchestration tool for any jobs in Databricks.

Main focus: Job scheduling and orchestration (not just data pipelines).

Features:

- Run any type of task: notebooks, Spark jobs, SQL queries, ML model training, Python scripts, even external tasks.
- Build multi-task workflows with dependencies (like Airflow or Prefect, but inside Databricks).
- Can include Lakeflow Declarative pipelines as a task in the workflow.
- Good for orchestrating end-to-end processes: ingestion → transformation → ML scoring → dashboard refresh.

Analogy: Think of it as Airflow built into Databricks, but with native integration.

✅ Does not require a notebook. You can orchestrate without ever touching one.
Much more flexible: Can run a notebook task, Or run a Python script, JAR, SQL statement, dbt task, or shell command.


## Key Difference

Lakeflow Declarative Pipelines = specialized for data pipelines (transformations + quality + lineage).

Workflows = general orchestration tool (runs Lakeflow Declarative Pipelines pipelines and any other tasks).


## Example Use Case:

Use pipelines to create your Silver and Gold tables with expectations for data quality.

Use Workflows to:
- Trigger the pipeline,
- Run ML training on the Gold table,
- Send notifications if something fails,
- Refresh dashboards afterwards.


## Languages Supported in Lakeflow Declarative Pipelines

SQL

- You can create tables with CREATE STREAMING TABLE ... AS SELECT ...
- Perfect for declarative transformations.

Example:
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
```

Python (PySpark or SQL inside Python)

You write functions that return a DataFrame and decorate them with @dp.table (or @dp.view).

Example:
```
from pyspark import pipelines as dp
from pyspark.sql.functions import col

@dp.table(
    comment="Filtered orders with non-null status"
)
def silver_orders():
    return (
        dp.read("bronze_orders")
          .where(col("status").isNotNull())
    )
```

Not Supported: Scala, R, Raw Spark jobs outside of PySpark/SQL context

Lakeflow Declarative Pipelines is intentionally restricted to SQL + Python so it can:
- Track lineage automatically,
- Apply data quality expectations,
- Optimize execution,
- Make pipelines declarative and reproducible.


## Languages Supported in Databricks Workflows

Workflows are not tied to one language. Instead, they can orchestrate any type of task you can run in Databricks.

Supported task types (and thus languages):
- Databricks Notebook → can be in Python, SQL, Scala, or R (depending on cluster/runtime).
- Lakeflow Declarative Pipelines → (which itself is SQL/Python, as we said).
- Python Script (from DBFS, Repos, or remote source).
- Spark JAR task → for Scala/Java.
- SQL task → runs SQL queries directly in a SQL warehouse.
- dbt task → if you integrate dbt with Databricks.
- Shell command task → for system-level commands.

You could create a Workflow that:
- Runs a Python notebook to ingest data,
- Triggers a Lakeflow Declarative Pipelines (SQL/Python) to process raw → silver → gold,
- Runs a Scala JAR task for complex ML feature engineering,
- Runs a SQL task to refresh a dashboard table,
- Sends a Slack notification with a Python script.

Comparison with Lakeflow Declarative Pipelines
- Lakeflow Declarative Pipelines: SQL & Python only → specialized for declarative pipelines.
- Workflows: Language-agnostic → orchestrates any task type (Python, SQL, Scala, R, Java, dbt, shell, etc.).


## Databricks UI

When you go to the Jobs & Pipelines tab, you’ll see options like:
- Ingestion pipeline
- ETL pipeline
- Job


-> Lakeflow Declarative Pipelines

If you click Ingestion pipeline or ETL pipeline, you are creating a Lakeflow Declarative Pipelines.

Both options bring you to the same pipeline creation flow — the only difference is the preset template:
- Ingestion pipeline → usually preconfigures Auto Loader for streaming ingestion into a Bronze table.
- ETL pipeline → gives you a blank pipeline where you define your own Bronze → Silver → Gold logic.


-> Jobs

If you click Job, you’re creating a Databricks Workflow job.
This is for orchestrating notebooks, JARs, SQL tasks, Python scripts, etc.
Not a Lakeflow Declarative Pipelines pipeline (though you can call it as a task inside a Workflow).


## Jobs vs Pipelines

In Databricks certification context:

Jobs = Workflows
- A Job in the UI = a Databricks Workflow.
- It’s the general-purpose orchestration engine.
- Can run notebooks, Python scripts, SQL, JARs, dbt, shell commands, or even pipelines as tasks.


Pipelines = Lakeflow Declarative Pipelines
- A Pipeline in the UI = a Lakeflow Declarative Pipelines
- Specialized for data ingestion and ETL (Bronze → Silver → Gold).
- Written only in SQL or Python (PySpark).
- Brings built-in lineage, expectations, auto-scaling, and reliability.