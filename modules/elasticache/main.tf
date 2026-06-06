###############################################################################
# modules/elasticache/main.tf
###############################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ── Subnet Group ──────────────────────────────────────────────────────────────
resource "aws_elasticache_subnet_group" "this" {
  name        = "${local.name_prefix}-redis-subnet-group"
  description = "ElastiCache subnet group for ${local.name_prefix}"
  subnet_ids  = var.subnet_ids

  tags = { Name = "${local.name_prefix}-redis-subnet-group" }
}

# ── Parameter Group ───────────────────────────────────────────────────────────
resource "aws_elasticache_parameter_group" "this" {
  name        = "${local.name_prefix}-redis71"
  family      = "redis7"
  description = "Redis 7.x parameter group for ${local.name_prefix}"

  tags = { Name = "${local.name_prefix}-redis-param-group" }
}

# ── Redis Replication Group (single-node for dev) ─────────────────────────────
# NOTE: auth_token is passed directly from secrets module output (sensitive var)
# to avoid a plan-time Secrets Manager data source chicken-and-egg problem.
# auth_token_update_strategy is set to "ROTATE" which is required by the AWS
# provider v5.x when transit_encryption_enabled = true.
resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${local.name_prefix}-redis"
  description          = "Redis for ${local.name_prefix}"

  engine         = "redis"
  engine_version = var.engine_version
  node_type      = var.node_type
  port           = 6379

  # Single-node (no replica) – set num_cache_clusters = 2 + automatic_failover_enabled = true for HA
  num_cache_clusters         = 1
  automatic_failover_enabled = false

  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [var.security_group_id]
  parameter_group_name = aws_elasticache_parameter_group.this.name

  # Auth + encryption
  # auth_token requires transit_encryption_enabled = true (TLS)
  auth_token                 = var.redis_auth_token
  auth_token_update_strategy = "ROTATE"  # required by AWS provider >=5.x when auth_token present
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true

  # Maintenance / backup
  maintenance_window       = "sun:05:00-sun:06:00"
  snapshot_retention_limit = 1
  snapshot_window          = "03:00-04:00"

  apply_immediately = true

  tags = { Name = "${local.name_prefix}-redis" }
}
