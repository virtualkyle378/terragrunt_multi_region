
variable "vpc_id" {
  type = string
  description = "vpc id"
  default = ""
}

variable "app_name" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
  description = "Public subnet ids"
  default = []
}

variable "standard_tags_no_name" {
  type = map(string)
}
