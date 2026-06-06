output "db_password_secret_arn" {
  description = "ARN of the RDS password secret"
  value       = aws_secretsmanager_secret.db_password.arn
  sensitive   = true
}

output "redis_auth_secret_arn" {
  description = "ARN of the Redis auth token secret"
  value       = aws_secretsmanager_secret.redis_auth.arn
  sensitive   = true
}

output "db_password" {
  description = "Generated DB password (sensitive)"
  value       = random_password.db_password.result
  sensitive   = true
}

output "redis_auth_token" {
  description = "Generated Redis auth token (sensitive)"
  value       = random_password.redis_auth_token.result
  sensitive   = true
}
