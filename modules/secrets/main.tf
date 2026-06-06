###############################################################################
# modules/secrets/main.tf
###############################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ── Random passwords ──────────────────────────────────────────────────────────
resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}|:,.<>?"
}

resource "random_password" "redis_auth_token" {
  length  = 32
  special = false # ElastiCache auth tokens must be alphanumeric
}

# ── DB password secret ────────────────────────────────────────────────────────
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${local.name_prefix}/rds/db-password"
  description             = "PostgreSQL master password for ${local.name_prefix}"
  recovery_window_in_days = var.recovery_window

  # Prevents "already exists" if a previous partial apply left this secret
  # behind. Safe because recovery_window_in_days = 0 means instant delete.
  force_overwrite_replica_secret = true

  tags = { Name = "${local.name_prefix}-secret-db-password" }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    dbname   = var.db_name
  })
}

# ── Redis auth token secret ───────────────────────────────────────────────────
resource "aws_secretsmanager_secret" "redis_auth" {
  name                    = "${local.name_prefix}/redis/auth-token"
  description             = "Redis auth token for ${local.name_prefix}"
  recovery_window_in_days = var.recovery_window

  # Same protection as above
  force_overwrite_replica_secret = true

  tags = { Name = "${local.name_prefix}-secret-redis-auth" }
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id     = aws_secretsmanager_secret.redis_auth.id
  secret_string = random_password.redis_auth_token.result
}
