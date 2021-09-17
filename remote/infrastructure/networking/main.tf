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
    Purpose = "Main project VPC"
    Name = "main-vpc"
  }
}

resource "aws_eip" "sm_lb" {
  vpc        = true
  depends_on = [aws_internet_gateway.sm_internet_gw]

  tags = {
    Name = "sm-public-eip"
  }
}

#
# Internet gateway
#
resource "aws_internet_gateway" "sm_internet_gw" {
  vpc_id = aws_vpc.sm_vpc_main.id

  tags = {
    Name = "sm-internet-gw"
  }
}

#
# NAT gateway
#
resource "aws_nat_gateway" "sm_nat_gw" {
  allocation_id = aws_eip.sm_lb.id
  subnet_id     = aws_subnet.sm_lambda_public_subnet.id

  tags = {
    Name = "sm-nat-gateway"
  }
}

#
# Subnets (Public/Private)
#
resource "aws_subnet" "sm_lambda_public_subnet" {
  cidr_block              = "10.0.2.0/24"
  vpc_id                  = aws_vpc.sm_vpc_main.id
  map_public_ip_on_launch = "true"

  tags = {
    Purpose = "Internet access public subnet"
    Name = "sm-public-subnet"
  }
}

resource "aws_subnet" "sm_lambda_private_subnet" {
  cidr_block              = "10.0.1.0/24"
  vpc_id                  = aws_vpc.sm_vpc_main.id
  map_public_ip_on_launch = false

  tags = {
    Purpose = "Lambdas private subnet"
    Name = "private-subnet"
  }
}

resource "aws_network_acl" "sm_lambda_subnet_acl" {
  vpc_id     = aws_vpc.sm_vpc_main.id
  subnet_ids = [aws_subnet.sm_lambda_public_subnet.id, aws_subnet.sm_lambda_private_subnet.id]

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "public-subnet-acl"
  }
}

#
# Route tables
#
resource "aws_route_table" "sm_public_rt" {
  vpc_id = aws_vpc.sm_vpc_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sm_internet_gw.id
  }

  tags = {
    Name = "sm-public-subnet-rt"
  }
}

resource "aws_route_table" "sm_private_rt" {
  vpc_id = aws_vpc.sm_vpc_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.sm_nat_gw.id
  }

  tags = {
    Name = "sm-private-subnet-rt"
  }
}

resource "aws_route_table_association" "sm_public_subnet_associate" {
  subnet_id      = aws_subnet.sm_lambda_public_subnet.id
  route_table_id = aws_route_table.sm_public_rt.id
}

resource "aws_route_table_association" "sm_private_subnet_associate" {
  subnet_id      = aws_subnet.sm_lambda_private_subnet.id
  route_table_id = aws_route_table.sm_private_rt.id
}

#
# Security group
#
resource "aws_security_group" "sm_vpc" {
  name        = "main_lambda_sg"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.sm_vpc_main.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "sm-lambda-sg"
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
# Endpoint for operate
#
resource "aws_api_gateway_resource" "se_api_gw_operate_resource" {
  path_part   = "operate"

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
      aws_api_gateway_resource.se_api_gw_operate_resource.id,
      aws_api_gateway_method.se_api_gw_operate_method.id,
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
