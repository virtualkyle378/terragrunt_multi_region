resource "aws_dynamodb_table" "state_lock_table" {
  name = "terraform-state-lock-022173080583"
  read_capacity  = 5
  write_capacity = 5

  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}