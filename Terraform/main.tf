module "nginxdemo" {
  source = "./modules/nginxdemo"

  environment_name = var.environment_name
}
