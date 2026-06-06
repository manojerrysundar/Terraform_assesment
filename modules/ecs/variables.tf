variable "project_name"          { type = string }
variable "environment"           { type = string }
variable "aws_region"            { type = string }
variable "vpc_id"                { type = string }
variable "private_subnet_ids"    { type = list(string) }

variable "api_sg_id"             { type = string }
variable "orders_sg_id"          { type = string }
variable "inventory_sg_id"       { type = string }

variable "alb_target_group_arn"  { type = string }

variable "api_image"             { type = string }
variable "orders_image"          { type = string }
variable "inventory_image"       { type = string }

variable "api_port"              { type = number }
variable "orders_port"           { type = number }
variable "inventory_port"        { type = number }

variable "api_cpu"               { type = number }
variable "api_memory"            { type = number }
variable "orders_cpu"            { type = number }
variable "orders_memory"         { type = number }
variable "inventory_cpu"         { type = number }
variable "inventory_memory"      { type = number }

variable "db_password_secret_arn" { type = string }
variable "redis_auth_secret_arn"  { type = string }

variable "db_host"     { type = string }
variable "db_port"     { type = number }
variable "db_name"     { type = string }
variable "db_username" { type = string }

variable "redis_host" { type = string }
variable "redis_port" { type = number }
