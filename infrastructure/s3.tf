###########################
# S3 RESOURCES
###########################


resource "aws_s3_bucket" "cinema_app_s3_bucket" {
  bucket        = "${local.prefix}-app"
  force_destroy = true

  tags = local.common_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cinema_app_bucket_encryption" {
  bucket = aws_s3_bucket.cinema_app_s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cinema_app_lifecycle" {
  bucket = aws_s3_bucket.cinema_app_s3_bucket.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# resource "aws_s3_bucket_acl" "cinema_app_bucket_acl" {
#   bucket = aws_s3_bucket.cinema_app_s3_bucket.id
#   acl    = "private"
# }

resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket = aws_s3_bucket.cinema_app_s3_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_versioning" "cinema_app_bucket_versioning" {
  bucket = aws_s3_bucket.cinema_app_s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "cinema_app_bucket_policy" {
  bucket = aws_s3_bucket.cinema_app_s3_bucket.id
  policy = data.aws_iam_policy_document.cinema_app_bucket_policy_document.json
}

# resource "aws_s3_bucket_website_configuration" "cinema_app_bucket_website" {
#   bucket = aws_s3_bucket.cinema_app_s3_bucket.id

#   index_document {
#     suffix = "index.html"
#   }

#   error_document {
#     key = "index.html"
#   }
# }

data "aws_iam_policy_document" "cinema_app_bucket_policy_document" {

  statement {
    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.cinema_app_s3_bucket.arn}/*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "cloudfront.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"

      values = [
        aws_cloudfront_distribution.s3_distribution.arn
      ]
    }
  }
}
