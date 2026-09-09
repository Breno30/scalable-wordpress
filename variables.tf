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
  description = "Two Availability Zones used by the stack"
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "availability_zones must contain exactly two Availability Zones."
  }
}

variable "ami_id" {
  type        = string
  description = "AMI used by the launch template"
  default     = "ami-0bdc7d025135d7b49" // Amazon Linux 2023 us-east-1
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 2
}

variable "desired_capacity" {
  type    = number
  default = 1
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

  validation {
    condition = var.domain_name == "" || can(regex(
      "^(\\*\\.)?([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\\.)+[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$",
      var.domain_name
    ))
    error_message = "domain_name must be null or a valid DNS name such as example.com or *.example.com."
  }
}
