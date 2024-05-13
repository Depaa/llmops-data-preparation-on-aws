resource "aws_dynamodb_table" "metadata" {
  name         = "${var.prefix}-metadata"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

module "bronze_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  bucket_prefix = "${var.prefix}-bronze"

  # security
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  attach_public_policy    = false

  # for development only
  force_destroy = var.bucket_force_delete
}

module "silver_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  bucket_prefix = "${var.prefix}-silver"

  # security
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  attach_public_policy    = false

  # for development only
  force_destroy = var.bucket_force_delete
}

module "gold_bucket" {
  source        = "terraform-aws-modules/s3-bucket/aws"
  bucket_prefix = "${var.prefix}-gold"

  # security
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  attach_public_policy    = false

  # for development only
  force_destroy = var.bucket_force_delete
}
