
output "iam_operational_lambda_invoke_arn" {
  value = aws_lambda_function.sm_gw_operate_lambda.invoke_arn
}
