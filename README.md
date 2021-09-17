# Source Engine Monitoring Tool - Serverless
Example serverless application on AWS using Valve Source Engine query protocol

[Swagger Description](https://petstore.swagger.io/?url=https://raw.githubusercontent.com/Draiget/se-monitor-aws/master/remote/app/swagger.yml)

## Player lookup
Example curl request to find a player by name on any Source Engine game supported by 
[python-valve](https://github.com/serverstf/python-valve) package (A2S query).

```shell script
curl \
  -X POST \
  -v \
  "https://h2ookxd44l.execute-api.us-east-1.amazonaws.com/dev/operate" \
  -H "x-api-key: <KEY>" \
  --data '{ "action": "find", "query": { "map": "gm_buildscapes_a2", "player": "Draiget", "regions": ["all"] }}'
```

Where a `<KEY>` you can obtain running `terraform output -json` command after provisioning infrastructure.

## Deploying

Application can be deployed within FreeTier usage.
