#
# Process Lambda description
#
resource "aws_lambda_function" "sm_gw_process_lambda" {
  filename      = "${local.lambda_base_path}/process.zip"
  function_name = "sm-process"

  role          = aws_iam_role.sm_process_lambda_role.arn
  handler       = "app.lambda_handler"
  runtime       = local.lambda_runtime
  layers        = [aws_lambda_layer_version.sm_lambda_shared_layer.arn]
  timeout       = "60"

  source_code_hash = filebase64sha256("${local.lambda_base_path}/process.zip")

  vpc_config {
    subnet_ids         = var.in_net_subnet_ids
    security_group_ids = var.in_net_security_ids
  }
}

#
# Triggers
#

#resource "aws_cloudwatch_event_rule" "sm_process_servers" {
#  name                = "TriggerSMRefreshServers"
#  description         = "Run server monitoring batch process"
#
#  # https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html
#  # Run every night (once a day)
#  schedule_expression = "cron(0 0 * * ? *)"
#}
