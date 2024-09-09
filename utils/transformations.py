from utils.logger import logger

def apply_transformations(df, transformation_rules):
    """
    Apply transformation rules based on SQL or DataFrame API.

    The transformation rules are applied in order, and are split into two categories:
    - SQL-based transformations: applied using the Spark SQL API
    - DataFrame API-based transformations: applied using the PySpark DataFrame API

    :param df: Spark DataFrame to apply the transformations to
    :param transformation_rules: dictionary of transformation rules
    :return: transformed DataFrame
    """
    # Apply SQL-based transformations
    if "sql_transforms" in transformation_rules:
        for sql_query in transformation_rules["sql_transforms"]:
            df.createOrReplaceTempView("df")
            df = df.sql(sql_query)
            logger.info(f"Applied SQL transformation: {sql_query}")

    # Apply DataFrame API-based transformations
    if "dataframe_transforms" in transformation_rules:
        for transform in transformation_rules["dataframe_transforms"]:
            # This assumes the transformation logic is a Python statement
            # The exec() function parses the expression passed to this method and executes Python expression(s) passed as a string
            exec(transform["transform"])
            logger.info(f"Applied DataFrame transformation: {transform['transform']}")
    
    return df
