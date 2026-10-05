variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test or prod."
  }
}

variable "instance_count" {
  type        = number
  description = "How many web servers this environment has"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}