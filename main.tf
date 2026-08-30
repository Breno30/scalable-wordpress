variable "vpc_id" {
  type        = string
  description = "VPC ID"
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

resource "aws_vpc" "app" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true 
  enable_dns_hostnames = true 
}


resource "aws_subnet" "app_a" {
  vpc_id = aws_vpc.app.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  
}

resource "aws_subnet" "app_b" {
  vpc_id = aws_vpc.app.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  
}

locals {
  subnet_ids = slice(data.aws_subnets.app.ids, 0, 2)
}

resource "random_string" "db_password" {
  length = 16
  special = false
}

resource "aws_db_instance" "app" {
    engine = "mysql"
    instance_class       = "db.t3.micro"
    db_name = var.db_name
    username = var.db_user
    password = random_string.db_password.result
    allocated_storage = 20
    publicly_accessible = true
    skip_final_snapshot       = true
    

}

resource "aws_efs_file_system" "app" {
    creation_token = "my-product"
  
}

resource "aws_security_group" "efs" {
  
  name = "app-efs"
  vpc_id = aws_vpc.app.id

  ingress {
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
    security_groups = [aws_security_group.app.id]
  }
}

resource "aws_efs_mount_target" "app" {
  for_each = toset(local.subnet_ids)
  file_system_id = aws_efs_file_system.app.id
  subnet_id = each.value
  security_groups = [aws_security_group.efs.id]
}

resource "aws_security_group" "app" {
  vpc_id = aws_vpc.app.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "redis" {
  vpc_id = aws_vpc.app.id

  ingress {
    from_port = 6379
    to_port = 6379
    protocol = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_serverless_cache" "app" {
    engine = "valkey"
  name = "wordpress-sessions"

  security_group_ids = [
    aws_security_group.redis.id
  ]

  subnet_ids = local.subnet_ids
}

resource "aws_launch_template" "app" {
    
    vpc_security_group_ids = [aws_security_group.app.id]

    image_id = var.ami_id

    instance_type = var.instance_type

    key_name = "wordpress"

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

        wp --allow-root core download --path=/usr/share/nginx/html

        wp --allow-root config create --path=/usr/share/nginx/html --dbname='${aws_db_instance.app.db_name}' --dbuser='${aws_db_instance.app.username}' --dbpass='${aws_db_instance.app.password}' --dbhost='${aws_db_instance.app.address}' --dbcharset='utf8mb4' --dbcollate='utf8mb4_unicode_ci'

        sudo chown -R apache:apache /usr/share/nginx/html

        sudo dnf install -y amazon-efs-utils

        sudo mkdir -p /efs

        sudo mount -t efs -o tls ${aws_efs_file_system.app.id}:/ efs

        sudo mkdir -p /efs/uploads

        sudo mkdir -p /usr/share/nginx/html/wp-content/uploads

        sudo chown -R apache:apache /efs/uploads 

        sudo mount --bind /efs/uploads /usr/share/nginx/html/wp-content/uploads

    EOF
    )
}

resource "aws_lb_target_group" "app" {
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.app.id

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

resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app.id
  }
  
}

resource "aws_route_table_association" "app_a" {
  subnet_id = aws_subnet.app_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "app_b" {
  subnet_id = aws_subnet.app_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_lb" "app" {
    internal = false
    load_balancer_type = "application"
    subnets = values(local.subnet_ids)
    security_groups = [aws_security_group.app.id]

    depends_on = [ 
      aws_route_table_association.app_a,
      aws_route_table_association.app_b
     ]
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

    vpc_zone_identifier = local.subnet_ids
    
  
}  