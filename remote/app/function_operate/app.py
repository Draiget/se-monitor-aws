import boto3
import logging
import json

import shared

logger = logging.getLogger(__name__)


def lambda_handler(event, _):
    logger.info('Initializing operate instructions (event = %s)' % event)

    if 'body' not in event:
        return shared.reply_err(message='Request body is not set')

    # API GW transforms query to a string, so let's check it and convert accordingly
    if isinstance(event['body'], str):
        body = json.loads(event['body'])
    else:
        body = event['body']

    # Require action in body to detect future action
    if 'action' not in body:
        return shared.reply_err(message='Request action is not set in the body')

    action = body['action']

    # TODO: Flask integration will be more useful if future API will expand
    if action == 'find':
        query = body['query']

        if 'player' not in query:
            return shared.reply_err(message='Player name is not set in the request')

        client = boto3.client('lambda')

        # Invoke processing lambda to find desired player
        process_response = client.invoke(
            FunctionName='sm-process',
            InvocationType='RequestResponse',
            Payload=json.dumps({
                'regions': query.get('regions', ["eu"]),
                'game': query.get('game', 'garrysmod'),
                'map': query.get('map', ''),
                'player': query['player']
            })
        )

        return shared.reply(response=process_response['Payload'].read().decode())

    return shared.reply(response='Unknown action, skipping')
