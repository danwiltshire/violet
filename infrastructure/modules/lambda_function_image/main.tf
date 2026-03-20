data "aws_caller_identity" "current" {}

data "aws_kms_key" "aws_lambda_kms_key" {
  key_id = "alias/aws/lambda"
}

locals {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  cloudwatch_logs_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}

resource "aws_iam_role" "this" {
  name = "${var.function_name}-role"

  assume_role_policy = local.assume_role_policy
}

data "aws_iam_policy_document" "policy" {
  source_policy_documents = flatten([
    local.cloudwatch_logs_policy,
    var.additional_policy_documents
  ])
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "${var.function_name}-policy"
  path        = "/"
  description = "IAM policy the ${var.function_name} Lambda function"

  policy = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_cloudwatch_log_group" "this" {
  # checkov:skip=CKV_AWS_158: Don't want KMS
  # checkov:skip=CKV_AWS_338: Don't want long retention
  name              = "/violet/${var.environment_name}/lambda/${var.function_name}"
  retention_in_days = 14
}

resource "aws_lambda_function" "this" {
  # checkov:skip=CKV_AWS_272: Don't need code signing.
  # checkov:skip=CKV_AWS_116: Don't want a dead letter queue.
  # checkov:skip=CKV_AWS_117: Don't need VPC access.
  # checkov:skip=CKV_AWS_50: Don't want X-Ray.
  architectures                  = [var.architecture]
  description                    = var.description
  function_name                  = var.function_name
  image_uri                      = var.image.uri
  kms_key_arn                    = data.aws_kms_key.aws_lambda_kms_key.arn
  memory_size                    = var.memory_size
  package_type                   = "Image"
  reserved_concurrent_executions = 10 # Deliberately low to prevent abuse.
  role                           = aws_iam_role.this.arn
  timeout                        = var.timeout

  image_config {
    command = var.image.command
  }

  logging_config {
    log_group  = aws_cloudwatch_log_group.this.name
    log_format = "JSON"
  }

  environment {
    variables = var.environment_variables
  }
}

resource "aws_lambda_function_url" "this" {
  function_name      = aws_lambda_function.this.function_name
  authorization_type = "AWS_IAM"
}

resource "aws_lambda_permission" "allow_cloudfront" {
  for_each = toset(["lambda:InvokeFunction", "lambda:InvokeFunctionUrl"])

  action         = each.value
  function_name  = aws_lambda_function.this.function_name
  principal      = "cloudfront.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
}
