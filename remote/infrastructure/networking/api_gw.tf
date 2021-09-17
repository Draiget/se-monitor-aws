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

  stage_description = md5(file("${path.module}/api_gw.tf"))

  lifecycle {
    create_before_destroy = true
  }
}
