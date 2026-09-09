resource "aws_elasticache_serverless_cache" "app" {
  engine = "valkey"
  name   = "${var.name_prefix}-sessions"

  security_group_ids = [
    aws_security_group.redis.id
  ]

  subnet_ids = values(local.private_app_subnet_ids)
}
