variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets for ALB and ASG"
}

variable "security_group_id" {
  type        = string
  description = "Security group for EC2 instances"
}

variable "ami_id" {
  type        = string
  description = "AMI used by the launch template"
}

variable "instance_type" {
  type        = string
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
  default = 2
}

variable "db_name" {
  type    = string
  default = "wordpress"
}

variable "db_user" {
  type    = string
  default = "wordpress"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_host" {
  type        = string
  description = "RDS endpoint"
}


resource "aws_launch_template" "app" {
    
    vpc_security_group_ids = [var.security_group_id]

    image_id = var.ami_id

    instance_type = var.instance_type


    user_data = base64encode(<<-EOF
        #!/bin/bash

        sudo dnf update -y

        sudo dnf install -y   nginx   php   php-fpm   php-mysqlnd   php-curl   php-gd   php-mbstring   php-xml   php-zip   php-intl   php-cli   nfs-utils   wget   unzip mariadb105

        sudo systemctl enable --now nginx
        sudo systemctl enable --now php-fpm

        sudo rm -r /usr/share/nginx/html/*

        sudo curl -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /tmp/wp
        sudo chmod +x /tmp/wp
        sudo mv /tmp/wp /usr/local/bin/wp

        sudo sed -i 's/^memory_limit = .*/memory_limit = 512M/' /etc/php.ini

        sudo chown -R ec2-user:ec2-user /usr/share/nginx/html

        wp --allow-root core download --path=/usr/share/nginx/html

        wp --allow-root config create --path=/usr/share/nginx/html --dbname='wordpress' --dbuser='wordpress' --dbpass='wordpress' --dbhost='wordpress.cdugk0ikk1pg.us-east-1.rds.amazonaws.com' --dbcharset='utf8mb4' --dbcollate='utf8mb4_unicode_ci'

    EOF
    )
}

resource "aws_lb_target_group" "app" {
    port = 80
    protocol = "HTTP"
    vpc_id = var.vpc_id

    health_check {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200-399"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 3
    }
}

resource "aws_lb" "app" {
    internal = false
    load_balancer_type = "application"
    subnets = var.subnet_ids
}

resource "aws_lb_listener" "app" {
    load_balancer_arn =  aws_lb.app.arn
    port = 80
    protocol = "HTTP"

    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.app.arn
    }
  
}

resource "aws_autoscaling_group" "app" {
    min_size = var.min_size
    max_size = var.max_size
    desired_capacity = var.desired_capacity

    launch_template {
        id  = aws_launch_template.app.id
        version = "$Latest"
    }

    target_group_arns = [aws_lb_target_group.app.arn]

    vpc_zone_identifier = var.subnet_ids
    
  
}  