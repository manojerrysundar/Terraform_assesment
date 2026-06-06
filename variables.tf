###############################################################################
# Global
###############################################################################
variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Short name used to prefix all resource names"
  type        = string
  default     = "ecs-platform"
}

variable "environment" {
  description = "Deployment environment (dev / staging / prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

###############################################################################
# Networking
###############################################################################
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to use (2 recommended)"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

###############################################################################
# Secrets Manager
###############################################################################
variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "appuser"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "appdb"
}

variable "secrets_recovery_window" {
  description = "Number of days Secrets Manager retains a deleted secret (0 = immediate)"
  type        = number
  default     = 0
}

###############################################################################
# RDS PostgreSQL
###############################################################################
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL major version — AWS picks the latest available minor automatically"
  type        = string
  default     = "16"
}

variable "db_deletion_protection" {
  description = "Enable deletion protection on the RDS instance"
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot on destroy (set false for prod)"
  type        = bool
  default     = true
}

###############################################################################
# ElastiCache Redis
###############################################################################
variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

###############################################################################
# Container images
###############################################################################
variable "api_image" {
  description = "Docker image for the api service"
  type        = string
  default     = "nginxdemos/hello:latest"
}

variable "orders_image" {
  description = "Docker image for the orders service"
  type        = string
  default     = "nginxdemos/hello:latest"
}

variable "inventory_image" {
  description = "Docker image for the inventory service"
  type        = string
  default     = "nginxdemos/hello:latest"
}

###############################################################################
# Service ports
###############################################################################
variable "api_port" {
  description = "Container port for api service"
  type        = number
  default     = 80
}

variable "orders_port" {
  description = "Container port for orders service"
  type        = number
  default     = 80
}

variable "inventory_port" {
  description = "Container port for inventory service"
  type        = number
  default     = 80
}

###############################################################################
# Task CPU / memory  (Fargate valid combinations)
###############################################################################
variable "api_cpu" {
  description = "CPU units for the api task (256 / 512 / 1024 / 2048 / 4096)"
  type        = number
  default     = 256
}

variable "api_memory" {
  description = "Memory (MiB) for the api task"
  type        = number
  default     = 512
}

variable "orders_cpu" {
  description = "CPU units for the orders task"
  type        = number
  default     = 256
}

variable "orders_memory" {
  description = "Memory (MiB) for the orders task"
  type        = number
  default     = 512
}

variable "inventory_cpu" {
  description = "CPU units for the inventory task"
  type        = number
  default     = 256
}

variable "inventory_memory" {
  description = "Memory (MiB) for the inventory task"
  type        = number
  default     = 512
}
