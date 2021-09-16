
variable "in_region" {
  description = "AWS region"
}

variable "in_api_gw_id" {
  description = "Id of API gateway resource"
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
# Process related
#
variable "in_api_gw_process_method" {
  description = "Id of API gateway for Process method"
  type = string
}

variable "in_api_gw_process_resource_id" {
  description = "Id of API gateway Process resource"
}

variable "in_api_gw_process_resource_path" {
  description = "Id of API gateway resource path for process endpoint"
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
