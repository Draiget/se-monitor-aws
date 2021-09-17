import boto3
import logging
import datetime
from datetime import datetime
from boto3.dynamodb.conditions import Key
import valve.source.master_server
import valve.source.a2s
from botocore.exceptions import ClientError

import shared

logger = logging.getLogger(__name__)


def convert_server_players(server):
    """
    Converts python-valve iterator to regular list

    :param server: Server object
    :return: List with player data
    """
    return list({"name": x["name"], "duration": x["duration"]} for x in server.players()["players"])


def cache_create_player(server_ip_port, player_data, players_table, message=None):
    """
    Create player cache entry in DynamoDB

    :param server_ip_port: Server where player was found
    :param player_data: Player data object (with name, duration)
    :param players_table: Boto3 table object for players
    :param message: Override for error message
    :return: Error object or None in case if creation was completed successfully
    """
    try:
        players_table.put_item(Item={
            'IpPort': server_ip_port,
            'Name': player_data["name"],
            'TimeLastOnline': int(datetime.now().timestamp()),
            'PlayTime': int(player_data["duration"])
        })
    except ClientError as e:
        return {
            "error": True,
            "message": f'{message}, error: {e}',
            "player": player_data["name"],
            "server": server_ip_port
        }
    return None


def cache_update_player(server_ip_port, player_data, players_table, message=None):
    """
    Updates player cache entry in DynamoDB

    :param server_ip_port: Server where player was found
    :param player_data: Player data object (with name, duration)
    :param players_table: Boto3 table object for players
    :param message: Override for error message
    :return: Error object or None in case if update was completed successfully
    """
    current_time = int(datetime.now().timestamp())
    try:
        logger.info('Updating player "%s" cache entry' % player_data["name"])
        players_table.update_item(
            Key={
                'Name': str(player_data["name"])
            },
            UpdateExpression="set IpPort=:i, TimeLastOnline=:t, PlayTime=:p",
            ExpressionAttributeValues={
                ':i': server_ip_port,
                ':t': current_time,
                ':p': int(player_data["duration"])
            },
            ReturnValues="UPDATED_NEW"
        )
    except ClientError as e:
        return {
            "error": True,
            "message": f'{message}, error: {e}',
            "player": player_data["name"],
            "server": server_ip_port
        }
    return None


def handle_find_player_cached(players_table, servers_table, lookup_player):
    """
    Lookup player in DynamoDB cache and update entries if necessary

    :param players_table: Boto3 table object for players
    :param servers_table: Boto3 table object for servers
    :param lookup_player: Name of the player which we're looking for
    :return: Response object with error or resulting data
    """
    player_cached = None

    try:
        response = players_table.query(
            KeyConditionExpression=Key('Name').eq(lookup_player)
        )

        # Lookup most recent cached player entry by time seen on a server
        if response is not None and response.get('Items', None) is not None:
            for ply_item in response['Items']:
                if player_cached is None:
                    player_cached = ply_item
                    continue

                # Find most recent player checking it's last online time
                if 'TimeLastOnline' in ply_item and player_cached['TimeLastOnline'] > ply_item['TimeLastOnline']:
                    player_cached = ply_item

    except ClientError as e:
        return {
            "error": True,
            "message": f'Unable to lookup player cache from db, error: {e}'
        }

    # Check if entry is actual and update/remove it if need
    if player_cached is not None:
        logger.info('Player "%s" found in cache' % lookup_player)
        cached_server_endpoint = player_cached['IpPort'].split(':')

        # Query server we found in cache and check whenever target player are still there, that
        # we can update both player and server cache entries
        with valve.source.a2s.ServerQuerier((cached_server_endpoint[0], int(cached_server_endpoint[1]))) as server:
            logger.info('Updating server "%s" cache' % player_cached['IpPort'])

            # Update server cache entry
            servers_table.update_item(
                Key={'IpPort': player_cached['IpPort']},
                UpdateExpression="set TimeLastOnline=:t",
                ExpressionAttributeValues={
                    ':t': int(datetime.now().timestamp()),
                },
                ReturnValues="UPDATED_NEW"
            )

            players = convert_server_players(server)
            for player in players:
                # Target player are still playing here
                if player["name"] == lookup_player:
                    # Update player cache entry
                    err = cache_update_player(
                        server_ip_port=player_cached['IpPort'],
                        player_data=player,
                        players_table=players_table,
                        message="Unable to update player cache entry")
                    if err is not None:
                        return err

                    return {
                        "server": player_cached['IpPort'],
                        # "title": info["server_name"],
                        "players": players
                    }

    return None


def handle_find_player_online(players_table, servers_table, regions, gamedir, lookup_player, map=''):
    """
    Lookup player on all servers matching our filter properties, like map, game, region, etc.

    :param players_table: Boto3 table object for players
    :param servers_table: Boto3 table object for servers
    :param regions: Master server regions filter
    :param gamedir: Master server gamedir filter, which means a particular game
    :param lookup_player: Name of the player which we're looking for
    :param map: Master server map filter
    :return: Response object with error or resulting data
    """
    with valve.source.master_server.MasterServerQuerier() as msq:
        # Perform master server find query with specific filter options/properties
        servers = msq.find(
            region=regions,
            duplicates="skip",
            gamedir=gamedir,
            map=map,
        )

        servers_count = 0
        player_found = False

        # Look thought each server in resulting iterator object
        for host, port in servers:
            server_ip_port = f'{host}:{port}'
            servers_count += 1

            try:
                # Lookup cache entry for server in DynamoDB
                response = servers_table.get_item(Key={'IpPort': server_ip_port})
                if response is not None:
                    if response.get('Item', None) is None:
                        # Create new cache entry for server as it firstly seen or was removed from cache by TTL
                        servers_table.put_item(Item={
                            'IpPort': server_ip_port,
                            'TimeLastOnline': int(datetime.now().timestamp())
                        })
                    else:
                        # Update server cache entry
                        servers_table.update_item(
                            Key={
                                'IpPort': server_ip_port,
                            },
                            UpdateExpression="set TimeLastOnline=:t",
                            ExpressionAttributeValues={
                                ':t': int(datetime.now().timestamp())
                            },
                            ReturnValues="UPDATED_NEW"
                        )
            except ClientError as e:
                return {
                    "error": True,
                    "message": f'Unable to add server entry into db: {e}',
                    "fetched": servers_count,
                }

            # Perform query to current game server we're got from Master Server and check online players
            logger.info('Querying server %s ...' % server_ip_port)
            with valve.source.a2s.ServerQuerier((host, port)) as server:
                # Info broken: https://github.com/serverstf/python-valve/issues/48
                # info = server.info()
                players = convert_server_players(server)

                for player in players:
                    # Create new player cache entry in DynamoDB
                    err = cache_create_player(
                        server_ip_port=server_ip_port,
                        player_data=player,
                        players_table=players_table,
                        message="Unable to add new player cache entry")
                    if err is not None:
                        return err

                    # Stop looking for more servers once player was found
                    if not player_found and player["name"] == lookup_player:
                        logger.info('Target player %s found on server %s' % (lookup_player, server_ip_port))
                        return {
                            "server": server_ip_port,
                            # "title": info["server_name"],
                            "players": players
                        }

    return {}


def handle_find_player(regions, gamedir, lookup_player, map=''):
    """
    Find player by using Master Server and server A2S queries.

    :param regions: Master server regions filter
    :param gamedir: Master server gamedir filter, which means a particular game
    :param lookup_player: Name of the player which we're looking for
    :param map: Master server map filter
    :return: Player lookup result or error message object
    """
    db = boto3.resource('dynamodb')
    logger.info('Starting fetching servers from master')

    servers_table = db.Table('servers')
    players_table = db.Table('players')

    cached_result = handle_find_player_cached(players_table, servers_table, lookup_player)
    if cached_result is not None:
        response_data = cached_result
    else:
        response_data = handle_find_player_online(players_table, servers_table, regions, gamedir, lookup_player, map)

    return {
        "error": False,
        "result": response_data,
    }


def lambda_handler(event, _):
    """
    Process lambda handler for specific actions, like find a player.

    :param event: Event object from API Gateway
    :param _:
    :return:
    """
    logger.info('Initializing master server processor')

    if 'player' not in event:
        return shared.reply_err('Player name is not set in request query')

    """
    Query structure:
    
    'regions': query.get('regions', ["eu"]),
    'game': query.get('game', 'garrysmod'),
    'map': query.get('map', ''),
    'player': query['player']
    """

    return handle_find_player(
        regions=event.get('regions', ["eu"]),
        gamedir=event.get('game', 'garrysmod'),
        lookup_player=event['player'],
        map=event.get('map', ''))
