output "ingest_handler_function_arn" {
  value = module.ingest_handler_function.function_arn
}

output "api_function_domain_name" {
  value = module.api_function.iam_function_domain
}
