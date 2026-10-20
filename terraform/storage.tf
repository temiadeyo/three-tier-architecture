##### EFS FILE SYSTEM #####
resource "aws_efs_file_system" "website" {
  creation_token = "wordpress-efs"

  encrypted = true

  tags = {
    Name = "wordpress-efs"
  }
}


##### EFS MOUNT TARGET - AZ A #####
resource "aws_efs_mount_target" "app_a" {
  file_system_id = aws_efs_file_system.website.id

  subnet_id = aws_subnet.private_app_a.id

  security_groups = [aws_security_group.efs.id]
}


##### EFS MOUNT TARGET - AZ B #####
resource "aws_efs_mount_target" "app_b" {
  file_system_id = aws_efs_file_system.website.id

  subnet_id = aws_subnet.private_app_b.id

  security_groups = [aws_security_group.efs.id]
}