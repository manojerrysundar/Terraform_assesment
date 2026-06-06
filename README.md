# ECS Fargate Platform – Terraform

Three microservices (`api`, `orders`, `inventory`) running on AWS ECS Fargate in `ap-south-1`, sharing a single RDS PostgreSQL database and ElastiCache Redis cluster.

---

## Architecture

```
Internet
   │
   ▼
[ALB] ─────────────────────────► api (Fargate, private subnet)
                                    │
              ┌─────────────────────┤ internal VPC routing
              ▼                     ▼
         orders (Fargate)     inventory (Fargate)
              │                     │
              └──────────┬──────────┘
                         ▼
              ┌─────────────────────┐
              │  RDS PostgreSQL     │  (private subnet, no public access)
              │  ElastiCache Redis  │  (private subnet, TLS + auth token)
              └─────────────────────┘
```

| Service   | Port | External | Uses         |
|-----------|------|----------|--------------|
| api       | 80   | Yes (ALB)| Redis        |
| orders    | 80   | No       | RDS, Redis   |
| inventory | 80   | No       | RDS, Redis   |

Internal service addresses (Cloud Map):
- `orders.ecs-platform-dev.local`
- `inventory.ecs-platform-dev.local`

---

## Module Structure

```
.
├── main.tf                  # Root – wires all modules
├── variables.tf             # All input variable declarations
├── outputs.tf               # Key outputs (ALB DNS, endpoints, etc.)
├── terraform.tfvars         # Dev defaults
└── modules/
    ├── networking/          # VPC, subnets, IGW, NAT, route tables
    ├── security/            # All security groups (least-privilege)
    ├── secrets/             # Secrets Manager – DB password & Redis token
    ├── rds/                 # RDS PostgreSQL (private, encrypted)
    ├── elasticache/         # ElastiCache Redis (TLS, auth token)
    ├── alb/                 # Application Load Balancer + target group
    └── ecs/                 # ECS cluster, task definitions, IAM, services
```

---

## Prerequisites

| Tool      | Version  |
|-----------|----------|
| Terraform | ≥ 1.9.0  |
| AWS CLI   | ≥ 2.x    |

### AWS credentials

```bash
export AWS_PROFILE=your-profile
# or
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=ap-south-1
```

The IAM principal needs these permissions:
- `ec2:*` (VPC, subnets, SGs, EIPs, NAT)
- `ecs:*`
- `elasticloadbalancing:*`
- `rds:*`
- `elasticache:*`
- `secretsmanager:*`
- `iam:*` (task roles)
- `logs:*`
- `servicediscovery:*`

---

## Deploy

```bash
# 1. Clone / enter the project directory
cd ecs-platform

# 2. Initialise providers and modules
terraform init

# 3. Review the execution plan
terraform plan -out=tfplan

# 4. Apply
terraform apply tfplan
```

After a successful apply (~15-20 minutes the first time due to RDS), Terraform prints:

```
alb_dns_name = "ecs-platform-dev-alb-<id>.ap-south-1.elb.amazonaws.com"
ecs_cluster_name = "ecs-platform-dev-cluster"
...
```

### Verify the api endpoint

```bash
ALB=$(terraform output -raw alb_dns_name)
curl http://$ALB/
```

You should receive an HTTP 200 from the placeholder container.

---

## Tear Down

```bash
terraform destroy
```

> **Note:** RDS and ElastiCache take 5-10 minutes to delete. The destroy will wait for them automatically.

If `secrets_recovery_window` is set to a non-zero value the Secrets Manager secrets will enter a "pending deletion" state and cannot be recreated with the same name until the window expires. Set it to `0` (the default in `terraform.tfvars`) for dev to allow immediate re-creation.

---

## Replacing Placeholder Images

The default `terraform.tfvars` uses `nginxdemos/hello:latest` for all three services. To use real application images, update the tfvars (or pass them on the CLI):

```hcl
# terraform.tfvars
api_image       = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/api:v1.0"
orders_image    = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/orders:v1.0"
inventory_image = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/inventory:v1.0"
```

If using ECR, add the following policy to the `task_execution` IAM role in `modules/ecs/main.tf`:

```hcl
resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
```

---

## Secrets Injection

Secrets are **never** in source code or Terraform state in plain text:

| Secret           | Secrets Manager path              | Injected as env var |
|------------------|-----------------------------------|---------------------|
| DB password      | `ecs-platform/dev/rds/db-password`| `DB_PASSWORD`       |
| Redis auth token | `ecs-platform/dev/redis/auth-token`| `REDIS_AUTH_TOKEN` |

The ECS task execution role has `secretsmanager:GetSecretValue` permission scoped to only these two ARNs.

---

## Remote State (Recommended for Teams)

Uncomment the `backend "s3"` block in `main.tf` and create the bucket + DynamoDB table first:

```bash
aws s3api create-bucket \
  --bucket my-tfstate-bucket \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

---

## Assumptions

- **Single NAT Gateway** (first AZ) – reduces cost in dev. For production add one per AZ.
- **Single RDS instance** – no Multi-AZ. Enable `multi_az = true` for production.
- **Single Redis node** – `num_cache_clusters = 1` with `automatic_failover_enabled = false`. For HA set both to 2/true.
- **HTTP only** – the ALB listener is port 80. For HTTPS, add an ACM certificate and an HTTPS listener.
- **Health checks** use `wget` against `/` (port 80) for the placeholder containers. Update the path and port for real services.
- **ECS Exec** (`enable_execute_command = true`) is enabled on all services for easy debugging.
- `db_skip_final_snapshot = true` is set for dev. Set to `false` for production.
- `deletion_protection = false` for dev. Set to `true` for production.
