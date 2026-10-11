variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "test", "prod", "ddlab"], var.environment)
    error_message = "environment must be dev, test, prod or ddlab."
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
