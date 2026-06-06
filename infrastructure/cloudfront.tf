###########################
# CLOUDFRONT RESOURCES
###########################

resource "aws_cloudfront_origin_access_control" "cinema_app_oac" {
  name                              = "cinema-app-oac"
  description                       = "OAC for cinema app"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# resource "aws_cloudfront_origin_access_identity" "cinema_app_origin_access" {
#   comment = "OAI for cinema app S3 bucket"
# }

resource "aws_cloudfront_distribution" "s3_distribution" {
  retain_on_delete    = false
  price_class         = "PriceClass_All"
  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.cinema_app_s3_bucket.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.cinema_app_s3_bucket.id
    origin_access_control_id = aws_cloudfront_origin_access_control.cinema_app_oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.cinema_app_s3_bucket.id
    viewer_protocol_policy = "redirect-to-https"

    compress    = true
    min_ttl     = 0
    default_ttl = 300
    max_ttl     = 300

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_response

    content {
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.common_tags
}