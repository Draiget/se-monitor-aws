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


@helper.create
def create(event, _c):
    logger.info('Test')
    return {}


def lambda_handler(event, context):
    helper(event, context)
