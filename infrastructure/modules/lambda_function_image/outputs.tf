output "role_arn" {
  value = aws_iam_role.this.arn
}

output "function_arn" {
  value = aws_lambda_function.this.arn
}

output "iam_function_domain" {
  value = trimsuffix(trimprefix(aws_lambda_function_url.this.function_url, "https://"), "/")
}
