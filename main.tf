module "vpc" {
  source       = "./modules/vpc"
  project_name = "fifth-project"
  aws_region   = var.aws_region
}
