##### DATABASE SUBNET GROUP #####
resource "aws_db_subnet_group" "main" {
  name        = "main-db-subnet-group"
  description = "Subnet group for MySQL database"

  subnet_ids = [
    aws_subnet.private_db_a.id,
    aws_subnet.private_db_b.id
  ]

  tags = {
    Name = "db-subnet-group"
  }
}


##### RDS MYSQL DATABASE #####
resource "aws_db_instance" "mysql" {
  identifier = "wordpress-db"

  engine            = "mysql"
  engine_version    = "8.4.9"
  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true


  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  publicly_accessible     = false
  multi_az                = true
  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false


  tags = {
    Name = "wordpress-db"
  }
}