import boto3
import json


def reply_err(response=None, message=None):
    return reply(error=True, error_message=message)


def reply(error=False, response=None, error_message=None):
    data = {
        "isBase64Encoded": False,
        "statusCode": 503 if error else 200,
        "headers": {},
        "body": {
            "error": error,
        }
    }

    if error:
        data['body']['message'] = error_message

    if response:
        if isinstance(response, dict):
            data['body'] = {**data['body'], **response}
        else:
            data['body'] = response

    return data
