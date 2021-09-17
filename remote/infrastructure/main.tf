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

module "db" {
  source = "./db"
}

module "functions" {
  source = "./functions"

  in_region = "us-east-1"

  in_api_gw_id = module.networking.api_gw_id
  in_api_gw_execution_arn = module.networking.api_gw_execution_arn

  in_api_gw_operate_method = module.networking.api_gw_operate_method

  in_api_gw_operate_resource_path = module.networking.api_gw_operate_resource_path
  in_api_gw_operate_resource_id = module.networking.api_gw_operate_resource_id

  in_db_players_table_arn =  module.db.sm_db_players_table_arn
  in_db_servers_table_arn =  module.db.sm_db_servers_table_arn

  in_net_security_ids = [module.networking.lambda_security_group_id]
  in_net_subnet_ids = [module.networking.lambda_private_subnet_id]
}
