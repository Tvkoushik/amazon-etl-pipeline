import pytest
from unittest import mock
from awsglue.context import GlueContext
from pyspark.sql import SparkSession
from utils.data_quality import apply_data_quality_checks
from utils.transformations import apply_transformations


@pytest.fixture(scope="module")
def spark_session():
    """
    Provides a SparkSession instance for the entire module.
    All tests in this module will share the same SparkSession.
    """
    spark = SparkSession.builder.appName("Glue Job Test").getOrCreate()
    return spark


@pytest.fixture
def glue_context(spark_session):
    """
    Provides a GlueContext instance for the entire module.
    All tests in this module will share the same GlueContext.
    """
    return GlueContext(spark_session)


@mock.patch("awsglue.context.GlueContext")
def test_load_dimension_job(mock_glue_context, glue_context, spark_session):
    # Sample staging data
    """
    Test the load dimension job by mocking the data quality and transformation functions.
    Assert that the transformations are applied and the output DataFrame has the expected columns and count.
    """
    staging_data = spark_session.createDataFrame(
        [(1, "John", "Doe", "2022-01-15"), (2, "Jane", "Smith", "2022-02-01")],
        ["customer_id", "first_name", "last_name", "account_creation_date"],
    )

    # Create DynamicFrame from staging data
    staging_dynamic_frame = glue_context.create_dynamic_frame.fromDF(
        staging_data, glue_context, "test_dynamic_frame"
    )

    # Mocking the data quality and transformation functions
    mock_glue_context.return_value = glue_context

    with mock.patch(
        "utils.data_quality.apply_data_quality_checks"
    ) as mock_quality_check:
        with mock.patch(
            "utils.transformations.apply_transformations"
        ) as mock_transform:
            # Call the dimension Glue job method directly
            cleaned_df = apply_data_quality_checks(staging_data, {})
            transformed_df = apply_transformations(cleaned_df, {})

            # Ensure transformations are applied
            mock_quality_check.assert_called()
            mock_transform.assert_called()

            assert "customer_id" in transformed_df.columns
            assert transformed_df.count() == 2
