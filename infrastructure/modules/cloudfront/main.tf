data "aws_s3_bucket" "media_bucket" {
  bucket = var.media_bucket_name
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_response_headers_policy" "cors" {
  name = "Managed-CORS-with-preflight-and-SecurityHeadersPolicy"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_wafv2_web_acl" "this" {
  # checkov:skip=CKV2_AWS_31: Not bothing with WAF logs for this demo app.
  # checkov:skip=CKV_AWS_192: Not a Java app - Log4j not used.
  name        = "violet-${var.environment_name}-waf"
  region      = "us-east-1"
  description = "WAF for Violet"
  scope       = "CLOUDFRONT"

  lifecycle {
    create_before_destroy = true
  }

  default_action {
    allow {}
  }

  rule {
    name     = "rate-limit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 500
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "rate-limit-action"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "default-action"
    sampled_requests_enabled   = false
  }
}

resource "aws_cloudfront_origin_access_control" "media_bucket" {
  name                              = "violet-media-bucket-oac-${var.environment_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_origin_access_control" "api_function" {
  name                              = "violet-api-function-oac-${var.environment_name}"
  origin_access_control_origin_type = "lambda"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudwatch_log_group" "this" {
  # checkov:skip=CKV_AWS_158: Don't want KMS
  # checkov:skip=CKV_AWS_338: Don't want long retention
  name              = "/violet/${var.environment_name}/cloudfront/access-logs"
  retention_in_days = 14
  region            = "us-east-1"
}

resource "aws_cloudfront_function" "spa_router" {
  name    = "angular-spa-router"
  runtime = "cloudfront-js-1.0"
  publish = true
  code    = <<-EOT
  var level = 0; // subdirectory level where index.html is located.
  var regexExpr = /^\/.+(\.\w+$)/; // Regex expression than matches paths requestiong an object. i.e: /route1/my-picture.png

  function handler(event) {
      var request = event.request;
      var olduri = request.uri;

      if (isRoute(olduri)) { // if is a route request. i.e: /route1
          var defaultPath = '';
          
          var parts = olduri
              .replace(/^\//,'') // remove leading '/'
              .replace(/\/$/,'') // remove triling '/' if any
              .split('/'); // split uri into array of parts. i.e: ['route1', 'my-picture.png']
          
          var nparts = parts.length;

          // determine the limit as either level or nparts, whichever is lower
          var limit = (level <= nparts) ? level : nparts; 

          // build the default path. i.e: /route1
          for (var i = 0; i < limit; i++) {
              defaultPath += '/' + parts[i];
          }
          
          var newuri = defaultPath + '/index.html';

          request.uri = newuri;
          console.log('Request for [' + olduri + '], rewritten to [' + newuri + ']');
      }   

      return request;
  }

  // Returns true if uri is a route. i.e: /route1
  // Returns false if uri is a file. i.e: /route1/index.html
  function isRoute(uri) {
      return !regexExpr.test(uri);
  }
  EOT
}


resource "aws_cloudfront_distribution" "this" {
  # checkov:skip=CKV2_AWS_42: Using built-in CloudFront domain
  # checkov:skip=CKV_AWS_374: Don't need geo restrictions
  # checkov:skip=CKV_AWS_310: Don't need origin failover
  # checkov:skip=CKV_AWS_86: Using CloudWatch Logs for logging
  # checkov:skip=CKV_AWS_174: Using TLSv1 for the CloudFront-managed TLS certificate
  # checkov:skip=CKV2_AWS_47: Log4j protection not required for the application.
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  http_version        = "http3"
  web_acl_id          = aws_wafv2_web_acl.this.arn
  aliases             = [var.domain_name]

  origin {
    domain_name              = data.aws_s3_bucket.media_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.media_bucket.id
    origin_id                = "violet-media-bucket-frontend"
    origin_path              = "/frontend"
  }

  origin {
    domain_name              = data.aws_s3_bucket.media_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.media_bucket.id
    origin_id                = "violet-media-bucket"
  }

  origin {
    domain_name              = var.api_function_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.api_function.id
    origin_id                = "violet-api-function"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    target_origin_id           = "violet-media-bucket-frontend"
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.cors.id
    viewer_protocol_policy     = "redirect-to-https"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_router.arn
    }
  }

  ordered_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    path_pattern               = "/api/*"
    target_origin_id           = "violet-api-function"
    viewer_protocol_policy     = "redirect-to-https"
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.cors.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
  }

  ordered_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    path_pattern               = "/images/*"
    target_origin_id           = "violet-media-bucket"
    viewer_protocol_policy     = "redirect-to-https"
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.cors.id
  }

  ordered_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    path_pattern               = "/output/*"
    target_origin_id           = "violet-media-bucket"
    viewer_protocol_policy     = "redirect-to-https"
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.cors.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    acm_certificate_arn      = module.acm.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_cloudwatch_log_delivery_source" "cloudfront_logs" {
  region       = "us-east-1"
  name         = "violet-${var.environment_name}-cloudfront-access-logs"
  log_type     = "ACCESS_LOGS"
  resource_arn = aws_cloudfront_distribution.this.arn
}

resource "aws_cloudwatch_log_delivery_destination" "cloudwatch_log_group" {
  region        = "us-east-1"
  name          = "violet-${var.environment_name}-cloudfront-access-logs"
  output_format = "json"

  delivery_destination_configuration {
    destination_resource_arn = aws_cloudwatch_log_group.this.arn
  }
}

resource "aws_cloudwatch_log_delivery" "cloudfront_logs" {
  region                   = "us-east-1"
  delivery_source_name     = aws_cloudwatch_log_delivery_source.cloudfront_logs.name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.cloudwatch_log_group.arn
}

data "aws_route53_zone" "this" {
  name = var.hosted_zone_name
}

resource "aws_route53_record" "ipv4" {
  for_each = aws_cloudfront_distribution.this.aliases
  zone_id  = data.aws_route53_zone.this.zone_id
  name     = each.value
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "ipv6" {
  for_each = aws_cloudfront_distribution.this.aliases
  zone_id  = data.aws_route53_zone.this.zone_id
  name     = each.value
  type     = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

module "acm" {
  # checkov:skip=CKV_TF_1: Using friendly versions based on their docs.
  source  = "terraform-aws-modules/acm/aws"
  version = "6.3.0"

  providers = {
    aws = aws.us-east-1
  }

  domain_name         = var.domain_name
  validation_method   = "DNS"
  wait_for_validation = true
  zone_id             = data.aws_route53_zone.this.zone_id
}
