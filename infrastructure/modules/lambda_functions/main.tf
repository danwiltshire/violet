data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret_version" "data_providers" {
  secret_id = "/violet/${var.environment_name}/data_providers"
}

locals {
  data_providers = jsondecode(data.aws_secretsmanager_secret_version.data_providers.secret_string)
}

module "ingest_handler_function" {
  source = "../lambda_function_image"

  description      = "Extracts metadata from media filenames and puts metadata into DynamoDB."
  function_name    = "violet-${var.environment_name}-ingest"
  environment_name = var.environment_name
  memory_size      = 512
  timeout          = 60

  image = {
    command = ["ingest_handler.lambda_handler"]
    uri     = "${var.ecr_repository_url}:violet-lambda"
  }

  environment_variables = {
    CATALOG_TABLE_NAME   = var.catalog_table_name
    MEDIA_BUCKET_NAME    = var.media_bucket_name
    THE_MOVIE_DB_API_KEY = local.data_providers["THE_MOVIE_DB_API_KEY"]
  }

  additional_policy_documents = [
    jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:PutItem",
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket",
          ],
          "Resource" : [
            "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/${var.catalog_table_name}",
            "arn:aws:s3:::${var.media_bucket_name}",
            "arn:aws:s3:::${var.media_bucket_name}/*",
          ]
        }
      ]
    })
  ]
}

module "api_function" {
  source = "../lambda_function_image"

  description             = "Violet API endpoints."
  enable_iam_function_url = true
  function_name           = "violet-${var.environment_name}-api"
  environment_name        = var.environment_name
  memory_size             = 512
  timeout                 = 60

  image = {
    command = ["api_handler.lambda_handler"]
    uri     = "${var.ecr_repository_url}:violet-lambda"
  }

  environment_variables = {
    CATALOG_TABLE_NAME   = var.catalog_table_name
    MEDIA_BUCKET_NAME    = var.media_bucket_name
    THE_MOVIE_DB_API_KEY = "not-needed"
  }

  additional_policy_documents = [
    jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:Query",
          ],
          "Resource" : ["arn:aws:dynamodb:*:*:table/*"],
          "Condition" : {
            "StringEquals" : {
              "aws:ResourceTag/app" : "violet",
              "aws:ResourceTag/env" : "${var.environment_name}",
            }
          }
        }
      ]
    })
  ]
}
