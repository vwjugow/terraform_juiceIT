resource "aws_codepipeline" "shop_be_pipeline" {
  name     = "${local.prefix}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn
  tags     = local.common_tags

  artifact_store {
    location = aws_s3_bucket.shop-be-images.id
    type     = "S3"
  }

  stage {
    name = "Clone"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      input_artifacts  = []
      output_artifacts = ["CodeWorkspace"]

      configuration = {
        Owner      = local.github_owner
        Repo       = local.shop_be_repository_name
        Branch     = local.shop_be_listen_branch_name
        OAuthToken = local.github_oauth_token
      }
    }
  }

  stage {
    name = "BuildZip"
    action {
      run_order        = 1
      name             = "BuildZip"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["CodeWorkspace"]
      output_artifacts = ["ZipFile"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.shop_be_codebuild.name
        EnvironmentVariables = jsonencode([
          {
            name  = "PIPELINE_EXECUTION_ID"
            value = "#{codepipeline.PipelineExecutionId}"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }
}

resource "aws_iam_role" "codepipeline" {
  description = "CodePipeline Service Role"
  tags        = local.common_tags
  name        = "${local.prefix}-codePipeline-provision-role"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "codepipeline.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )

  inline_policy {
    name   = "codepipeline_execute_policy"
    policy = data.aws_iam_policy_document.codepipeline.json
  }
}

data "aws_iam_policy_document" "codepipeline" {
  statement {
    sid = "SSOCodePipelineAllow"

    actions = [
      "s3:*",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "iam:PassRole",
    ]

    resources = [
      aws_iam_role.codebuild_role.arn,
    ]
  }

  statement {
    actions = [
      "codecommit:BatchGet*",
      "codecommit:BatchDescribe*",
      "codecommit:Describe*",
      "codecommit:Get*",
      "codecommit:List*",
      "codecommit:GitPull",
      "codecommit:UploadArchive",
      "codecommit:GetBranch",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "codebuild:StartBuild",
      "codebuild:StopBuild",
      "codebuild:BatchGetBuilds",
    ]

    resources = [
      aws_codebuild_project.shop_be_codebuild.arn,
    ]
  }
}
