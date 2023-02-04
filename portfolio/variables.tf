variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}
variable aws_profile {
  description   = "AWS profile"
}
variable db_password {
  description   = "DB master password"
  sensitive     = true
}
