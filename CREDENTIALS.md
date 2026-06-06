# AWS Credentials Setup Guide

Terraform needs AWS credentials to create resources. **Never put credentials
in `.tf` or `.tfvars` files — they will end up in your git history.**

Choose one of the three methods below.

---

## Method 1 — Environment Variables (Quickest for local dev)

```bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="wJalrXUtn..."
export AWS_DEFAULT_REGION="ap-south-1"

# Then run Terraform as normal
terraform init
terraform plan
terraform apply
```

Variables are only set for the current shell session — they are gone when you
close the terminal. Safe for short-lived local work.

---

## Method 2 — AWS CLI Named Profile (Recommended for daily use)

### 2a. Configure the profile

```bash
aws configure --profile ecs-platform
# AWS Access Key ID:     AKIA...
# AWS Secret Access Key: wJalr...
# Default region:        ap-south-1
# Default output format: json
```

This writes to `~/.aws/credentials` and `~/.aws/config` on your machine —
**not** inside this project.

### 2b. Tell Terraform which profile to use

**Option A — environment variable (preferred, no code change needed):**
```bash
export AWS_PROFILE=ecs-platform
terraform apply
```

**Option B — in `main.tf` provider block (committed to code, fine for non-prod):**
```hcl
provider "aws" {
  region  = var.aws_region
  profile = "ecs-platform"   # add this line
}
```

---

## Method 3 — IAM Role (CI/CD / GitHub Actions / EC2)

If running from GitHub Actions, an EC2 instance, or any AWS service, use an
IAM Role instead of static keys.

### GitHub Actions example

```yaml
# .github/workflows/deploy.yml
permissions:
  id-token: write   # needed for OIDC
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
      aws-region: ap-south-1

  - name: Terraform Apply
    run: |
      terraform init
      terraform apply -auto-approve
```

Create the `GitHubActionsRole` in IAM with a trust policy for
`token.actions.githubusercontent.com` and the permissions listed in the README.

---

## Where to get your Access Key ID and Secret

1. Log in to the AWS Console → **IAM** → **Users** → your username
2. **Security credentials** tab → **Create access key**
3. Choose **CLI / local development**
4. Copy both values — the secret is shown only once

Store them in a password manager (1Password, Bitwarden, etc.) rather than a
plain-text file.

---

## Minimum IAM Permissions Required

Attach these AWS-managed policies to your IAM user / role, or use a custom
policy covering the actions listed in the README:

| Policy | Why needed |
|--------|-----------|
| `AmazonVPCFullAccess` | VPC, subnets, IGW, NAT, SGs |
| `AmazonECS_FullAccess` | ECS cluster, services, task definitions |
| `ElasticLoadBalancingFullAccess` | ALB, target groups, listeners |
| `AmazonRDSFullAccess` | RDS instances, subnet groups, param groups |
| `AmazonElastiCacheFullAccess` | ElastiCache clusters, subnet groups |
| `SecretsManagerReadWrite` | Secrets Manager secrets |
| `IAMFullAccess` | Task execution / task IAM roles |
| `CloudWatchLogsFullAccess` | CloudWatch log groups |
| `AWSCloudMapFullAccess` | Service discovery namespace + services |

For tighter security create a single custom policy scoped to only the
resources this project creates (use the ARN prefix `ecs-platform-dev-*`).
