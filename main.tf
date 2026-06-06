terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket         = "your-tfstate-bucket"
  #   key            = "ecs-platform/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

###############################################################################
# Networking
###############################################################################
module "networking" {
  source = "./modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}

###############################################################################
# Security Groups
###############################################################################
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  vpc_cidr     = var.vpc_cidr
}

###############################################################################
# Secrets Manager – DB credentials and Redis auth token
###############################################################################
module "secrets" {
  source = "./modules/secrets"

  project_name        = var.project_name
  environment         = var.environment
  db_username         = var.db_username
  db_name             = var.db_name
  recovery_window     = var.secrets_recovery_window
}

###############################################################################
# RDS PostgreSQL
###############################################################################
module "rds" {
  source = "./modules/rds"

  project_name           = var.project_name
  environment            = var.environment
  subnet_ids             = module.networking.private_subnet_ids
  security_group_id      = module.security.rds_sg_id
  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = module.secrets.db_password        # direct sensitive output (avoids plan-time data source issue)
  db_password_secret_arn = module.secrets.db_password_secret_arn
  db_instance_class      = var.db_instance_class
  db_allocated_storage   = var.db_allocated_storage
  db_engine_version      = var.db_engine_version
  deletion_protection    = var.db_deletion_protection
  skip_final_snapshot    = var.db_skip_final_snapshot

  depends_on = [module.secrets]
}

###############################################################################
# ElastiCache Redis
###############################################################################
module "elasticache" {
  source = "./modules/elasticache"

  project_name      = var.project_name
  environment       = var.environment
  subnet_ids        = module.networking.private_subnet_ids
  security_group_id = module.security.redis_sg_id
  node_type         = var.redis_node_type
  engine_version    = var.redis_engine_version
  auth_secret_arn   = module.secrets.redis_auth_secret_arn
  redis_auth_token  = module.secrets.redis_auth_token   # direct sensitive output

  depends_on = [module.secrets]
}

###############################################################################
# ALB
###############################################################################
module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  security_group_id = module.security.alb_sg_id
  api_port          = var.api_port
}

###############################################################################
# ECS Cluster + Services
###############################################################################
module "ecs" {
  source = "./modules/ecs"

  project_name      = var.project_name
  environment       = var.environment
  aws_region        = var.aws_region
  vpc_id            = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  # Security groups
  api_sg_id       = module.security.api_sg_id
  orders_sg_id    = module.security.orders_sg_id
  inventory_sg_id = module.security.inventory_sg_id

  # ALB
  alb_target_group_arn = module.alb.api_target_group_arn

  # Service images
  api_image       = var.api_image
  orders_image    = var.orders_image
  inventory_image = var.inventory_image

  # Port configuration
  api_port       = var.api_port
  orders_port    = var.orders_port
  inventory_port = var.inventory_port

  # Task sizing
  api_cpu       = var.api_cpu
  api_memory    = var.api_memory
  orders_cpu    = var.orders_cpu
  orders_memory = var.orders_memory
  inventory_cpu       = var.inventory_cpu
  inventory_memory    = var.inventory_memory

  # Secrets
  db_password_secret_arn  = module.secrets.db_password_secret_arn
  redis_auth_secret_arn   = module.secrets.redis_auth_secret_arn

  # RDS connection info
  db_host     = module.rds.db_endpoint
  db_port     = module.rds.db_port
  db_name     = var.db_name
  db_username = var.db_username

  # Redis connection info
  redis_host = module.elasticache.redis_endpoint
  redis_port = module.elasticache.redis_port

  depends_on = [module.rds, module.elasticache, module.alb]
}
