In the repo, there are some questions and notes that helped me for the preparation of the Databricks Data Engineer Associate Certification.

The questions have been taken from different websites and some answers might be wrong. Copilot, ChatGPT and Databricks AI assistant have been used to explain the answers of some questions, and the information of my the notes in the .md documents. I cannot guarantee that it's 100% correct (at the end of the day, AI assistants' responses are just probability, right?).

The questions are in the document questions_databricks_DE_associate.md, the notes of the other .md document are about:

**Auto Loader.md**
- Auto Loader
- Benefits
- Handling Data Inconsistencies
- Options of Auto Loader
- stream vs batch tables
- Checkpoint
- DataStreamWriter.trigger
- Summary Auto Loader:

**clusters.md** TO DO

**delta_table_vs_delta_live_tables.md** Difference between Delta Tables and  Delta Live Tables
- Delta Tables
- Delta Live Tables
- Delta Table Example (Storage Layer)
- Delta Live Tables example (Pipeline Framework)
- The bronze table of DLT
- Stream vs batch
- Batch mode in DLT

**dlt_vs_workflows.md**
- From June 2025, Databricks introduced new naming for both DLT and Jobs/Workflows.
- Difference between Databricks DLT (Delta Live Tables) and Workflows.
- Delta Live Tables (DLT)
- Databricks Workflows
- Key Difference
- Example Use Case
- Languages Supported in DLT
- Languages Supported in Databricks Workflows
- Databricks UI
- Jobs vs Pipelines

**other_topics**
- Reason to restart cluster in a databricks notebook which is using multiple languages
- %run magic command
- How does the concept of a metastore contribute to data governance in databricks
- Deduplicate rows
- Databricks runtime version
- DBFS
- transaction log
- VACUUM
- Z-ordering
- Service principal
- Time travel feature

**streaming_vs_batch_delta_tables.md**
- Stream vs Batch Tables
- Example Python
- Example SQL
- spark.read.format vs spark.read.table
- Stream and batch outside DLT
- Outside DLT: Plain Spark / Structured Streaming
- Using them (Plain Spark / Structured Streaming) in Workflows (Jobs)
- Difference (Plain Spark / Structured Streaming) vs DLT
- Structured Streaming job
- Example: Python Structured Streaming Job
- Example: SQL Structured Streaming Job
- spark.table() vs spark.read.table()
- spark.table() vs spark.readStream.format("delta").table("sales")
- spark.readStream.format("cloudFiles")

**volumes.md**
- Volume
- Files in the volume
- Files outside the volume
- How querying a volume file directly compares with creating a Delta table
- Updating a Delta table created from volume files or from files in a external cloud storage
- Managed Delta table from CSV in a Volume or from CSV in an external storage
- External Delta table from CSV in an external storage or from CSV in a Volume
- External table
- USING DELTA vs USING CSV
- External table and Databricks catalog


Websites: 
- [github canaytore](https://github.com/canaytore/spark-learnings/blob/main/Databricks_Certified_Associate_Developer_for_Apache_Spark_Practice_Exam.md)
- https://certificationpractice.com/practice-exams/databricks-certified-data-engineer-associate


Other websites:
- https://docs.azure.cn/en-us/databricks/
- https://docs.databricks.com/aws/en/
- https://docs.databricks.com/aws/en/getting-started/
- https://medium.com/the-data-therapy/how-i-scored-95-on-the-databricks-data-engineer-associate-certification-a-comprehensive-guide-c4ea47485a05
- https://www.databricks.com/discover/pages/getting-started-with-delta-live-tables#dlt
- https://www.databricks.com/learn/training/home
- https://www.databricks.com/resources/demos/tutorials#data-engineering
- https://www.databricks.com/training/catalog?roles=data-engineer
- https://www.leetquiz.com/certificate/databricks-certified-data-engineer-associate/practice
- https://www.pass4success.com/databricks/exam/databricks-certified-data-engineer-associate

Website to learn Spark: [sparkbyexamples](https://sparkbyexamples.com/)
