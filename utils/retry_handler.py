import time
from utils.logger import logger


def retry(table_name, max_retries=3, backoff_factor=2):
    """
    Retry logic with exponential backoff in case of transient failures.

    Args:
        table_name (str): Name of the table that failed processing.
        max_retries (int): Maximum number of retries to attempt. Defaults to 3.
        backoff_factor (int): Multiplier to increase the backoff time after each failure. Defaults to 2.

    Returns:
        bool: True if the retry was successful, False otherwise.
    """
    retries = 0
    backoff_time = 1
    while retries < max_retries:
        try:
            # Attempt to reprocess the table
            logger.info(f"Retrying {table_name}... attempt {retries + 1}")
            return True
        except Exception as e:
            # Increment the retry count and calculate the new backoff time
            retries += 1
            backoff_time *= backoff_factor
            logger.error(
                f"Retry attempt {retries} failed for {table_name}, retrying in {backoff_time} seconds..."
            )
            # Sleep for the calculated backoff time
            time.sleep(backoff_time)

    # If we reach this point, max retries have been exceeded
    logger.error(f"Max retries reached for {table_name}. Aborting.")
    return False
