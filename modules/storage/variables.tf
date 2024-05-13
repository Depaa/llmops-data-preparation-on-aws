variable "prefix" {
  type = string
}

variable "bucket_force_delete" {
  description = "Force bucket deletion."
  type        = bool
  default     = true
}
