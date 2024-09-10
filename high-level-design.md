# High Level Design

## Extract

### Why Use CDC for Data Ingestion at Amazon Scale?

#### Full Load vs. Incremental Load

- **Full Load**:
  - **Definition**: Extracts the entire dataset from the OLTP system and loads it into the warehouse, replacing existing data.
  - **Pros**: Simple to implement and ensures no data is missed or corrupted.
  - **Cons**: Inefficient for large-scale datasets at Amazon’s scale, requires significant time and resources, high compute costs, and does not support real-time processing.
  - **Conclusion**: Not practical for high-volume transactional systems at Amazon scale.

- **Incremental Load**:
  - **Definition**: Extracts only the changes (inserts, updates, deletes) that occurred since the last load.
  - **Batch-Based Incremental**:
    - Simple to implement, reduces I/O load, but not suitable for real-time applications, and requires manual tracking of deletes.
  - **Change Data Capture (CDC)**:
    - Tracks and extracts database changes in real-time via logs, ensuring real-time updates and minimal read overhead.
    - **Pros**: Near real-time updates, minimal overhead, and automatic change tracking for inserts, updates, and deletes.
    - **Cons**: Complex to implement and requires continuous monitoring.

### Why CDC is the Best Choice?
- **Scalability**: Captures changes incrementally, handling millions of changes in real-time.
- **Real-Time Processing**: Supports near real-time updates crucial for operational systems like Amazon.
- **No DB Locks**: Reduces contention in high-concurrency environments.
- **Write-Ahead Logs (WAL)**: Uses logs without additional database reads.
- **Manual Coding Not Required**: CDC tools like **Amazon DMS** automate log capture and change processing.

---

## Best Practices for Setting up CDC with Amazon DMS and S3 Staging

1. **Use Amazon DMS for CDC**:
   - Supports log-based CDC for databases like PostgreSQL, capturing changes continuously with minimal database impact.

2. **Push Changes to Amazon S3 as Staging**:
   - **Why Use S3**: S3 is scalable, cost-effective, and integrates with AWS services like Redshift and Glue.

3. **Schema and Data Evolution**:
   - Use **AWS Glue** Data Catalog to manage schema changes and handle schema drift in Redshift.

4. **CDC Monitoring and Error Handling**:
   - Use **CloudWatch Alarms** for DMS monitoring and checkpointing to ensure changes are processed only once.

5. **Security**:
   - Encrypt data at rest using **SSE** in S3 and apply proper IAM policies to secure the pipeline.

6. **High Availability (HA)**:
   - Configure **Multi-AZ DMS Replication** and ensure failover strategies for minimal downtime.

7. **Load into Data Warehouse**:
   - Use **Redshift COPY** command to load data in parallel and **MERGE** for efficient incremental updates.

---

## Conclusion: Why CDC is the Best Choice

- **Real-Time Capability**: Real-time or near real-time data is essential for Amazon-scale operations.
- **Efficient Resource Usage**: CDC reduces bandwidth, I/O load, and compute requirements.
- **Database-Friendly**: CDC captures changes without querying the database directly, ensuring no performance degradation.
- **Scalable and Fault-Tolerant**: With Amazon DMS, S3, and Redshift, the architecture is highly scalable and resilient.

---

## Transform Section of ETL Pipeline

### 1. **Objective**

The transform stage focuses on applying **data quality** checks and **transformations** as the data moves from **raw source (S3)** to **staging tables** in **Amazon Redshift**. This ensures data is cleaned, validated, and prepared for analytics and reporting.

### 2. **Key Components**

- **Data Quality**: Rules ensure data integrity at multiple stages, including null checks, range checks, and valid date checks.
- **Transformations**: Business logic is applied to enrich and format data for analytics.
- **Error Handling and Fault Tolerance**: The pipeline incorporates error handling and retry mechanisms to ensure resilience.

### 3. **Workflow Overview**

1. **Source Data (S3)**: Parquet files from DMS are stored in S3.
2. **Load Raw Data**: Parquet files are loaded into Spark.
3. **Data Quality Checks**: Quality checks are applied to ensure the data’s integrity.
4. **Transformations**: Data is transformed based on business rules.
5. **Staging Tables (Redshift)**: Transformed data is loaded into Redshift staging tables with a truncate-and-load approach.
6. **Preactions**: The Redshift staging tables are truncated before loading.
7. **Postactions (Optional)**: Additional transformations or updates after loading.

### 4. **Key Design Considerations**

- **Config-Driven Approach**: The pipeline is fully driven by configuration files. This makes it easy to manage and update without changing code.
- **Flexibility**: Data quality and transformation rules can be applied at any level (raw to staging, staging to dimensions, dimensions to facts) using both Spark SQL and DataFrame API.
- **Scalability**: Designed to handle large-scale data at Amazon level, leveraging Glue and Redshift for efficient data processing.
- **Idempotency**: The pipeline ensures idempotent loads, meaning it can be re-run safely without duplicating data.
- **High Availability and Resilience**: The pipeline includes retry mechanisms and error handling to manage transient failures and ensure fault tolerance.

### 5. **Tools and Technologies Used**

- **AWS Glue**: Used for orchestration, data transformation, and applying data quality rules.
- **Amazon Redshift**: Used for storing staging and dimension/fact tables for analytics.
- **AWS DMS**: Used for Change Data Capture (CDC) and exporting raw data to S3 in parquet format.
- **Spark SQL** and **DataFrame API**: Used for applying transformations and data quality rules.

---

## Load Section of the ETL Pipeline

### 1. **Objective**

The load stage focuses on moving the data from the staging tables to the dimension and fact tables, ensuring that the dimensional model supports the necessary business use cases.

### 2. **Key Components**

- **Staging to Dimension/Fact Transformation**: Data from staging tables is merged into the dimension and fact tables. SCD Type 2 logic is applied where necessary.
- **SCD Type 2 Implementation**: For historical tracking, SCD Type 2 logic is applied on dimension tables, ensuring that any changes in the data are captured.
- **Fact Tables**: Fact tables are append-only, and no updates occur. 

### 3. **Workflow Overview**

1. **Load Data into Staging**: Data is first loaded into Redshift staging tables from S3.
2. **Dimension Table Load**: Apply SCD Type 2 logic for dimension tables using `MERGE`.
3. **Fact Table Load**: Insert fact data without duplicates using append-only logic.
4. **Postactions**: Post-load actions such as removing partial loads are applied.

---

## Monitoring, Orchestration, and Security

### 1. **Monitoring**

- **CloudWatch Monitoring**: All Glue jobs are monitored using **Amazon CloudWatch**, ensuring real-time alerting and error logging.
- **Retries**: If a job fails, it will automatically retry up to three times before raising an alert.
  
### 2. **Orchestration**

- **AWS Step Functions**: Step Functions are used to orchestrate the entire pipeline, ensuring that data is loaded in the correct order (staging, dimension, fact).
- **Step-Level Execution**: Each Glue job is triggered in a defined order, with error handling and retries in case of failure.

---

## Governance and Security

### 1. **Access Control**

- **IAM Policies**: The pipeline uses IAM roles with least-privilege access to manage data security.
- **Lake Formation**: Row/column level security is enforced using **AWS Lake Formation**, ensuring that sensitive data is protected.

### 2. **Data Encryption**

- **S3 Encryption**: Data at rest in S3 is encrypted using server-side encryption (SSE).
- **Redshift Encryption**: All data in Redshift is encrypted using **KMS** for additional security.

### 3. **Data Masking**

- **Sensitive Data**: Data like PII is masked or anonymized before being loaded into Redshift if needed.

---

## Visualization

- **Amazon QuickSight**: Data from Redshift is visualized using QuickSight, where dashboards are created to display business metrics and analytics.

---