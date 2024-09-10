# AWS Data Pipeline - Comprehensive Overview

## Table of Contents
1. [Introduction](#introduction)
2. [Architecture Overview](#architecture-overview)
3. [Extract](#extract)
4. [Transform](#transform)
5. [Load](#load)
6. [Monitoring and Orchestration](#monitoring-and-orchestration)
7. [Governance and Security](#governance-and-security)
8. [Visualization](#visualization)

---

## Introduction
This document explains the end-to-end AWS-based ETL pipeline built to ingest, transform, and load data into Amazon Redshift for analytics. It describes each step of the process, the AWS services used, the decisions made, and best practices employed to handle large-scale data ingestion and analytics for real-time processing.

---

## Architecture Overview
The ETL pipeline follows a structured approach, using the following key AWS components:

- **Amazon RDS (PostgreSQL)**: As the source transactional database.
- **AWS DMS**: For Change Data Capture (CDC) to continuously capture changes from PostgreSQL.
- **Amazon S3**: For storing raw data and staging data in Parquet format.
- **AWS Glue**: For data transformation and applying data quality checks before loading into Redshift.
- **Amazon Redshift**: As the data warehouse, hosting both staging tables and dimension/fact tables.
- **AWS Step Functions**: For orchestrating the Glue jobs and managing execution order.
- **Amazon QuickSight**: For data visualization and creating dashboards.
- **AWS Lakeformation**: For Data Governance.
- **AWS IAM**: For Access Management

---

## Extract

### Why Use CDC for Data Ingestion?

Amazon's operational scale requires efficient real-time data ingestion. **Change Data Capture (CDC)** is chosen because:

- **Real-Time Processing**: It captures incremental changes (inserts, updates, deletes) in real-time.
- **Efficiency**: CDC extracts only changes, reducing I/O and bandwidth compared to full load or batch-based methods.
- **No Database Locks**: Unlike batch-based incremental loading, CDC doesn’t place additional read locks on the database, minimizing impact on OLTP performance.

### CDC with Amazon DMS
- **Amazon DMS** is used to capture changes from PostgreSQL. It streams data to S3 in **Parquet** format, optimized for storage and query performance.
- **S3 Partitioning**: Data is partitioned by time (e.g., hourly/daily) to facilitate efficient querying.

**Best Practices**:
- Use **Amazon DMS** in **Multi-AZ** configuration to ensure high availability.
- Monitor DMS tasks with **CloudWatch** to detect failures and track replication lag.
- **Encryption**: Use server-side encryption (SSE) for S3 and **KMS** for Redshift.

---

## Transform

### Objective
The transformation stage cleanses and enriches data, ensuring it adheres to business rules and is ready for analytics.

### Key Components
- **Data Quality Checks**: Applied at multiple stages to ensure consistency (null checks, date validation, etc.).
- **Transformations**: SQL-based or DataFrame transformations (using Spark) are applied to format data for downstream use.
- **Config-Driven Architecture**: The pipeline is config-driven, allowing flexibility in defining quality rules and transformations for each table.

### Workflow Overview
1. **Raw Data Load**: Parquet files from S3 are read into Spark using Glue.
2. **Data Quality**: Defined checks are applied to ensure data validity.
3. **Transformations**: The data is transformed and enriched as per the business rules.
4. **Staging**: The transformed data is loaded into Redshift **staging tables** using a truncate-and-load approach.

**Best Practices**:
- **Glue Bookmarks**: Used to track processed files and ensure incremental loading.
- **Cluster Settings**: Optimize Glue cluster and Spark job settings for efficient processing.
- **Glue Retry Mechanism**: Configured to handle transient failures by retrying the job up to 3 times.

---

## Load

### Objective
Load data from staging tables to dimension and fact tables in Redshift, with support for **Slowly Changing Dimensions (SCD Type 2)**.

### Dimension Loading
- **SCD Type 2** logic is implemented using **MERGE** statements in Redshift. CDC flags (`I`, `U`, `D`) are processed, and records are either inserted or updated based on the change type.
- Each dimension table tracks historical changes by maintaining an `effective_date` and `expiry_date`, with active records marked using an `is_current_record` flag.

### Fact Loading
- Fact tables follow an **append-only** strategy. Each fact table stores transactional data (e.g., orders, sales), and no updates are required. To prevent duplication, any partially loaded data due to failed jobs is cleaned up using **preactions**.

### Workflow Overview
1. **Load Staging Data**: Data from the staging tables is merged into dimension tables.
2. **Fact Table Load**: Data is appended from staging tables into fact tables.
3. **No Duplicates**: Preactions remove any partially loaded data before appending new records.

**Best Practices**:
- **Redshift Distribution & Sort Keys**: Ensure efficient query performance by setting appropriate **DISTKEY** and **SORTKEY** based on query patterns.
- **Compression**: Use **ZSTD** compression for optimal storage and performance.

---

## Monitoring and Orchestration

### AWS Step Functions
- **Step Functions** orchestrate the ETL pipeline, ensuring that Glue jobs are executed in sequence: first the **staging tables**, then the **dimensions**, and finally the **fact tables**.

### CloudWatch Monitoring
- **CloudWatch Logs** and **Alarms** are configured to monitor Glue job execution, track failures, and send alerts for manual intervention if necessary.
- **Error Handling**: Any failures trigger retries automatically before alerts are sent.

**Best Practices**:
- **Step Functions State Machine**: Includes retries and conditional checks to handle different failure scenarios.
- **Glue Job Metrics**: Monitor job run times and memory usage to ensure optimal performance.

---

## Governance and Security

### IAM and Access Control
- **IAM Roles** are configured following the principle of least privilege, ensuring only necessary services and users have access to sensitive data.
- **AWS Lake Formation** is used for row/column-level security in Redshift, ensuring compliance with data access policies.

### Data Encryption
- Data at rest in **S3** and **Redshift** is encrypted using **SSE** and **KMS** keys to ensure data protection.
- **Data Masking** is applied where required (e.g., masking personally identifiable information).

**Best Practices**:
- **IAM Policies**: Fine-grained policies are applied for access control to S3, Glue, and Redshift.
- **Compliance**: Ensure compliance with industry security standards such as GDPR by implementing proper encryption and access control mechanisms.

---

## Visualization

### Amazon QuickSight
- **QuickSight** is used for visualizing the analytics stored in Redshift. Dashboards are created to display:
  1. **Product Trends**: Track growth and depreciation trends in product sales month-over-month.
  2. **Seller Behavior**: Categorize sellers into high, medium, and low buckets based on service quality (e.g., returns and refunds).
  3. **Consumer Statistics**: Study consumer behavior in terms of spending, transaction counts, and refunds.

**Best Practices**:
- **SPICE Storage**: Utilize **QuickSight’s SPICE** in-memory engine to accelerate dashboard performance for large datasets.

---