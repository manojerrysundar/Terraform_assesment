###############################################################################
# modules/security/main.tf
###############################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ── ALB Security Group ────────────────────────────────────────────────────────
# Open to the internet on port 80 (and 443 if you add TLS later)
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-sg-alb"
  description = "ALB: allow inbound HTTP from internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-sg-alb" }
}

# ── API Service Security Group ────────────────────────────────────────────────
# Accepts traffic from the ALB only
resource "aws_security_group" "api" {
  name        = "${local.name_prefix}-sg-api"
  description = "api service: allow inbound from ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "From ALB"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-sg-api" }
}

# ── Orders Service Security Group ─────────────────────────────────────────────
# Internal only – reachable from api and other services on the private network
resource "aws_security_group" "orders" {
  name        = "${local.name_prefix}-sg-orders"
  description = "orders service: allow inbound from VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "From VPC (internal services)"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-sg-orders" }
}

# ── Inventory Service Security Group ─────────────────────────────────────────
resource "aws_security_group" "inventory" {
  name        = "${local.name_prefix}-sg-inventory"
  description = "inventory service: allow inbound from VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "From VPC (internal services)"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-sg-inventory" }
}

# ── RDS Security Group ────────────────────────────────────────────────────────
# Accepts connections only from the three ECS service SGs
resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-sg-rds"
  description = "RDS: allow PostgreSQL from ECS services only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from api service"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.api.id]
  }

  ingress {
    description     = "PostgreSQL from orders service"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.orders.id]
  }

  ingress {
    description     = "PostgreSQL from inventory service"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.inventory.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-sg-rds" }
}

# ── Redis Security Group ──────────────────────────────────────────────────────
# Accepts connections only from the three ECS service SGs
resource "aws_security_group" "redis" {
  name        = "${local.name_prefix}-sg-redis"
  description = "Redis: allow port 6379 from ECS services only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from api service"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.api.id]
  }

  ingress {
    description     = "Redis from orders service"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.orders.id]
  }

  ingress {
    description     = "Redis from inventory service"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.inventory.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-sg-redis" }
}
