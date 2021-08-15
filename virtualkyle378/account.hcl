locals {
  account_name = "${basename(get_terragrunt_dir())}"
  state_bucket = "terraform-state-022173080583"
  state_lock_dynamodb_table = "terraform-state-lock-022173080583"
  alb_access_logs_bucket = "alb-access-logs"
}