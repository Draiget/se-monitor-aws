
output "sm_db_servers_table_id" {
  value = aws_dynamodb_table.sm_servers_table.id
}

output "sm_db_servers_table_arn" {
  value = aws_dynamodb_table.sm_servers_table.arn
}

output "sm_db_players_table_id" {
  value = aws_dynamodb_table.sm_players_table.id
}

output "sm_db_players_table_arn" {
  value = aws_dynamodb_table.sm_players_table.arn
}
