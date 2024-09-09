from pyspark.sql import functions as F
from utils.logger import logger


def apply_data_quality_checks(df, dq_rules):
    """
    Apply data quality rules based on SQL or DataFrame API.

    Args:
        df (pyspark.sql.DataFrame): DataFrame to apply data quality checks on
        dq_rules (dict): Dictionary of data quality rules
    """
    # Apply SQL-based checks
    if "sql_checks" in dq_rules:
        for sql_query in dq_rules["sql_checks"]:
            # Create a temporary view of the DataFrame
            df.createOrReplaceTempView("df")
            # Apply the SQL query to the temporary view
            df = df.sql(sql_query)
            logger.info(f"Applied SQL data quality check: {sql_query}")
            # Can send an alert or fail the job or send the data to another table if the data quality check fails

    # Apply DataFrame API-based checks
    if "dataframe_checks" in dq_rules:
        if "check_not_null" in dq_rules["dataframe_checks"]:
            for col_name in dq_rules["dataframe_checks"]["check_not_null"]:
                # Filter out rows where the column is NULL
                df = df.filter(F.col(col_name).isNotNull())
                logger.info(f"Applied NOT NULL check on column: {col_name}")
                # Can send an alert or fail the job or send the data to another table if the data quality check fails

        if "check_positive" in dq_rules["dataframe_checks"]:
            for col_name in dq_rules["dataframe_checks"]["check_positive"]:
                # Filter out rows where the column is not positive
                df = df.filter(F.col(col_name) > 0)
                logger.info(f"Applied POSITIVE check on column: {col_name}")
                # Can send an alert or fail the job or send the data to another table if the data quality check fails

        if "check_valid_date" in dq_rules["dataframe_checks"]:
            for col_name in dq_rules["dataframe_checks"]["check_valid_date"]:
                # Filter out rows where the column is not a valid date
                df = df.filter(F.col(col_name).cast("date").isNotNull())
                logger.info(f"Applied VALID DATE check on column: {col_name}")
                # Can send an alert or fail the job or send the data to another table if the data quality check fails

    return df
