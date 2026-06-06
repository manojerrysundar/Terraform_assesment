variable "project_name"      { type = string }
variable "environment"       { type = string }
variable "subnet_ids"        { type = list(string) }
variable "security_group_id" { type = string }
variable "node_type"         { type = string }
variable "engine_version"    { type = string }
variable "auth_secret_arn"   { type = string }
