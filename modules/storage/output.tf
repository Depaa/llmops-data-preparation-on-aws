output "bronze_bucket_name" {
  value = module.bronze_bucket.s3_bucket_id
}

output "silver_bucket_name" {
  value = module.silver_bucket.s3_bucket_id
}

output "gold_bucket_name" {
  value = module.gold_bucket.s3_bucket_id
}
