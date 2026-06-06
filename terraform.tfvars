###############################################################################
# terraform.tfvars  –  Development defaults
# Override specific values per environment in environments/dev|staging|prod
###############################################################################

aws_region   = "ap-south-1"
project_name = "ecs-platform"
environment  = "dev"

# ── Networking ────────────────────────────────────────────────────────────────
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["ap-south-1a", "ap-south-1b"]
public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets    = ["10.0.10.0/24", "10.0.11.0/24"]

# ── Database ──────────────────────────────────────────────────────────────────
db_username            = "appuser"
db_name                = "appdb"
db_instance_class      = "db.t3.micro"
db_allocated_storage   = 20
db_engine_version      = "16.3"
db_deletion_protection = false
db_skip_final_snapshot = true      # set to false for prod

# ── ElastiCache ───────────────────────────────────────────────────────────────
redis_node_type    = "cache.t3.micro"
redis_engine_version = "7.1"

# ── Container Images (replace with your own ECR URIs for real workloads) ─────
api_image       = "nginxdemos/hello:latest"
orders_image    = "nginxdemos/hello:latest"
inventory_image = "nginxdemos/hello:latest"

# ── Ports ─────────────────────────────────────────────────────────────────────
# nginxdemos/hello exposes port 80; change if using a real image
api_port       = 80
orders_port    = 80
inventory_port = 80

# ── Task sizing ───────────────────────────────────────────────────────────────
api_cpu       = 256
api_memory    = 512
orders_cpu    = 256
orders_memory = 512
inventory_cpu    = 256
inventory_memory = 512

# ── Secrets recovery ──────────────────────────────────────────────────────────
secrets_recovery_window = 0   # immediate delete in dev; use 7-30 in prod
