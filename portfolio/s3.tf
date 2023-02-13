data "aws_canonical_user_id" "current" {}

output "canonical_user_id" {
  value = data.aws_canonical_user_id.current.id
}

resource "aws_s3_bucket" "shop-be-images" {
  bucket = "${local.prefix}-images-bucket"
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
