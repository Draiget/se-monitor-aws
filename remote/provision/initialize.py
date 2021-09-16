import argparse
import boto3
import botocore
import os
import re
from os import environ

parser = argparse.ArgumentParser(description='Infrastructure provision helper')
parser.add_argument('-sb', '--state-bucket',
                    dest='state_bucket',
                    help='Unique text which will be used as name for Terraform state bucket',
                    required=True)

if __name__ == "__main__":
    args = parser.parse_args()

    if not environ.get('AWS_KEY_ID') is not None and not environ.get('AWS_KEY_ID') and \
       not environ.get('AWS_KEY_SECRET') is not None and not environ.get('AWS_KEY_SECRET'):
        s3_client = boto3.client(
            's3',
            aws_access_key_id=os.environ['AWS_KEY_ID'],
            aws_secret_access_key=os.environ['AWS_KEY_SECRET']
        )
    else:
        if not os.path.isfile('~/.aws/credentials'):
            os.system('aws configure')

        s3_client = boto3.client('s3')

    try:
        s3_client.create_bucket(Bucket=args.state_bucket)
        s3_client.put_public_access_block(
            Bucket=args.state_bucket,
            PublicAccessBlockConfiguration={
                'BlockPublicAcls': True,
                'IgnorePublicAcls': True,
                'BlockPublicPolicy': True,
                'RestrictPublicBuckets': True
            },
        )

        s3_client.put_bucket_versioning(
            Bucket=args.state_bucket,
            VersioningConfiguration={
                'Status': 'Enabled'
            },
        )
    except botocore.exceptions.ClientError as error:
        print(f'Error creating state bucket: {error}')
        exit(1)

    print(f'State bucket "{args.state_bucket}" successfully created!')

    f = open("/var/tf/main.tf", "r")
    content = f.read()
    f.close()

    f = open("/var/tf/main.tf", "w")
    f.write(re.sub('(backend\ \"s3\"\ {)*(bucket\s=\s\")([a-zA-Z0-9-]+)(\")', r'\1\2%s\4' % args.state_bucket, content))
    f.close()
    print(f'Backend bucket set in main.tf')
