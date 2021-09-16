import boto3
import logging
import json
import crhelper
import requests
import datetime
from datetime import datetime
import valve.source.master_server


logger = logging.getLogger(__name__)
helper = crhelper.CfnResource(json_logging=True, log_level='DEBUG')
db = boto3.resource('dynamodb')


@helper.poll_create
@helper.poll_update
@helper.poll_delete
def poll_operation(event, _):
    return {}


@helper.create
def create(event, _c):
    logger.info('Initializing master-server scanning')
    target_ms_region = event['ResourceProperties']['ScanRegion']

    helper.Data.update({
        'StartTimestamp': str(datetime.now().timestamp()),
        'Args': {
            'Region': target_ms_region
        }
    })


def lambda_handler(event, context):
    helper(event, context)
