# Source Engine Monitoring Tool - Serverless
Example serverless application on AWS using Valve Source Engine query protocol

[Swagger Description](https://petstore.swagger.io/?url=https://raw.githubusercontent.com/Draiget/se-monitor-aws/master/remote/app/swagger.yml)

## Player lookup
Example curl request to find a player by name on any Source Engine game supported by 
[python-valve](https://github.com/serverstf/python-valve) package (A2S query).

<a name="player_lookup_example"></a>
```shell script
curl \
  -X POST \
  -v \
  "https://<link>.execute-api.us-east-1.amazonaws.com/dev/operate" \
  -H "x-api-key: <KEY>" \
  --data '{ "action": "find", "query": { "map": "gm_buildscapes_a2", "player": "Draiget", "regions": ["all"] }}'
```

Where a `<KEY>` you can obtain running `terraform output -json` command after provisioning infrastructure.

## Deploying

Application can be deployed within FreeTier usage.

Use following steps to deploy application (assumes that you're in the folder where this README.md are placed):
1. Package lambda functions:
    ```shell script
    (cd remote/app && ./lambda_build.sh)
    ```
2. Apply terraform:
    ```shell script
    (cd remote/infrastructure && terraform apply -auto-approve)
    ```
3. Validate using example in [Player lookup](#player-lookup)