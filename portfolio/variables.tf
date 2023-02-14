variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}
variable "aws_profile" {
  description = "AWS profile"
}
variable "db_password" {
  description = "DB master password"
  sensitive   = true
}
variable "lambda_zip_name" {
  description = "Name of the zip that is to be uploaded to the S3 bucket and referenced from the Lambda Function"
  default     = "flask-app.zip"
}
variable "codebuild_configuration" {
  type = map(string)
  default = {
    cb_compute_type = "BUILD_GENERAL1_SMALL"
    cb_image        = "aws/codebuild/standard:5.0"
    cb_type         = "LINUX_CONTAINER"
  }
}

locals {
  prefix                     = "shop-be"
  github_oauth_token         = "sensible-to_do_delete"
  github_owner               = "vwjugow"
  shop_be_repository_name    = "shop_be_juiceIT"
  buildspec_file             = "buildspec-zip.yml"
  shop_be_listen_branch_name = "zip_for_lambda"
  common_tags = {
    Project   = "Shop Backend"
    ManagedBy = "Terraform"
  }
}
