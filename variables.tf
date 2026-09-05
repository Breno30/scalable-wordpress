# Input variables
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
}