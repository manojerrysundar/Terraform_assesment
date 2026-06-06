###############################################################################
# modules/ecs/main.tf
###############################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Environment variables injected into all three services
  common_environment = [
    { name = "ENVIRONMENT", value = var.environment },
    { name = "DB_HOST",     value = var.db_host },
    { name = "DB_PORT",     value = tostring(var.db_port) },
    { name = "DB_NAME",     value = var.db_name },
    { name = "DB_USER",     value = var.db_username },
    { name = "REDIS_HOST",  value = var.redis_host },
    { name = "REDIS_PORT",  value = tostring(var.redis_port) },
  ]

  # Secrets pulled from Secrets Manager at task start
  common_secrets = [
    {
      name      = "DB_PASSWORD"
      valueFrom = "${var.db_password_secret_arn}:password::"
    },
    {
      name      = "REDIS_AUTH_TOKEN"
      valueFrom = var.redis_auth_secret_arn
    },
  ]
}

###############################################################################
# ECS Cluster
###############################################################################
resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "${local.name_prefix}-cluster" }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

###############################################################################
# CloudWatch Log Groups
###############################################################################
resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${local.name_prefix}/api"
  retention_in_days = 14
  tags              = { Service = "api" }
}

resource "aws_cloudwatch_log_group" "orders" {
  name              = "/ecs/${local.name_prefix}/orders"
  retention_in_days = 14
  tags              = { Service = "orders" }
}

resource "aws_cloudwatch_log_group" "inventory" {
  name              = "/ecs/${local.name_prefix}/inventory"
  retention_in_days = 14
  tags              = { Service = "inventory" }
}

###############################################################################
# IAM – Task Execution Role (shared by all tasks)
###############################################################################
resource "aws_iam_role" "task_execution" {
  name = "${local.name_prefix}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.name_prefix}-ecs-task-execution-role" }
}

resource "aws_iam_role_policy_attachment" "task_execution_managed" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allow the execution role to read Secrets Manager secrets
resource "aws_iam_role_policy" "secrets_read" {
  name = "${local.name_prefix}-ecs-secrets-read"
  role = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          var.db_password_secret_arn,
          var.redis_auth_secret_arn
        ]
      }
    ]
  })
}

###############################################################################
# IAM – Task Role (for app code to call AWS services)
###############################################################################
resource "aws_iam_role" "task" {
  name = "${local.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "${local.name_prefix}-ecs-task-role" }
}

# Minimal CloudWatch Logs write access for the application itself
resource "aws_iam_role_policy" "task_logs" {
  name = "${local.name_prefix}-task-logs"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

###############################################################################
# Task Definitions
###############################################################################

# ── api ───────────────────────────────────────────────────────────────────────
resource "aws_ecs_task_definition" "api" {
  family                   = "${local.name_prefix}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.api_cpu
  memory                   = var.api_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = var.api_image
      essential = true

      portMappings = [
        {
          containerPort = var.api_port
          protocol      = "tcp"
        }
      ]

      environment = local.common_environment
      secrets     = local.common_secrets

      healthCheck = {
        command     = ["CMD-SHELL", "wget -qO- http://localhost:${var.api_port}/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.api.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "api"
        }
      }

      readonlyRootFilesystem = false
    }
  ])

  tags = { Name = "${local.name_prefix}-task-api" }
}

# ── orders ────────────────────────────────────────────────────────────────────
resource "aws_ecs_task_definition" "orders" {
  family                   = "${local.name_prefix}-orders"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.orders_cpu
  memory                   = var.orders_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "orders"
      image     = var.orders_image
      essential = true

      portMappings = [
        {
          containerPort = var.orders_port
          protocol      = "tcp"
        }
      ]

      environment = local.common_environment
      secrets     = local.common_secrets

      healthCheck = {
        command     = ["CMD-SHELL", "wget -qO- http://localhost:${var.orders_port}/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.orders.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "orders"
        }
      }

      readonlyRootFilesystem = false
    }
  ])

  tags = { Name = "${local.name_prefix}-task-orders" }
}

# ── inventory ─────────────────────────────────────────────────────────────────
resource "aws_ecs_task_definition" "inventory" {
  family                   = "${local.name_prefix}-inventory"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.inventory_cpu
  memory                   = var.inventory_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "inventory"
      image     = var.inventory_image
      essential = true

      portMappings = [
        {
          containerPort = var.inventory_port
          protocol      = "tcp"
        }
      ]

      environment = local.common_environment
      secrets     = local.common_secrets

      healthCheck = {
        command     = ["CMD-SHELL", "wget -qO- http://localhost:${var.inventory_port}/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.inventory.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "inventory"
        }
      }

      readonlyRootFilesystem = false
    }
  ])

  tags = { Name = "${local.name_prefix}-task-inventory" }
}

###############################################################################
# Service Discovery (optional Cloud Map namespace for internal service-to-service)
###############################################################################
resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = "${local.name_prefix}.local"
  vpc         = var.vpc_id
  description = "Private DNS namespace for ${local.name_prefix} services"

  tags = { Name = "${local.name_prefix}-dns-namespace" }
}

resource "aws_service_discovery_service" "orders" {
  name = "orders"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = { Name = "${local.name_prefix}-sd-orders" }
}

resource "aws_service_discovery_service" "inventory" {
  name = "inventory"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = { Name = "${local.name_prefix}-sd-inventory" }
}

###############################################################################
# ECS Services
###############################################################################

# ── api (public, behind ALB) ──────────────────────────────────────────────────
resource "aws_ecs_service" "api" {
  name            = "${local.name_prefix}-api"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.api_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "api"
    container_port   = var.api_port
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  enable_execute_command = true   # allows ECS Exec for debugging

  tags = { Name = "${local.name_prefix}-svc-api" }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# ── orders (internal) ─────────────────────────────────────────────────────────
resource "aws_ecs_service" "orders" {
  name            = "${local.name_prefix}-orders"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.orders.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.orders_sg_id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.orders.arn
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  enable_execute_command = true

  tags = { Name = "${local.name_prefix}-svc-orders" }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# ── inventory (internal) ──────────────────────────────────────────────────────
resource "aws_ecs_service" "inventory" {
  name            = "${local.name_prefix}-inventory"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.inventory.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.inventory_sg_id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.inventory.arn
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  enable_execute_command = true

  tags = { Name = "${local.name_prefix}-svc-inventory" }

  lifecycle {
    ignore_changes = [desired_count]
  }
}
