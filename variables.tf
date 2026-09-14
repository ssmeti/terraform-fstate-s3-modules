variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "terraform-user"
}

variable "assume_role_arn" {
  description = "ARN of the role Terraform will assume"
  type        = string
}
