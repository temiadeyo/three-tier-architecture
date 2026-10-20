output "alb_url" {
  description = "Load balancer URL"
  value       = "http://${aws_lb.main.dns_name}"
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.mysql.address
}
