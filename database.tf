resource "aws_db_subnet_group" "app" {
  name = "wordpress-db"
  subnet_ids = [
    aws_subnet.db_a.id,
    aws_subnet.db_b.id
  ]
}

resource "aws_db_instance" "app" {
  engine                      = "mysql"
  instance_class              = "db.t3.micro"
  db_name                     = var.db_name
  username                    = var.db_user
  manage_master_user_password = true
  allocated_storage           = 20
  db_subnet_group_name        = aws_db_subnet_group.app.name
  vpc_security_group_ids      = [aws_security_group.db.id]
  publicly_accessible         = false
  skip_final_snapshot         = true


}
