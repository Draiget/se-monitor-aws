import boto3
import logging
import json
import crhelper
import datetime
from datetime import datetime
import valve.source.master_server
import valve.source.a2s
from botocore.exceptions import ClientError

import shared

logger = logging.getLogger(__name__)
helper = crhelper.CfnResource(json_logging=True, log_level='DEBUG')


def handle_fetch_servers(regions, gamedir, lookup_player, map=''):
    db = boto3.resource('dynamodb')
    logger.info('Starting fetching servers from master')

    response_data = {}

    with valve.source.master_server.MasterServerQuerier() as msq:
        servers = msq.find(
            region=regions,
            duplicates="skip",
            gamedir=gamedir,
            map=map,
        )

        # servers_table = db.Table('servers')

        servers_count = 0
        player_found = False

        for host, port in servers:
            server_ip_port = f'{host}:{port}'
            servers_count += 1
            """
            try:
                response = servers_table.get_item(Key={'ServerIp': server_ip_port})
                if response is None:
                    servers_table.put_item(Item={
                        'ServerIp': server_ip_port,
                        'Data': {
                            'Fetched': datetime.now().timestamp()
                        }
                    })
            except ClientError as e:
                return {
                    "error": True,
                    "message": f'Unable to add server entry into db: {e}',
                    "fetched": servers_count,
                }
            """

            logger.info('Querying server %s ...' % server_ip_port)
            with valve.source.a2s.ServerQuerier((host, port)) as server:
                # Info broken: https://github.com/serverstf/python-valve/issues/48
                # info = server.info()
                players = list({"name": x["name"], "duration": x["duration"]} for x in server.players()["players"])

                for player in players:
                    if not player_found and player["name"] == lookup_player:
                        logger.info('Target player %s found on server %s' % (lookup_player, server_ip_port))
                        response_data = {
                            "server": server_ip_port,
                            # "title": info["server_name"],
                            "players": players
                        }

        return {
            "error": False,
            "fetched": servers_count,
            "result": response_data,
        }


def lambda_handler(event, _):
    logger.info('Initializing master server processor')

    if 'player' not in event:
        return shared.reply_err('Player name is not set in request query')

    """
    'regions': query.get('regions', ["eu"]),
    'game': query.get('game', 'garrysmod'),
    'map': query.get('map', ''),
    'player': query['player']
    """

    return handle_fetch_servers(
        regions=event.get('regions', ["eu"]),
        gamedir=event.get('game', 'garrysmod'),
        lookup_player=event['player'],
        map=event.get('map', ''))
