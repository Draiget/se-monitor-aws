import boto3
import json
from botocore.errorfactory import ClientError
from botocore.client import Config


def reply_err(body=None, message=None):
    return reply(error=True, error_message=message)


def reply(error=False, body=None, error_message=None):
    if not error:
        return {"error": error, "body": body}

    return {"error": error, "message": '' if not error_message else error_message}
