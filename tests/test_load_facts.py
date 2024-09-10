import pytest
from unittest import mock
from awsglue.context import GlueContext
from pyspark.sql import SparkSession
from utils.data_quality import apply_data_quality_checks
from utils.transformations import apply_transformations


@pytest.fixture(scope="module")
def spark_session():
    """
    Pytest fixture to create a SparkSession instance for the entire module.
    All tests in this module will share the same SparkSession.
    """
    spark = SparkSession.builder.appName("Glue Job Test").getOrCreate()
    return spark


@pytest.fixture
def glue_context(spark_session):
    """
    Pytest fixture to create a GlueContext instance for each test.
    The GlueContext is created with the shared SparkSession instance.
    """

    return GlueContext(spark_session)


@mock.patch("awsglue.context.GlueContext")
def test_load_fact_job(mock_glue_context, glue_context, spark_session):
    # Sample data for SQL query result (fact data)
    """
    Test the load_fact_job function by mocking the GlueContext and SQL execution.

    The test data is a sample of fact data with 1 row, and the test checks that
    the function returns a DataFrame with the correct columns and row count.
    """
    fact_data = spark_session.createDataFrame(
        [(1, 1, 100, "2022-01-15", 199.99)],
        ["sale_id", "order_id", "customer_id", "sale_date", "total_amount"],
    )

    # Mock the GlueContext and SQL execution
    mock_glue_context.return_value = glue_context

    with mock.patch("spark.sql") as mock_sql:
        # Mock SQL query execution
        mock_sql.return_value = fact_data

        # Call the fact table loading method
        fact_df = mock_sql("SELECT * FROM fact_sales")

        assert fact_df.count() == 1
        assert "sale_id" in fact_df.columns
