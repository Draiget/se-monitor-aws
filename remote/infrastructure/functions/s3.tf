#
# Bucket to store shared lambda layers, etc.
#
resource "aws_s3_bucket" "sm_lambda_bucket" {
  bucket_prefix = "sm-lambda-bucket"
  acl           = "private"

  tags = {
    env = "dev"
    purpose = "Store Lambda functions and layers"
  }
}
