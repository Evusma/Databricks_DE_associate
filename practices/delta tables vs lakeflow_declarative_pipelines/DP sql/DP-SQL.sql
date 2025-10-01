-- Define a streaming table to ingest data from a volume
CREATE OR REFRESH STREAMING TABLE bronze_sales
AS
SELECT 
*,
current_timestamp() AS processing_time,
_metadata.file_name AS file
 FROM STREAM read_files(
  '/Volumes/dataops_dev/schema_test/volume_test/delta_tables/json/',
  format => 'json',
  multiline => 'true'
);

CREATE OR REFRESH MATERIALIZED VIEW silver_sales
AS SELECT Id, CAST(money AS DOUBLE) AS money, processing_time, file
FROM bronze_sales;

CREATE OR REFRESH MATERIALIZED VIEW gold_sales_summary
AS SELECT Id, SUM(money) AS total_sales
FROM silver_sales
GROUP BY Id;