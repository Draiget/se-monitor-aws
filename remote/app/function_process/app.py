import boto3
import logging
import json
import crhelper
import requests
import datetime
from datetime import datetime
import valve.source.master_server
from botocore.exceptions import ClientError

import shared

logger = logging.getLogger(__name__)
helper = crhelper.CfnResource(json_logging=True, log_level='DEBUG')


def handle_fetch_servers(regions, gamedir, map=''):
    db = boto3.resource('dynamodb')

    with valve.source.master_server.MasterServerQuerier() as msq:
        servers = msq.find(
            region=regions,
            duplicates="skip",
            gamedir=gamedir,
            map=map,
        )

        servers_table = db.Table('servers')
        for host, port in servers:
            try:
                response = servers_table.get_item(Key={'Ip': host, 'Port': port})
                if response is None:
                    servers_table.put_item(Item={
                        'Ip': host,
                        'Port': port,
                        'TimeFirstFetched': datetime.now().timestamp()
                    })
            except ClientError as e:
                return {
                    "error": True,
                    "message": f'Unable to add server entry into db: {e}'
                }

        return {"error": False, "data": 'Fetched %s servers' % len(list(servers))}


def lambda_handler(event, _):
    logger.info('Initializing master server processor')

    if 'body' not in event:
        return {"error": True, "message": 'Request body is not set'}

    body = json.loads(event['body'])

    if 'action' not in body:
        return {"error": True, "message": 'Request action is not set in the body'}

    action = body['action']
    if action == 'fetch':
        return handle_fetch_servers(body.get('regions', ["eu"]), body.get('game', 'garrysmod'), body.get('map', ''))

    return {"error": False, "message": 'ok'}
