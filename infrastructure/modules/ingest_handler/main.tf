data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "mediaconvert_role" {
  name = "violet-${var.environment_name}-mediaconvert-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "mediaconvert.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "media_convert_policy" {
  name = "violet-${var.environment_name}-mediaconvert-policy"
  role = aws_iam_role.mediaconvert_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:Get*",
          "s3:List*",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.media_bucket_name}",
          "arn:aws:s3:::${var.media_bucket_name}/*"
        ]
      },
      {
        Action = [
          "s3:Put*",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.media_bucket_name}/*"
      },
    ]
  })
}

resource "aws_iam_role" "state_machine_role" {
  name = "violet-${var.environment_name}-stepfunctions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "state_machine_policy" {
  name = "violet-${var.environment_name}-stepfunctions-policy"
  role = aws_iam_role.state_machine_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "mediaconvert:CreateJob",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:mediaconvert:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*",
        ]
      },
      {
        Action = [
          "mediaconvert:GetJob",
          "mediaconvert:CancelJob"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:mediaconvert:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:jobs/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/ManagedByService" = "AWSStepFunctions"
          }
        }
      },
      {
        Action = [
          "iam:PassRole"
        ]
        Effect   = "Allow"
        Resource = "${aws_iam_role.mediaconvert_role.arn}"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "mediaconvert.amazonaws.com"
            ]
          }
        }
      },
      {
        Action = [
          "events:PutTargets",
          "events:PutRule",
          "events:DescribeRule"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:events:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForMediaConvertJobRule"
      },
      {
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:cloudfront::*:distribution/*",
        ],
        Condition : {
          "StringEquals" : {
            "aws:ResourceTag/app" : "violet",
            "aws:ResourceTag/env" : "${var.environment_name}",
          }
        }
      },
      {
        Action = [
          "lambda:InvokeFunction"
        ]
        Effect   = "Allow"
        Resource = var.ingest_handler_function_arn
      },
      {
        Action = [
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.media_bucket_name}/ingest/*"
      }
    ]
  })
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  # checkov:skip=CKV_AWS_285: Built-in console history is fine
  # checkov:skip=CKV_AWS_284: Don't want X-Ray
  name     = "violet-${var.environment_name}-ingest"
  role_arn = aws_iam_role.state_machine_role.arn

  definition = templatefile("${path.module}/templates/state_machine.asl.json", {
    mediaconvert_role_arn       = aws_iam_role.mediaconvert_role.arn
    bucket_name                 = var.media_bucket_name
    catalog_ingest_function_arn = var.ingest_handler_function_arn
    cloudfront_distribution_id  = var.cloudfront_distribution_id
  })
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.media_bucket_name

  eventbridge = true
}


module "eventbridge" {
  # checkov:skip=CKV_TF_1: Prefer human readable version
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "v4.3.0"

  create_bus = false

  rules = {
    media_uploads = {
      description = "Media uploads"
      event_pattern = jsonencode({
        "source" : ["aws.s3"],
        "detail-type" : ["Object Created"],
        "detail" : {
          "bucket" : {
            "name" : [
              "${var.media_bucket_name}"
            ]
          },
          "object" : {
            "key" : [
              {
                "prefix" : "ingest/"
              }
            ]
          }
        }
      })
    }
  }

  targets = {
    media_uploads = [
      {
        name            = aws_sfn_state_machine.sfn_state_machine.name
        arn             = aws_sfn_state_machine.sfn_state_machine.arn
        attach_role_arn = true
      }
    ]
  }

  sfn_target_arns   = [aws_sfn_state_machine.sfn_state_machine.arn]
  attach_sfn_policy = true
}
