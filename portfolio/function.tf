#### lambda
## lambda itself
resource "aws_lambda_function" "shop-be-lambda" {
  function_name = "shop-be-lambda"
  runtime       = "python3.8"
  role          = aws_iam_role.shop-be-role.arn
  s3_bucket     = aws_s3_bucket.shop-be-images.bucket
  s3_key        = var.lambda_zip_name
  handler       = "app.app"
  # source_code_hash = filebase64sha256("function.zip")
  environment {
    variables = {
      BUCKET_NAME       = aws_s3_bucket.shop-be-images.bucket
      DB_USER           = aws_ssm_parameter.db_user.value
      DB_PASSWORD       = aws_ssm_parameter.db_pw.value
      DB_HOST           = aws_ssm_parameter.db_hostname.value
      DB_PORT           = aws_ssm_parameter.db_port.value
      DATABASE          = "shopapp"
      FLASK_ENV         = "development"
      FLASK_CONFIG_FILE = "envs/flask.cfg"
    }
  }
  depends_on = [
    aws_s3_bucket.shop-be-images,
    aws_ssm_parameter.db_user,
    aws_ssm_parameter.db_pw,
    aws_ssm_parameter.db_hostname,
    aws_ssm_parameter.db_port
  ]
}

resource "aws_iam_role" "shop-be-role" {
  name               = "shop-be-role"
  assume_role_policy = <<EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
    EOF
}
