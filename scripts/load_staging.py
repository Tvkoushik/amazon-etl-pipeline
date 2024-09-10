import json
from awsglue.context import GlueContext
from pyspark.sql import SparkSession
from utils.data_quality import apply_data_quality_checks
from utils.transformations import apply_transformations
from utils.retry_handler import retry
from utils.logger import logger

# Initialize Glue context and Spark session
glueContext = GlueContext(SparkSession.builder.getOrCreate())
spark = glueContext.spark_session

# Load the configuration file for staging
with open("configs/staging_config.json", "r") as config_file:
    config = json.load(config_file)

# Process each staging table defined in the configuration
for table in config["staging_tables"]:
    try:
        # Step 1: Load raw parquet data from S3
        logger.info(f"Loading parquet files from {table['source']}...")
        raw_df = spark.read.parquet(table["source"])

        # Step 2: Apply data quality checks (from utils/data_quality.py)
        cleaned_df = apply_data_quality_checks(raw_df, table["data_quality_rules"])

        # Step 3: Apply transformations (from utils/transformations.py)
        transformed_df = apply_transformations(cleaned_df, table["transformations"])

        # Step 4: Load the transformed data into Redshift staging table with `preactions` to truncate the table
        logger.info(
            f"Loading data into Redshift table: {table['target_table']}, and truncating it before loading..."
        )
        glueContext.write_dynamic_frame.from_jdbc_conf(
            frame=glueContext.create_dynamic_frame.from_catalog(
                database=table["target_database"],
                table_name=table["source"].split("/")[-1],
            ),
            catalog_connection="redshift_connection",
            connection_options={
                "preactions": f"truncate table {table['target_table']};",
                "dbtable": table["target_table"],
                "database": table["target_database"],
            },
            redshift_tmp_dir="s3://your-temp-directory/",
            transformation_ctx=f"datasink_{table['target_table']}",
        )
    except Exception as e:
        logger.error(f"Error loading {table['target_table']}: {str(e)}")
        retry(table["target_table"])
