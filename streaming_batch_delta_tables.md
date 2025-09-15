
Reference:Difference between LIVE TABLE and STREAMING LIVE TABLE,CREATE STREAMING TABLE,Load data using streaming tables in Databricks SQL.


When using DLT, we can create a live table with either STREAMING LIVE TABLE or LIVE TABLE, as written in the docs :

CREATE OR REFRESH { STREAMING LIVE TABLE | LIVE TABLE } table_name

What is the difference between the two syntaxes ?
A live table or view always reflects the results of the query that defines it, including when the query defining the table or view is updated, or an input data source is updated. Like a traditional materialized view, a live table or view may be entirely computed when possible to optimize computation resources and time.

A streaming live table or view processes data that has been added only since the last pipeline update. Streaming tables and views are stateful; if the defining query changes, new data will be processed based on the new query and existing data is not recomputed.
https://docs.databricks.com/aws/en/dlt/dbsql/streaming