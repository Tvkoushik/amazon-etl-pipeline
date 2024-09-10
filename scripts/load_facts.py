import json
import sys
from pyspark.sql import SparkSession
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from awsglue.dynamicframe import DynamicFrame

# Initialize Glue context and Spark session
glueContext = GlueContext(SparkSession.builder.getOrCreate())
spark = glueContext.spark_session


# Function to write the fact table to Redshift
def write_fact_table_to_redshift(fact_df, fact_table, preactions):
    """
    Write the fact table data to Redshift.

    Args:
        fact_df (DataFrame): Data for the fact table
        fact_table (str): Name of the fact table
        preactions (str): SQL preactions to run before loading the data

    Returns:
        None
    """
    fact_dynamic_frame = DynamicFrame.fromDF(
        fact_df, glueContext, f"dynamic_frame_{fact_table}"
    )

    glueContext.write_dynamic_frame.from_jdbc_conf(
        frame=fact_dynamic_frame,
        catalog_connection="your_redshift_connection",
        connection_options={
            "preactions": preactions,
            "dbtable": f"redshift_schema.{fact_table}",
        },
        redshift_tmp_dir="s3://your-temp-dir/",
        transformation_ctx=f"datasink_{fact_table}",
    )


# Load configuration file from S3 and process each fact table
config_path = "facts_config.json"
config = json.loads(config_path)

# Process each fact table based on the config
for fact_config in config["fact_tables"]:

    print(f"Processing {fact_config['fact_table']}...")

    # Prepare SQL query for loading fact data
    load_query = fact_config["load_query"]

    # Execute the SQL query to load data into the fact table
    fact_df = spark.sql(load_query)

    # Write fact data to Redshift
    write_fact_table_to_redshift(
        fact_df=fact_df,
        fact_table=fact_config["fact_table"],
        preactions=fact_config["preactions"],
    )

    print(f"Completed processing for {fact_config['fact_table']}.")
