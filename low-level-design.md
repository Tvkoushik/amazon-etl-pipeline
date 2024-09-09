# Low Level Design

## Key Design Decisions for CDC and Ingestion Pipeline

- **Target Format**: Use **Parquet** instead of CSV for more efficient storage and faster query performance. `--s3-settings='{"DataFormat": "parquet"}'`

  `
  database_schema_name/table_name/LOAD00000001.csv
  database_schema_name/table_name/20141029-1134010000.csv
  ...`
  - **Reason**: Parquet is columnar, providing better compression and query speed, especially for large datasets.

- **File Naming & Path Structure**: Organize files in S3 by timestamps and partition keys. DMS stores files with default names like LOAD00000001.csv for full loads and timestamp-based names for CDC files (e.g., 20141029-1134010000.csv)
  - **Reason**: Improves file management, query performance, and enables better partitioning in downstream processes.

- **Transaction Order Preservation**: Enable **transaction ordering** in CDC files. `--s3-settings='{"IncludeTransactionDetails": true}'`
  - **Reason**: Ensures data consistency for use cases where the sequence of changes (insert, update, delete) matters.

- **File Size Management**: Set `MaxFileSize`, `cdcMaxBatchInterval`, and `cdcMinFileSize` for optimized performance. `--s3-settings='{"cdcMaxBatchInterval": 60, "cdcMinFileSize": 10485760}'`
  - **Reason**: Balances between small, frequent files (which increase I/O) and large files (which delay data availability).

- **Soft Delete Handling**: Implement logic to handle `DELETE` flags in CDC data.
  - **Reason**: Ensures that deleted records are properly processed during ETL for accurate reporting in Redshift.

- **Security**: Use **ExpectedBucketOwner** to ensure only the correct AWS account writes to the S3 bucket. `--s3-settings='{"ExpectedBucketOwner": "AWS_Account_ID"}'`
  - **Reason**: Prevents unauthorized access or misconfigurations when writing data to the S3 target.

- **CDC Change Flags**: Handle `I` (INSERT), `U` (UPDATE), `D` (DELETE) change flags in Glue during transformation.
  - **Reason**: Guarantees accurate application of changes in the data warehouse for real-time and historical analysis.

- **Initial Full Load**: Use **Amazon DMS** to migrate historical data from the OLTP system into S3 as the first step.
  - **Reason**: Ensures the entire dataset is moved to the warehouse before transitioning to incremental CDC.

- **Post Full Load CDC**: Use **CDC** with **Amazon DMS** to capture real-time changes and store them in S3.
  - **Reason**: Enables real-time or near real-time data availability for downstream analytics without database overhead.

- **Data Validation & Transformation**: Use **AWS Glue** to validate, clean, enrich, and transform the data before loading into Redshift.
  - **Reason**: Ensures high data quality and schema alignment before analytics, leveraging Glue's serverless architecture for scalability.

## Transform Section of ETL Pipeline

### 1. **Configuration-Driven Architecture**

- The entire pipeline is designed to be **config-driven**, allowing all data quality checks, transformations, and table mappings to be specified in configuration files.
- This approach provides a **scalable** and **flexible** pipeline, enabling easy updates to the rules and logic without modifying the core code.
- The configurations define **source S3 paths**, **target Redshift staging tables**, **data quality rules**, and **transformation rules** for each table.

### 2. **Data Quality and Transformation Logic**

- **Data Quality Checks**:
    - Quality rules are applied at multiple stages (raw to staging, staging to dimensions, dimensions to facts) to ensure the integrity and consistency of the data.
    - These checks include **null checks**, **valid date checks**, and **range checks**, all defined in the config files.
    - Both **Spark SQL** and **DataFrame API** methods are used, depending on the complexity and performance requirements of the checks.

- **Transformations**:
    - The transformation stage ensures that data is enriched, formatted, and prepared for downstream analytics.
    - Transformations are applied using **Spark SQL** or **DataFrame API**, depending on the type of transformation and the specific needs of the data. This ensures flexibility in processing complex business rules.

### 3. **Redshift Loading with Preactions**

- The staging tables in Redshift are loaded using a **truncate-and-load approach**. Before loading the data, a **`preactions`** SQL command is executed to truncate the staging table, ensuring a clean slate for each data load.
- This ensures that old data is cleared before new data is loaded, which prevents any residual data from previous loads.

- **Cluster Settings and Optimizations**:
    - Redshift cluster configurations are optimized for performance and scalability. **DIST and SORT keys** are defined on staging and dimension/fact tables to optimize query performance based on expected query patterns.
    - Redshift's **concurrency scaling** and **auto-scaling** options are considered for handling large workloads and ensuring high availability.

### 4. **Glue Cluster Settings and Optimizations**

- **Worker Type and Scaling**:
    - The Glue job leverages the **G.1X** or **G.2X** worker types, depending on the volume of data being processed. **Auto Scaling** is enabled to dynamically allocate resources based on job demands.

- **Spark Settings**:
    - **Parallelism** and **partitioning** are tuned based on the data volume to avoid memory bottlenecks and improve performance.
    - Glue jobs are configured with optimized **memory allocation** for Spark executors to prevent out-of-memory errors.

- **Glue Bookmarks**:
    - **Glue bookmarks** are used to track the files that have already been processed, ensuring that the data load is incremental and that files are not reprocessed unnecessarily.

### 5. **Error Handling and Retry Mechanism**

- **Retry Logic**:
    - The ETL pipeline incorporates a robust **retry mechanism** to handle transient failures. If a task fails, it is retried up to 3 times with exponential backoff, ensuring that the system can recover from temporary issues.
  
- **Error Logging and Monitoring**:
    - All errors and critical logs are pushed to **CloudWatch**, enabling real-time monitoring and alerting. Alerts are configured to notify the team of failures so that immediate action can be taken.
    - The logging strategy ensures that issues are easily traceable for faster debugging and troubleshooting.

### 6. **S3 Lifecycle Policies for DMS Files**

- **S3 Lifecycle Management**:
    - **Lifecycle policies** are applied to manage the raw data exported by DMS to S3. These policies ensure that older files are archived or deleted after a certain period (e.g., 30-90 days).
    - This helps optimize storage costs by moving older files to **Glacier** for long-term storage or deleting them if they are no longer needed.

### 7. **Data Partitioning and File Formats**

- **Parquet File Optimization**:
    - The pipeline leverages **parquet files** for efficient storage and processing, as they provide both **compression** and a **columnar format** for faster queries and reduced storage costs.

- **Compression and File Size**:
    - Care is taken to optimize the size of parquet files. File sizes between **128MB to 1GB** are ideal for balancing Spark performance and Redshift load times, ensuring efficient data processing.

### 8. **Handling CDC Flags in Staging**

- **Change Data Capture (CDC)**:
    - The pipeline handles **CDC flags** (`I`, `U`, `D`) generated by AWS DMS. These flags are passed into the staging tables and used to manage **SCD Type 2** logic for updates and deletions in the dimension and fact tables.
    - The appropriate insert, update, or delete actions are applied based on the CDC flags during the transformation process.

### 9. **Security Best Practices**

- **IAM Roles**:
    - **IAM roles** with the least-privilege principle are used to secure access to S3, Redshift, and other AWS resources. Glue jobs are run with roles that have only the necessary permissions to ensure a secure and compliant architecture.

- **S3 Bucket Policies**:
    - Strict **S3 bucket policies** are in place to limit access to sensitive data, ensuring that only necessary AWS services and roles have access to the data.

- **Encryption**:
    - Data is encrypted at rest using **server-side encryption (SSE)** in S3, and data in Redshift is encrypted using **KMS** keys to ensure data security.

### 10. **Monitoring and Performance Tuning**

- **CloudWatch Monitoring**:
    - Continuous monitoring of Glue jobs and Redshift performance is enabled via **CloudWatch**. Metrics such as job run times, memory usage, and errors are tracked to identify potential bottlenecks.
  
- **Redshift Query Performance**:
    - Regular reviews of **query execution plans** and optimizations to **SORT** and **DIST keys** are performed to ensure that Redshift queries are running efficiently.
    - **Concurrency scaling** and **RA3 nodes** are employed when necessary to enhance throughput and support large-scale workloads.

- **S3 Monitoring**:
    - **S3 request rates** and usage patterns are monitored to ensure that data transfer to Redshift is optimized and that there are no performance bottlenecks during the extract/load stages.