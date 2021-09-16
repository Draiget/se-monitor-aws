
#
# Operational Lambda description
#
resource "aws_lambda_function" "sm_gw_operator_lambda" {
  filename      = "${local.lambda_base_path}/operate.zip"
  function_name = "sm-operator"

  role          = aws_iam_role.sm_operational_lambda_role.arn
  handler       = "app.lambda_handler"
  runtime       = local.lambda_runtime
  layers        = [aws_lambda_layer_version.sm_lambda_shared_layer.arn]

  source_code_hash = filebase64sha256("${local.lambda_base_path}/operate.zip")

  vpc_config {
    subnet_ids         = var.in_net_subnet_ids
    security_group_ids = var.in_net_security_ids
  }
}

#
# TODO: Dynamic block / for-each ?
#
resource "aws_lambda_permission" "sm_gw_operator_lambda_permissions" {
  statement_id  = "AllowOperatorExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  function_name = aws_lambda_function.sm_gw_operator_lambda.function_name

  # http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.in_region}:${data.aws_caller_identity.current.account_id}:${var.in_api_gw_id}/*/${var.in_api_gw_operate_method}${var.in_api_gw_operate_resource_path}"
}

resource "aws_api_gateway_integration" "sm_gw_operate_integration" {
  rest_api_id             = var.in_api_gw_id
  resource_id             = var.in_api_gw_operate_resource_id
  http_method             = var.in_api_gw_operate_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.sm_gw_operator_lambda.invoke_arn
}

#
# Triggers
#