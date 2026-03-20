module "ecr_repository" {
  source = "../../modules/ecr_repository"

  providers = {
    aws = aws.prod_eu_west_2
  }

  environment_name = "prod"
}

module "storage" {
  source = "../../modules/storage"

  providers = {
    aws = aws.prod_eu_west_2
  }

  environment_name = var.environment_name
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  providers = {
    aws = aws.prod_eu_west_2
  }

  environment_name         = var.environment_name
  ecr_repository_url       = module.ecr_repository.repository_url
  media_bucket_name        = module.storage.media_bucket_name
  api_function_domain_name = module.lambda_functions.api_function_domain_name
  domain_name              = "violet.danforge.net"
  hosted_zone_name         = "danforge.net"
}

module "lambda_functions" {
  source = "../../modules/lambda_functions"

  providers = {
    aws = aws.prod_eu_west_2
  }

  catalog_table_name = module.storage.catalog_table_name
  ecr_repository_url = module.ecr_repository.repository_url
  environment_name   = var.environment_name
  media_bucket_name  = module.storage.media_bucket_name
}

module "ingest_handler" {
  source = "../../modules/ingest_handler"

  providers = {
    aws = aws.prod_eu_west_2
  }

  environment_name            = var.environment_name
  ecr_repository_url          = module.ecr_repository.repository_url
  cloudfront_distribution_id  = module.cloudfront.distribution_id
  ingest_handler_function_arn = module.lambda_functions.ingest_handler_function_arn
  media_bucket_name           = module.storage.media_bucket_name
}

