resource "aws_launch_template" "app" {
    
    vpc_security_group_ids = ["sg-0c7b92557fa5b1c1d"]

    image_id = "ami-0bdc7d025135d7b49"

    instance_type = "t3.micro"


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
    vpc_id = "vpc-0ec65c595e103120b"
}

resource "aws_lb" "app" {
    internal = false
    load_balancer_type = "application"
    subnets = ["subnet-03da0a5486c213aae", "subnet-02a5d31f007e28973"]
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
    min_size = 1
    max_size = 2
    desired_capacity = 2

    launch_template {
        id  = aws_launch_template.app.id
        version = "2"
    }

    target_group_arns = [aws_lb_target_group.app.arn]

    vpc_zone_identifier = ["subnet-03da0a5486c213aae", "subnet-02a5d31f007e28973"]
    
  
}