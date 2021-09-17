
variable "in_region" {
  description = "AWS region"
}

variable "in_api_gw_id" {
  description = "Id of API gateway resource"
}

variable "in_api_gw_execution_arn" {
  description = "Execution ARN of API GW"
}

#
# Operate related
#
variable "in_api_gw_operate_method" {
  description = "Id of API gateway for operate method"
  type = string
}

variable "in_api_gw_operate_resource_id" {
  description = "Id of API gateway operate resource"
}

variable "in_api_gw_operate_resource_path" {
  description = "Id of API gateway resource path for operate endpoint"
}

#
# Subnets list
#
variable "in_net_subnet_ids" {
  description = "List of subnet IDs for lambda function"
  type = list(string)
}

#
# Security group list
#
variable "in_net_security_ids" {
  description = "List of security group IDs for lambda function"
  type = list(string)
}

#
# DynamoDB table inputs
#
variable "in_db_servers_table_arn" {
  description = "ARN for servers DynamoDB table"
}

variable "in_db_players_table_arn" {
  description = "ARN for players DynamoDB table"
}