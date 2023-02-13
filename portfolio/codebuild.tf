#### CI
resource "aws_codebuild_project" "shop_be_codebuild" {
  name         = "${local.prefix}_be_codebuild_proj"
  service_role = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  source {
    type            = "GITHUB"
    location        = "https://github.com/vwjugow/shop_be_juiceIT.git"
    git_clone_depth = 1
    buildspec       = <<EOF
version: 0.2
phases:
  build:
    commands:
      - echo "Running script from GitHub repository"
      - bash build_zip.sh
artifacts:
  files:
    - flask-app.zip
EOF
  }
  source_version = "zip_for_lambda"
  environment {
    type         = "LINUX_CONTAINER"
    image        = "aws/codebuild/standard:2.0"
    compute_type = "BUILD_GENERAL1_SMALL"
  }
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_iam_role" "codebuild_role" {
  name = "${local.prefix}-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_role_policy" {
  role   = aws_iam_role.codebuild_role.name
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
  role       = aws_iam_role.codebuild_role.name
}
