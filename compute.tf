

resource "aws_launch_template" "app" {

  name_prefix = "${var.name_prefix}-app-"

  image_id = var.ami_id

  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.wordpress.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    device_index                = 0
    security_groups             = [aws_security_group.app.id]
  }

  user_data = base64encode(templatefile("${path.module}/scripts/bootstrap-wordpress.sh.tftpl", {
    cache_host    = aws_elasticache_serverless_cache.app.endpoint[0].address
    cache_port    = aws_elasticache_serverless_cache.app.endpoint[0].port
    db_host       = aws_db_instance.app.address
    db_name       = aws_db_instance.app.db_name
    db_secret_arn = aws_db_instance.app.master_user_secret[0].secret_arn
    efs_file_id   = aws_efs_file_system.app.id
    wordpress_dir = "/usr/share/nginx/html"
  }))
}

# Auto Scaling
resource "aws_autoscaling_group" "app" {
  name_prefix      = "${var.name_prefix}-app-"
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  health_check_type         = "ELB"
  health_check_grace_period = 300

  default_instance_warmup = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app.arn]

  vpc_zone_identifier = values(local.private_app_subnet_ids)

  depends_on = [aws_efs_mount_target.app]

}

resource "aws_autoscaling_policy" "app_cpu_target" {
  name                   = "${var.name_prefix}-average-cpu"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60
  }
}
