#### CI
resource "aws_codebuild_project" "shop_be_codebuild" {
  name         = "${local.prefix}_codebuild_proj"
  service_role = aws_iam_role.codebuild_role.arn
  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-zip.yml"
  }
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type = var.codebuild_configuration["cb_compute_type"]
    image        = var.codebuild_configuration["cb_image"]
    type         = var.codebuild_configuration["cb_type"]
  }
  tags = local.common_tags
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
  description = "Allows CodeBuild to call AWS services on your behalf."
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  ]
}

resource "aws_iam_role_policy" "codebuild_role_policy" {
  role = aws_iam_role.codebuild_role.name
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Resource" : [
            "*"
          ],
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
        },
        {
          "Action" : [
            "s3:PutObject",
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketAcl",
            "s3:GetBucketLocation"
          ]
          "Effect" : "Allow"
          "Resource" : [
            "arn:aws:s3:::codepipeline-us-east-1-*"
          ]
        },
        {
          "Action" : [
            "codebuild:CreateReportGroup",
            "codebuild:CreateReport",
            "codebuild:UpdateReport",
            "codebuild:BatchPutTestCases",
            "codebuild:BatchPutCodeCoverages"
          ]
          "Effect" : "Allow"
          "Resource" : [
            "*"
          ]
        }
      ]
  })
}
