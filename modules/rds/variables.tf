variable "project_name"          { type = string }
variable "environment"           { type = string }
variable "subnet_ids"            { type = list(string) }
variable "security_group_id"     { type = string }
variable "db_name"               { type = string }
variable "db_username"           { type = string }
# Plain-text password sourced from the secrets module (sensitive)
variable "db_password" {
  type      = string
  sensitive = true
}
variable "db_password_secret_arn" { type = string }   # kept for IAM policy scoping in ECS module
variable "db_instance_class"      { type = string }
variable "db_allocated_storage"   { type = number }
variable "db_engine_version"      { type = string }
variable "deletion_protection"    { type = bool }
variable "skip_final_snapshot"    { type = bool }
