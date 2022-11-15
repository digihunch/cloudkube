output "cognito_info" {
  value = {
    issuer_url = "https://${aws_cognito_user_pool.cognito_user_pool.endpoint}"
    pool_id = aws_cognito_user_pool.cognito_user_pool.id
    pool_arn = aws_cognito_user_pool.cognito_user_pool.arn
    client_id = aws_cognito_user_pool_client.cognito_user_pool_client.id
  }
}
