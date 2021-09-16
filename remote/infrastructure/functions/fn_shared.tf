#
# Get account details data resource reference for lambda permissions
#
data "aws_caller_identity" "current" {}

#
# Due to terraform call base64sha256 before any apply actions, below script is not being executed before it
# Ref: https://github.com/hashicorp/terraform/issues/22036#issuecomment-510558357
#
#resource "null_resource" "sm_pack_operator_lambda" {
#  provisioner "local-exec" {
#    command = "(cd ${path.module}/../.. && sh ./lambda_build.sh)"
#  }
#}

#
# Create and upload shared layer zip file to S3 bucket
#
resource "aws_s3_bucket_object" "sm_s3_shared_layer" {
  bucket = aws_s3_bucket.sm_lambda_bucket.id
  key    = "lambda/layers/shared.zip"

  # depends_on = [null_resource.sm_pack_operator_lambda]
  source = "${local.lambda_base_path}/shared.zip"
}

#
# Define shared layer for Lambda that we will use in our both lambda functions
#
resource "aws_lambda_layer_version" "sm_lambda_shared_layer" {
  layer_name = "sm_shared"

  s3_bucket = aws_s3_bucket_object.sm_s3_shared_layer.bucket
  s3_key = aws_s3_bucket_object.sm_s3_shared_layer.key
  s3_object_version = aws_s3_bucket_object.sm_s3_shared_layer.version_id

  description = "Shared Lambda layer for Source Monitoring"
  compatible_runtimes = [local.lambda_runtime]

  source_code_hash = filebase64sha256("${local.lambda_base_path}/shared.zip")
}
