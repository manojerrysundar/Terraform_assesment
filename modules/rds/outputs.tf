output "db_endpoint" {
  description = "RDS endpoint address (hostname only)"
  value       = aws_db_instance.this.address
  sensitive   = true
}

output "db_port" {
  description = "RDS port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.identifier
}
