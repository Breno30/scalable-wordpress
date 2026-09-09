# Input variables
variable "aws_region" {
  type        = string
  description = "AWS Region in which to deploy the stack"
  default     = "us-east-1"
}

variable "name_prefix" {
  type        = string
  description = "Prefix used for names of resources created by this stack"
  default     = "wordpress"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,18}[a-z0-9]$", var.name_prefix))
    error_message = "name_prefix must be 2 to 20 characters and contain only lowercase letters, numbers, and hyphens, with no leading or trailing hyphen."
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "Optional pair of Availability Zones used by the stack; defaults to two available zones in aws_region"
  default     = null

  validation {
    condition     = var.availability_zones == null || length(var.availability_zones) == 2
    error_message = "availability_zones must contain exactly two Availability Zones."
  }
}

variable "ami_id" {
  type        = string
  description = "Optional AMI used by the launch template; defaults to the latest regional Amazon Linux 2023 x86_64 image"
  default     = null

  validation {
    condition     = var.ami_id == null || can(regex("^ami-[0-9a-f]+$", var.ami_id))
    error_message = "ami_id must be null or a valid AMI ID beginning with ami-."
  }
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "min_size" {
  type    = number
  default = 1

  validation {
    condition     = var.min_size >= 0 && floor(var.min_size) == var.min_size
    error_message = "min_size must be a non-negative integer."
  }
}

variable "max_size" {
  type    = number
  default = 2

  validation {
    condition     = var.max_size >= 0 && floor(var.max_size) == var.max_size
    error_message = "max_size must be a non-negative integer."
  }
}

variable "desired_capacity" {
  type    = number
  default = 1

  validation {
    condition     = var.desired_capacity >= 0 && floor(var.desired_capacity) == var.desired_capacity
    error_message = "desired_capacity must be a non-negative integer."
  }
}

variable "db_name" {
  type    = string
  default = "wordpress"
}

variable "db_user" {
  type    = string
  default = "wordpress"
}

variable "domain_name" {
  type        = string
  description = "The target domain name (e.g., example.com)"
  default     = ""

  validation {
    condition = var.domain_name == "" || can(regex(
      "^(\\*\\.)?([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\\.)+[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$",
      var.domain_name
    ))
    error_message = "domain_name must be null or a valid DNS name such as example.com or *.example.com."
  }
}
