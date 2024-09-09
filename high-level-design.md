# High Level Design

## Extract

## Why Use CDC for Data Ingestion at Amazon Scale?

### Full Load vs. Incremental Load

- **Full Load**:
  - **Definition**: Extracts the entire dataset from the OLTP system and loads it into the warehouse, replacing existing data.
  - **Pros**:
    - Simple to implement.
    - Ensures that no data is missed or corrupted.
  - **Cons**:
    - Inefficient for large-scale datasets, requiring significant time and resources.
    - High compute costs at Amazon’s scale.
    - Does not support real-time processing.
    - Replaces all data, which increases I/O load on both the source and the warehouse.
  - **Conclusion**: Full load is not practical for high-volume transactional systems at Amazon scale.

- **Incremental Load**:
  - **Definition**: Extracts only the changes (inserts, updates, deletes) that occurred since the last load.
  - **Two Options**:
    - **Batch-Based Incremental**:
      - Extracts data periodically based on timestamps or sequences.
      - **Pros**: 
        - Simple to implement.
        - Reduces I/O load compared to full loads.
      - **Cons**:
        - Delayed processing, not suitable for real-time applications.
        - Manual tracking of deleted records.
        - Large intervals between batches could result in missed data.
    - **Change Data Capture (CDC)**:
      - Tracks and extracts database changes in real-time via logs or triggers.
      - **Pros**:
        - Near real-time updates.
        - Minimal read overhead on the database, thanks to log-based capture.
        - No manual tracking for deletes, updates, and inserts—everything is automatically captured.
      - **Cons**:
        - Complex to implement, especially for distributed databases.
        - Requires access to transaction logs (e.g., Write-Ahead Logs in PostgreSQL) or triggers.
        - Higher operational complexity due to the need for continuous monitoring.

### Why CDC is the Best Choice ?
- **Scalability**: CDC captures changes incrementally, making it highly scalable for environments like Amazon, where millions of changes happen every minute.
- **Real-Time Processing**: CDC supports near real-time updates, which is crucial for use cases like order management, inventory tracking, and customer analytics at Amazon's operational scale.
- **No DB Locks**: Unlike traditional read queries, CDC doesn’t place additional read locks on the database, reducing contention in high-concurrency environments.
- **Write-Ahead Logs (WAL)**:
  - **How It Works**: CDC leverages transaction logs (e.g., PostgreSQL WAL), which record every database change. The logs are streamed without additional read overhead.
  - **Pros**:
    - No direct queries are run on the OLTP system.
    - No risk of database performance degradation.
  - **Cons**:
    - Access to logs requires additional setup and may not always capture all database operations.
- **Manual Coding Not Required**: CDC tools like **Amazon DMS** automate log capture and change processing, eliminating the need for custom scripts.

### Issues with Alternative Approaches
- **Batch-Based Incremental Loading**:
  - **Read Overhead**: Requires periodic scans of the entire table, introducing additional database load.
  - **Manual Handling of Deletes**: Requires custom logic to track and handle deleted records.
  - **Latency**: Not suitable for near real-time use cases due to fixed intervals between data pulls.
  
---

## Best Practices for Setting up CDC with Amazon DMS and S3 Staging

1. **Use Amazon DMS for CDC**:
   - **Why**: DMS supports log-based CDC for databases like PostgreSQL and can capture changes continuously without locking the database.
   - **CDC Method**: Log-based CDC (from WAL logs) provides a non-intrusive method for capturing changes, avoiding heavy database reads and minimizing overhead.
   - **Real-Time Sync**: Allows near real-time syncing to downstream systems.

2. **Push Changes to Amazon S3 as Staging**:
   - **Why Use S3**: S3 is highly scalable, cost-effective, and integrates seamlessly with the rest of the AWS ecosystem (e.g., Redshift, Glue).
   - **S3 as Staging**:
     - Allows storage of raw change data, which can be further processed before loading into the data warehouse.
     - Supports both structured and semi-structured data.
   - **Partitioning**: Partition S3 storage by time intervals (e.g., daily, hourly) to optimize query performance in downstream stages (e.g., Glue or Redshift).

3. **Schema and Data Evolution**:
   - Use **AWS Glue** Data Catalog to manage schema changes over time.
   - Ensure that downstream consumers (e.g., Redshift) are designed to handle schema drift in case new columns are added or data types are changed.

4. **CDC Monitoring and Error Handling**:
   - **CloudWatch Alarms**: Set up CloudWatch for DMS task monitoring to alert if there are failures, lag, or performance degradation.
   - **Checkpointing**: Implement checkpointing in DMS to ensure changes are only processed once and no data is lost in case of failure.
   - **Retries**: Set up automatic retries and rollback mechanisms to handle transient failures.
   
5. **Security**:
   - **Data Encryption**: Use server-side encryption (SSE) for S3 data to ensure sensitive data is protected at rest.
   - **Access Control**: Apply proper IAM policies to restrict access to the CDC pipeline and S3 storage.
   - **Data Masking**: Use data masking or anonymization for sensitive columns (e.g., personally identifiable information) before storing data in S3.

6. **High Availability (HA)**:
   - **Multi-AZ DMS Replication**: Configure DMS to use multi-AZ deployments for high availability.
   - **Redundancy**: Ensure data is replicated across multiple availability zones and back up CDC logs regularly.
   - **Failover Strategy**: Implement failover mechanisms in case of DMS instance failure, ensuring minimal downtime.

7. **Load into Data Warehouse**:
   - After transformation in S3, use **Amazon Redshift** for fast querying and analytics.
   - Use **COPY** command in Redshift to load data in parallel from S3 efficiently.
   - **Best Practice**: Use `MERGE` operations to apply changes (INSERT, UPDATE, DELETE) in Redshift, ensuring efficient incremental updates.

---

## Conclusion: Why CDC is the Best Choice

- **Real-Time Capability**: At Amazon's scale, real-time or near-real-time data is essential for operational decisions (e.g., order processing, customer behavior analytics). CDC enables this with minimal latency.
- **Efficient Resource Usage**: CDC extracts only the changes, reducing bandwidth, I/O load, and compute requirements compared to full or batch-based loads.
- **Database-Friendly**: CDC uses transaction logs (WAL) to capture changes without querying the database, ensuring the OLTP system remains performant with no additional read locks or overhead.
- **Scalable and Fault-Tolerant**: Using Amazon DMS in combination with S3 for staging and Redshift for querying provides a highly scalable architecture. With proper monitoring, error handling, and multi-AZ deployment, the pipeline is fault-tolerant and resilient to failures.

## Transform Section of ETL Pipeline

### 1. **Objective**

The transform stage focuses on applying necessary **data quality** checks and **transformations** as the data moves from the **raw source (S3)** to **staging tables** in **Amazon Redshift**. This stage ensures that the data is cleaned, validated, and transformed for downstream analytics and reporting.

### 2. **Key Components**

- **Data Quality**: Rules are applied to ensure the consistency and correctness of the data. Data quality checks can be defined at multiple stages (raw to staging, staging to dimensions, dimensions to facts).
- **Transformations**: Custom and SQL-based transformations are applied to enrich and format the data for analytics. This stage ensures that the data is aligned with the business rules.
- **Error Handling and Fault Tolerance**: The pipeline includes built-in error handling and retry mechanisms to ensure resiliency at Amazon scale.
  
### 3. **Workflow Overview**

1. **Source Data (S3)**: Parquet files generated by AWS DMS are stored in S3.
2. **Load Raw Data**: Parquet files are loaded from S3 into Spark.
3. **Data Quality Checks**: A set of quality rules are applied to ensure the integrity of the data. This includes null checks, data type validations, range checks, etc.
4. **Transformations**: Data is transformed to apply enrichment, formatting, and derived calculations, ensuring readiness for analytics.
5. **Staging Tables (Redshift)**: Transformed data is loaded into Redshift staging tables. The staging tables are truncated before each load to ensure a clean and complete data load.
6. **Preactions**: The Redshift table is truncated before loading data using the `preactions` parameter.
7. **Postactions (Optional)**: Post-load actions such as updates or final transformations can be triggered after data load.

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