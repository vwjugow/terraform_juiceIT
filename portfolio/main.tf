data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name                 = "shop-be"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_db_subnet_group" "shop-be" {
  name       = "shop-be"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "shop-be"
  }
}

resource "aws_security_group" "rds" {
  name   = "shop-be_rds"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "shop-be_rds"
  }
}

resource "aws_db_parameter_group" "shop-be" {
  name   = "shop-be"
  family = "postgres14"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "shop-be" {
  identifier             = "shop-be"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "14.1"
  username               = "edu"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.shop-be.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.shop-be.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}

## Parameters
resource "aws_ssm_parameter" "db_pw" {
  name        = "/development/database/password"
  description = "The parameter description"
  type        = "SecureString"
  value       = aws_db_instance.shop-be.password
  tags = {
    environment = "development"
  }
}
resource "aws_ssm_parameter" "db_user" {
  name        = "/development/database/user"
  description = "Dev DB username"
  type        = "SecureString"
  value       = aws_db_instance.shop-be.username
  tags = {
    environment = "development"
  }
}
resource "aws_ssm_parameter" "db_hostname" {
  name        = "/development/database/hostname"
  description = "Dev DB hostname"
  type        = "SecureString"
  value       = aws_db_instance.shop-be.address
  tags = {
    environment = "development"
  }
}
resource "aws_ssm_parameter" "db_port" {
  name        = "/development/database/port"
  description = "Dev DB port"
  type        = "SecureString"
  value       = aws_db_instance.shop-be.port
  tags = {
    environment = "development"
  }
}

#### Bucket
data "aws_canonical_user_id" "current" {}

output "canonical_user_id" {
  value = data.aws_canonical_user_id.current.id
}

resource "aws_s3_bucket" "shop-be-images" {
  bucket = "shop-be-images-bucket"
  tags = {
  }
}

resource "aws_s3_bucket_acl" "shop-be-images-acl" {
  bucket = aws_s3_bucket.shop-be-images.id
  access_control_policy {
    grant {
      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "READ"
    }
    owner {
      id = data.aws_canonical_user_id.current.id
    }
  }
}

resource "aws_s3_object" "dummy_zip" {
  bucket = aws_s3_bucket.shop-be-images.bucket
  key    = var.lambda_zip_name
  source = "./dummy.zip"
  etag   = filemd5("./dummy.zip")
}

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
