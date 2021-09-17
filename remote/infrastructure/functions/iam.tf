#
# IAM policy JSON definition for both lambda functions
#
data "aws_iam_policy_document" "sm_lambda_policy" {
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    sid = ""
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

#
# IAM policy JSON definition to allow operate calling process lambda
#
data "aws_iam_policy_document" "sm_operate_call_process_policy" {
  version = "2012-10-17"
  statement {
    actions   = ["lambda:InvokeFunction"]
    effect    = "Allow"
    resources = [aws_lambda_function.sm_gw_process_lambda.arn]
  }
}

resource "aws_iam_policy" "sm_operate_allow_process_policy" {
  name        = "sm-allow-process-call"
  description = "Policy which allows operate lambda to call process lambda"

  policy = data.aws_iam_policy_document.sm_operate_call_process_policy.json
}

resource "aws_iam_role_policy_attachment" "sm_operate_process_policy_attachment" {
  role       = aws_iam_role.sm_operate_lambda_role.name
  policy_arn = aws_iam_policy.sm_operate_allow_process_policy.arn
}

#
# Process lambda roles and policy attachments
#
resource "aws_iam_role" "sm_process_lambda_role" {
  name        = "process_lambda_iam_role"
  description = "Base lambda assume role policy"

  assume_role_policy = data.aws_iam_policy_document.sm_lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "sm_process_lambda_exec_role" {
  role       = aws_iam_role.sm_process_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

#
# Operate lambda roles and policy attachments
#
resource "aws_iam_role" "sm_operate_lambda_role" {
  name = "operate_lambda_iam_role"
  assume_role_policy = data.aws_iam_policy_document.sm_lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "sm_operate_lambda_exec_role" {
  role       = aws_iam_role.sm_operate_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
