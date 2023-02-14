resource "aws_codebuild_project" "shop_be_codebuild" {
  name         = "${local.prefix}_codebuild_proj"
  service_role = aws_iam_role.codebuild_role.arn
  source {
    type      = "GITHUB"
    location  = "https://github.com/${local.github_owner}/${local.shop_be_repository_name}"
    buildspec = local.buildspec_file
  }
  source_version = local.shop_be_listen_branch_name
  artifacts {
    artifact_identifier    = "ZipFile_build"
    encryption_disabled    = false
    location               = aws_s3_bucket.shop-be-images.id
    name                   = "${local.prefix}-artifact"
    namespace_type         = "NONE"
    override_artifact_name = true
    packaging              = "ZIP"
    type                   = "S3"
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
