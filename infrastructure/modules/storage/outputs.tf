output "catalog_table_name" {
  value = aws_dynamodb_table.catalog.name
}

output "media_bucket_name" {
  value = aws_s3_bucket.media.id
}
