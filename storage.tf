resource "aws_efs_file_system" "app" {
  creation_token = "my-product"

}

resource "aws_efs_mount_target" "app" {
  for_each        = local.private_app_subnet_ids
  file_system_id  = aws_efs_file_system.app.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}
