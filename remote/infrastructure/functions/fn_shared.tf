#
# Get account details data resource reference for lambda permissions
#
data "aws_caller_identity" "current" {}

data "archive_file" "sm_lambda_shared_layer_zip" {
  type             = "zip"
  source_dir       = "${path.module}/../../app/shared"
  output_file_mode = "0666"
  output_path      = "${path.module}/../../app/target/shared.zip"
}

#
# Create and upload shared layer zip file to S3 bucket
#
resource "aws_s3_bucket_object" "sm_s3_shared_layer" {
  bucket = aws_s3_bucket.sm_lambda_bucket.id
  key    = "lambda/layers/shared.zip"
  source = data.archive_file.sm_lambda_shared_layer_zip.output_path
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
}
