# Low Level Design

## Key Design Decisions for CDC and Ingestion Pipeline

- **Target Format**: Use **Parquet** instead of CSV for more efficient storage and faster query performance. `--s3-settings='{"DataFormat": "parquet"}'`
  - **Reason**: Parquet is columnar, providing better compression and query speed, especially for large datasets.
  
- **File Naming & Path Structure**: Organize files in S3 by timestamps and partition keys. DMS stores files with default names like LOAD00000001.csv for full loads and timestamp-based names for CDC files (e.g., 20141029-1134010000.csv).
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
    - Transformations are applied using **Spark SQL** or **DataFrame API**, depending on the type of transformation and the specific needs of the data.

### 3. **Redshift Loading with Preactions**

- The staging tables in Redshift are loaded using a **truncate-and-load approach**. Before loading the data, a **`preactions`** SQL command is executed to truncate the staging table, ensuring a clean slate for each data load.
  
- **Cluster Settings and Optimizations**:
    - Redshift cluster configurations are optimized for performance and scalability. **DIST and SORT keys** are defined on staging and dimension/fact tables to optimize query performance based on expected query patterns.
    - **Concurrency scaling** and **auto-scaling** options are considered for handling large workloads.

### 4. **Glue Cluster Settings and Optimizations**

- **Worker Type and Scaling**:
    - The Glue job leverages the **G.1X** or **G.2X** worker types, depending on the volume of data being processed. **Auto Scaling** is enabled to dynamically allocate resources based on job demands.

- **Spark Settings**:
    - **Parallelism** and **partitioning** are tuned to avoid memory bottlenecks and improve performance.

### 5. **Error Handling and Retry Mechanism**

- **Retry Logic**:
    - The pipeline incorporates a robust **retry mechanism** with exponential backoff, ensuring the system can recover from temporary issues.
  
- **Error Logging and Monitoring**:
    - All errors and critical logs are pushed to **CloudWatch**, with alerts for failures to allow immediate action.

### 6. **S3 Lifecycle Policies for DMS Files**

- **Lifecycle policies** are applied to manage the raw data exported by DMS to S3. Older files are archived or deleted after a set period (e.g., 30-90 days), optimizing storage costs.

### 7. **Handling CDC Flags in Staging**

- The pipeline handles **CDC flags** (`I`, `U`, `D`) generated by AWS DMS, passing them into staging tables and using them for **SCD Type 2** logic for updates and deletions in the dimension and fact tables.

### 8. **Security Best Practices**

- **IAM Roles** with least-privilege principle are used for secure access to S3, Redshift, and other AWS resources.

- **S3 Bucket Policies** are in place to limit access to sensitive data, ensuring only authorized services can access the data.

### 9. **Monitoring and Performance Tuning**

- **CloudWatch Monitoring** is enabled for Glue jobs and Redshift performance, tracking job run times, memory usage, and errors.
  
- **Redshift Query Performance**: Regular reviews of **query execution plans** and optimizations to **SORT** and **DIST keys** ensure efficient queries.

- **S3 Monitoring**: **S3 request rates** and usage patterns are monitored to ensure optimized data transfer to Redshift.