locals {
  stages = {
    "dev" = {}
  }
}

#
# Our main VPC resource
#
resource "aws_vpc" "sm_vpc_main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    purpose = "Main project VPC"
  }
}

resource "aws_subnet" "sm_lambda_subnet" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.sm_vpc_main.id

  tags = {
    purpose = "Lambdas subnet"
  }
}

resource "aws_security_group" "sm_vpc" {
  name        = "main_lambda_sg"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.sm_vpc_main.id

  tags = {
    Name = "allow_tls"
  }
}

#
# Gateway for REST-full api
#
resource "aws_api_gateway_api_key" "se_api_gw_key" {
  name = "client-key"
}

resource "aws_api_gateway_rest_api" "se_api_gw" {
  name = "source-monitoring-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

#
# Endpoints (resources) for two lambda
# 1. For operate
# 2. For process
#
resource "aws_api_gateway_resource" "se_api_gw_operate_resource" {
  path_part   = "operate"

  parent_id   = aws_api_gateway_rest_api.se_api_gw.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.se_api_gw.id
}

resource "aws_api_gateway_resource" "se_api_gw_process_resource" {
  path_part   = "process"

  parent_id   = aws_api_gateway_rest_api.se_api_gw.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.se_api_gw.id
}

#
# Methods for Operate and Process resources (endpoints)
#
resource "aws_api_gateway_method" "se_api_gw_operate_method" {
  rest_api_id   = aws_api_gateway_rest_api.se_api_gw.id
  resource_id   = aws_api_gateway_resource.se_api_gw_operate_resource.id

  http_method   = "POST"
  authorization = "NONE"

  api_key_required = true
}

resource "aws_api_gateway_method" "se_api_gw_process_method" {
  rest_api_id   = aws_api_gateway_rest_api.se_api_gw.id
  resource_id   = aws_api_gateway_resource.se_api_gw_process_resource.id

  http_method   = "POST"
  authorization = "NONE"

  api_key_required = true
}

#
# Deployment for API
#
resource "aws_api_gateway_deployment" "se_gw_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.se_api_gw.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.se_api_gw.body,
      aws_api_gateway_resource.se_api_gw_process_resource.id,
      aws_api_gateway_method.se_api_gw_process_method.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

#
# Stages for API (generic, based on local variables)
#
resource "aws_api_gateway_stage" "se_gw_stage" {
  for_each = local.stages

  deployment_id = aws_api_gateway_deployment.se_gw_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.se_api_gw.id
  stage_name    = each.key
}

resource "aws_api_gateway_usage_plan" "se_api_gw_usage_plan" {
  for_each = local.stages
  name     = "operate_${each.key}_usage_plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.se_api_gw.id
    stage = aws_api_gateway_stage.se_gw_stage[each.key].stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "se_api_gw_usage_plan_key" {
  for_each = local.stages

  key_id = aws_api_gateway_api_key.se_api_gw_key.id
  key_type = "API_KEY"

  usage_plan_id = aws_api_gateway_usage_plan.se_api_gw_usage_plan[each.key].id
}
