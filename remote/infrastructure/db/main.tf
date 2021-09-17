#
# Servers cache table definition (DynamoDB)
#
resource "aws_dynamodb_table" "sm_servers_table" {
  name           = "servers"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "IpPort"

  attribute {
    name = "IpPort"
    type = "S"
  }

  ttl {
    attribute_name = "TimeLastOnline"
    enabled        = true
  }

  tags = {
    env = "dev"
  }
}

#
# Players cache table definition (DynamoDB)
#
resource "aws_dynamodb_table" "sm_players_table" {
  name           = "players"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "Name"

  attribute {
    name = "Name"
    type = "S"
  }

  ttl {
    attribute_name = "TimeLastOnline"
    enabled        = true
  }

  tags = {
    env = "dev"
  }
}
