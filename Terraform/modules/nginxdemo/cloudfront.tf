
resource "aws_cloudfront_function" "index_function" {
  name    = "index-function"
  runtime = "cloudfront-js-1.0"
  comment = "function redirect to index.html"
  publish = true
  code    = file("${path.module}/function.js")
}

module "nginxdemo-cloudfront" {
  source = "terraform-aws-modules/cloudfront/aws"


  /* aliases = ["suyogmaid.co"] */

  comment             = "nginxdemo CloudFront"
  enabled             = true
  http_version        = "http2and3"
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = true

  create_origin_access_identity = true
  origin_access_identities = {
    s3_bucket_oai = "nginxdemo CloudFront can access"
  }

  logging_config = {
    bucket = "nginxdemo-logs.s3.amazonaws.com"
    prefix = "cloudfront"
  }

  origin = {
    uw_api_agw = {
      domain_name = "52osjflqff.execute-api.ap-south-1.amazonaws.com"
      custom_origin_config = {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }

    s3_customer_images = {
      domain_name = "nginxdemo-customer-images.s3.amazonaws.com"
      s3_origin_config = {
        origin_access_identity = "s3_bucket_oai"
      }
    }
    s3_client_ui = {
      domain_name = "nginxdemo-client-ui.s3.amazonaws.com"
      s3_origin_config = {
        origin_access_identity = "s3_bucket_oai"
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "s3_client_ui"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    use_forwarded_values   = false
    function_association = {

      # Valid keys: viewer-request, origin-request, viewer-response, origin-response
      viewer-request = {
        function_arn = aws_cloudfront_function.index_function.arn
      }
    }
  }

  ordered_cache_behavior = [
    {
      path_pattern           = "/udyog-ui/images/*"
      target_origin_id       = "s3_customer_images"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD"]
      compress               = true
      cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      use_forwarded_values   = false
      function_association = {

        # Valid keys: viewer-request, origin-request, viewer-response, origin-response
        viewer-request = {
          function_arn = aws_cloudfront_function.index_function.arn
        }
      }
    },
    {
      path_pattern             = "/udyog/*"
      target_origin_id         = "uw_api_agw"
      viewer_protocol_policy   = "redirect-to-https"
      allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods           = ["GET", "HEAD"]
      compress                 = false
      use_forwarded_values     = false
      cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
      origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"

    }

  ]
  custom_error_response = [{
    error_code         = 404
    response_code      = 404
    response_page_path = "/assets/html/404.html"
    }, {
    error_code         = 403
    response_code      = 403
    response_page_path = "/assets/html/403.html"
  }]


  /* viewer_certificate = {
    acm_certificate_arn = "arn:aws:acm:us-east-1:135367859851:certificate/1032b155-22da-4ae0-9f69-e206f825458b"
    ssl_support_method  = "sni-only"
  } */
}

data "aws_iam_policy_document" "s3_policy_nginxdemo_client_ui" {
  # Origin Access Identities
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3-bucket-nginxdemo-client-ui.s3_bucket_arn}/*"]

    principals {
      type        = "AWS"
      identifiers = module.nginxdemo-cloudfront.cloudfront_origin_access_identity_iam_arns
    }
  }

  # Origin Access Controls
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3-bucket-nginxdemo-client-ui.s3_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [module.nginxdemo-cloudfront.cloudfront_distribution_arn]
    }
  }

  statement {
    sid    = "denyUnencryptedObjectUploads"
    effect = "Deny"

    actions = [
      "s3:PutObject"
    ]

    resources = ["${module.s3-bucket-nginxdemo-client-ui.s3_bucket_arn}/*"]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = [true]
    }
  }

}

resource "aws_s3_bucket_policy" "bucket_policy_nginxdemo_client_ui" {
  bucket = module.s3-bucket-nginxdemo-client-ui.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_policy_nginxdemo_client_ui.json
}

data "aws_iam_policy_document" "s3_policy_nginxdemo_customer_images" {
  # Origin Access Identities
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3-bucket-nginxdemo-customer-images.s3_bucket_arn}/*"]

    principals {
      type        = "AWS"
      identifiers = module.nginxdemo-cloudfront.cloudfront_origin_access_identity_iam_arns
    }
  }

  # Origin Access Controls
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3-bucket-nginxdemo-customer-images.s3_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [module.nginxdemo-cloudfront.cloudfront_distribution_arn]
    }
  }

  statement {
    sid    = "denyUnencryptedObjectUploads"
    effect = "Deny"

    actions = [
      "s3:PutObject"
    ]

    resources = ["${module.s3-bucket-nginxdemo-customer-images.s3_bucket_arn}/*"]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = [true]
    }
  }

}

resource "aws_s3_bucket_policy" "bucket_policy_nginxdemo_customer_images" {
  bucket = module.s3-bucket-nginxdemo-customer-images.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_policy_nginxdemo_customer_images.json
}

