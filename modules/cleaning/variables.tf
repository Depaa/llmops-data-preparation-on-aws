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

# glue job varaibles
variable "default_arguments" {
  description = "The default arguments for the Glue job."
  type        = map(string)
  default     = {}
}

variable "max_retries" {
  description = "The maximum number of times to retry this job if it fails."
  type        = number
  default     = 0
}

variable "timeout" {
  description = "The job timeout in minutes."
  type        = number
  default     = 2880
}

variable "glue_version" {
  description = "The version of Glue to use."
  type        = string
  default     = "4.0"
}

variable "number_of_workers" {
  description = "The number of workers of a defined workerType that are allocated when a job runs."
  type        = number
  default     = 10
}

variable "worker_type" {
  description = "The type of predefined worker that is allocated when a job runs. Accepts Standard, G.1X, or G.2X."
  type        = string
  default     = "G.1X"
}