terraform {
  backend "s3" {
    bucket = "sm-state-bucket-dev"
    key    = "tfstate/main"
    region = "us-east-1"
  }
}

module "networking" {
  source = "./networking"

  in_region = "us-east-1"
}

module "functions" {
  source = "./functions"

  in_region = "us-east-1"

  in_api_gw_id = module.networking.api_gw_id
  in_api_gw_operate_method = module.networking.api_gw_operate_method
  in_api_gw_process_method = module.networking.api_gw_process_method

  in_api_gw_operate_resource_path = module.networking.api_gw_operate_resource_path
  in_api_gw_operate_resource_id = module.networking.api_gw_operate_resource_id

  in_api_gw_process_resource_id = module.networking.api_gw_process_resource_id
  in_api_gw_process_resource_path = module.networking.api_gw_process_resource_path

  in_net_security_ids = [module.networking.lambda_security_group_id]
  in_net_subnet_ids = [module.networking.lambda_subnet_id]
}

module "db" {
  source = "./db"
}
