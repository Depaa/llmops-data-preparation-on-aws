output "bronze_bucket_name" {
  value = module.bronze_bucket.s3_bucket_id
}

output "silver_bucket_name" {
  value = module.silver_bucket.s3_bucket_id
}

output "gold_bucket_name" {
  value = module.gold_bucket.s3_bucket_id
}

output "metadata_database_name" {
  value = aws_dynamodb_table.metadata.name
}

output "metadata_database_arn" {
  value = aws_dynamodb_table.metadata.arn
}