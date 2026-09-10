resource "aws_db_subnet_group" "app" {
  name = "${var.name_prefix}-db"
  subnet_ids = [
    aws_subnet.db_a.id,
    aws_subnet.db_b.id
  ]
}

resource "aws_db_instance" "app" {
  identifier                  = "${var.name_prefix}-db"
  engine                      = "mysql"
  instance_class              = "db.t3.small"
  db_name                     = var.db_name
  username                    = var.db_user
  manage_master_user_password = true
  allocated_storage           = 20
  max_allocated_storage       = 100
  storage_type                = "gp3"
  storage_encrypted           = true
  db_subnet_group_name        = aws_db_subnet_group.app.name
  vpc_security_group_ids      = [aws_security_group.db.id]
  publicly_accessible         = false
  multi_az                    = true
  backup_retention_period     = 14
  copy_tags_to_snapshot       = true
  deletion_protection         = var.deletion_protection
  skip_final_snapshot         = false
  final_snapshot_identifier   = "${var.name_prefix}-final-snapshot"
}
