/**
*   Deploys the metadata dynamodb table and 3 storage buckets
*   
*/

locals {
  is_debug_on = var.environment != "prod" ? true : false
}

module "storage" {
  source = "./modules/storage"

  prefix              = "${var.environment}-${var.region}-${var.project}"
  bucket_force_delete = var.environment != "prod" ? false : true
}

module "extracting_layer" {
  source = "./modules/extracting"

  prefix                 = "${var.environment}-${var.region}-${var.project}"
  bronze_bucket_name     = module.storage.bronze_bucket_name
  silver_bucket_name     = module.storage.silver_bucket_name
  gold_bucket_name       = module.storage.gold_bucket_name
  metadata_database_name = module.storage.metadata_database_name
  metadata_database_arn  = module.storage.metadata_database_arn
  is_debug_on            = local.is_debug_on
}

module "cleaning_layer" {
  source = "./modules/cleaning"

  prefix                 = "${var.environment}-${var.region}-${var.project}"
  bronze_bucket_name     = module.storage.bronze_bucket_name
  silver_bucket_name     = module.storage.silver_bucket_name
  gold_bucket_name       = module.storage.gold_bucket_name
  metadata_database_name = module.storage.metadata_database_name
  metadata_database_arn  = module.storage.metadata_database_arn
  is_debug_on            = local.is_debug_on
}

module "augmenting_layer" {
  source = "./modules/augmenting"

  prefix                 = "${var.environment}-${var.region}-${var.project}"
  bronze_bucket_name     = module.storage.bronze_bucket_name
  silver_bucket_name     = module.storage.silver_bucket_name
  gold_bucket_name       = module.storage.gold_bucket_name
  metadata_database_name = module.storage.metadata_database_name
  metadata_database_arn  = module.storage.metadata_database_arn
  is_debug_on            = local.is_debug_on
}
