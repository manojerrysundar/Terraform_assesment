output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.this.arn
}

output "api_service_name" {
  description = "ECS service name for api"
  value       = aws_ecs_service.api.name
}

output "orders_service_name" {
  description = "ECS service name for orders"
  value       = aws_ecs_service.orders.name
}

output "inventory_service_name" {
  description = "ECS service name for inventory"
  value       = aws_ecs_service.inventory.name
}

output "task_execution_role_arn" {
  description = "ARN of the shared ECS task execution role"
  value       = aws_iam_role.task_execution.arn
}

output "service_discovery_namespace" {
  description = "Private DNS namespace for internal service discovery"
  value       = aws_service_discovery_private_dns_namespace.this.name
}
