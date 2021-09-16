import boto3
import json
from botocore.errorfactory import ClientError
from botocore.client import Config


def get_operational_state(bucket_name, client=None):
    if client is None:
        client = boto3.client('s3', config=Config(connect_timeout=30, retries={'max_attempts': 2}))

    try:
        s3_response_object = client.get_object(Bucket=bucket_name, Key='state')
        body = s3_response_object['Body'].read().decode(encoding='utf-8', errors='ignore')
        if body is not None and len(body) > 0:
            return {"error": False, "data": json.loads(body)}
    except ClientError as e:
        return {"error": True, "message": e}

    return {"error": False, "data": {}}


def update_operational_state(bucket_name, state, client=None):
    if client is None:
        client = boto3.client('s3', config=Config(connect_timeout=30, retries={'max_attempts': 2}))

    try:
        response = client.put_object(
            Bucket=bucket_name,
            Body=json.dumps(state),
            Key='state'
        )

        return {"error": False, "message": f'Operational state has been updated, status = {response}'}
    except ClientError as e:
        return {"error": True, "message": 'Unable to retrieve operational state [%s]: %s' %
                                          (e.response['Error']['Code'], e.response['Error']['Message'])}
