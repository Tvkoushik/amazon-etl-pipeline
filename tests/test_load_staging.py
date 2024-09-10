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
def test_load_staging_job(mock_glue_context, glue_context, spark_session):
    # Sample raw data
    raw_data = spark_session.createDataFrame(
        [
            (1, "John", "Doe", "john.doe@example.com", "2022-01-15"),
            (2, "Jane", "Smith", "jane.smith@example.com", "2022-02-01"),
        ],
        ["customer_id", "first_name", "last_name", "email", "account_creation_date"],
    )

    # Create DynamicFrame from raw data
    raw_dynamic_frame = glue_context.create_dynamic_frame.fromDF(
        raw_data, glue_context, "test_dynamic_frame"
    )

    # Mocking the data quality and transformation functions
    mock_glue_context.return_value = glue_context

    with mock.patch(
        "utils.data_quality.apply_data_quality_checks"
    ) as mock_quality_check:
        with mock.patch(
            "utils.transformations.apply_transformations"
        ) as mock_transform:
            # Call the staging Glue job method directly, testing the logic
            cleaned_df = apply_data_quality_checks(raw_data, {})
            transformed_df = apply_transformations(cleaned_df, {})

            # Ensure transformations are called
            mock_quality_check.assert_called()
            mock_transform.assert_called()

            assert "first_name" in transformed_df.columns
