import boto3
import logging
import json
from botocore.errorfactory import ClientError
from botocore.client import Config

logger = logging.getLogger(__name__)


def create_table(db, table_name, schema):
    """
    Creates an Amazon DynamoDB table with the specified schema.
    From: https://docs.aws.amazon.com/code-samples/latest/catalog/python-dynamodb-batching-dynamo_batching.py.html

    :param table_name: The name of the table.
    :param schema: The schema of the table. The schema defines the format
                   of the keys that identify items in the table.
    :return: The newly created table.
    """
    try:
        table = db.create_table(
            TableName=table_name,
            KeySchema=[{
                'AttributeName': item['name'], 'KeyType': item['key_type']
            } for item in schema],
            AttributeDefinitions=[{
                'AttributeName': item['name'], 'AttributeType': item['type']
            } for item in schema],
            ProvisionedThroughput={'ReadCapacityUnits': 10, 'WriteCapacityUnits': 10}
        )
        table.wait_until_exists()
        logger.info("Created table %s.", table.name)
    except ClientError:
        logger.exception("Couldn't create movie table.")
        raise
    else:
        return table
