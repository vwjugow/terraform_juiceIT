output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.shop-be.address
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.shop-be.port
  sensitive   = true
}

output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.shop-be.username
  sensitive   = true
}

output "rds_pw" {
  description = "RDS instance root password"
  value       = aws_db_instance.shop-be.password
  sensitive   = true
}
