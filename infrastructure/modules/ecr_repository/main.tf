resource "aws_ecr_repository" "this" {
  # checkov:skip=CKV_AWS_51: ECR tags get overwritten by CI
  # checkov:skip=CKV_AWS_136: Don't need a custom CMK
  # checkov:skip=CKV_AWS_163: Don't need vulnerability scanning
  name                 = "violet-${var.environment_name}-images"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode(
    {
      "rules" : [
        {
          "rulePriority" : 1,
          "description" : "Expire images older than 14 days",
          "selection" : {
            "tagStatus" : "untagged",
            "countType" : "sinceImagePushed",
            "countUnit" : "days",
            "countNumber" : 14
          },
          "action" : {
            "type" : "expire"
          }
        }
      ]
    }
  )
}
