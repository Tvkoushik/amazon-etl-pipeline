import json
from pyspark.sql import SparkSession
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.utils import getResolvedOptions
from pyspark.sql.functions import col
from glue_utils.data_quality import (
    apply_data_quality_checks,
)  # Assuming we reuse the existing data quality checks
from glue_utils.transformations import (
    apply_transformations,
)  # Assuming we reuse the existing transformations

# Initialize Glue context and Spark session
glueContext = GlueContext(SparkSession.builder.getOrCreate())
spark = glueContext.spark_session

# Load configuration file from S3
config_path = "dimensions_config.json"
config = json.loads(config_path)

# Iterate over each dimension table defined in the configuration
for table_config in config["dimension_tables"]:

    print(f"Processing {table_config['dimension_table']}...")

    # Load data from the staging table in Redshift
    staging_df = glueContext.create_dynamic_frame.from_catalog(
        database=table_config["target_database"],
        table_name=table_config["staging_table"],
        transformation_ctx=f'staging_{table_config["dimension_table"]}',
    ).toDF()

    # Apply data quality checks (SQL and DataFrame-based checks)
    staging_df = apply_data_quality_checks(
        staging_df, table_config["data_quality_rules"]
    )

    # Apply transformations (SQL and DataFrame-based transformations)
    staging_df = apply_transformations(staging_df, table_config["transformations"])

    # Convert back to DynamicFrame for Glue job
    staging_dynamic_frame = DynamicFrame.fromDF(
        staging_df,
        glueContext,
        f'staging_dynamic_frame_{table_config["dimension_table"]}',
    )

    # Write data to the Redshift temporary table using the provided preactions and postactions
    glueContext.write_dynamic_frame.from_jdbc_conf(
        frame=staging_dynamic_frame,
        catalog_connection=config["redshift_connection"],
        connection_options={
            "preactions": table_config[
                "preactions"
            ],  # Truncate staging table
            "dbtable": f"redshift_schema.stage_{table_config['dimension_table']}",  # Temporary staging table
            "postactions": table_config[
                "postactions"
            ],  # MERGE operation for SCD Type 2 or simple insert
        },
        redshift_tmp_dir=config["redshift_tmp_dir"],
        transformation_ctx=f'datasink_{table_config["dimension_table"]}',
    )

    print(f"Completed processing for {table_config['dimension_table']}.")
