###############################################################################
# Networking
###############################################################################
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

###############################################################################
# ALB
###############################################################################
output "alb_dns_name" {
  description = "Public DNS name of the ALB (entry point for the api service)"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

###############################################################################
# ECS
###############################################################################
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = module.ecs.cluster_arn
}

###############################################################################
# RDS
###############################################################################
output "rds_endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "rds_db_name" {
  description = "PostgreSQL database name"
  value       = module.rds.db_name
}

###############################################################################
# ElastiCache
###############################################################################
output "redis_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = module.elasticache.redis_endpoint
  sensitive   = true
}

output "redis_port" {
  description = "ElastiCache Redis port"
  value       = module.elasticache.redis_port
}

###############################################################################
# Secrets
###############################################################################
output "db_password_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the DB password"
  value       = module.secrets.db_password_secret_arn
  sensitive   = true
}

output "redis_auth_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the Redis auth token"
  value       = module.secrets.redis_auth_secret_arn
  sensitive   = true
}
