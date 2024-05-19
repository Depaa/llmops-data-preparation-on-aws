variable "prefix" {
  type = string
}

variable "is_debug_on" {
  type    = bool
  default = true
}

variable "bronze_bucket_name" {
  type = string
}

variable "silver_bucket_name" {
  type = string
}

variable "gold_bucket_name" {
  type = string
}

variable "metadata_database_name" {
  type = string
}

variable "metadata_database_arn" {
  type = string
}
