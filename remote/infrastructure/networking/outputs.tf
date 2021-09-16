
#
# VPC and subnet
#
output "main_vpc_arn" {
  value = aws_vpc.sm_vpc_main.arn
}

output "lambda_subnet_id" {
  value = aws_subnet.sm_lambda_subnet.id
}

#
# Security group
#
output "lambda_security_group_id" {
  value = aws_security_group.sm_vpc.id
}

#
# API GW access key
#
output "api_key" {
  value = aws_api_gateway_api_key.se_api_gw_key.value
}

#
# API GW resource Id
#
output "api_gw_id" {
  value = aws_api_gateway_rest_api.se_api_gw.id
}

#
# Operate endpoint related
#
output "api_gw_operate_method" {
  value = aws_api_gateway_method.se_api_gw_operate_method.http_method
}

output "api_gw_operate_resource_id" {
  value = aws_api_gateway_resource.se_api_gw_operate_resource.id
}

output "api_gw_operate_resource_path" {
  value = aws_api_gateway_resource.se_api_gw_operate_resource.path
}

#
# Process endpoint related
#
output "api_gw_process_method" {
  value = aws_api_gateway_method.se_api_gw_process_method.http_method
}

output "api_gw_process_resource_id" {
  value = aws_api_gateway_resource.se_api_gw_process_resource.id
}

output "api_gw_process_resource_path" {
  value = aws_api_gateway_resource.se_api_gw_process_resource.path
}
