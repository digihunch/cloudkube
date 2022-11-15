resource "aws_cognito_user_pool" "cognito_user_pool" {
  name = "${var.resource_prefix}-oidc-userpool"
  tags = merge(var.resource_tags, { Name = "${var.resource_prefix}-cognito-user-pool" })
  password_policy {
    require_lowercase = false
    require_numbers = false
    require_symbols = false
    require_uppercase = false
    minimum_length = 8
  }
  admin_create_user_config {
    allow_admin_create_user_only = false
  }
  username_attributes = ["email"]
  #auto_verified_attributes = ["email"]
  username_configuration {
    case_sensitive = false 
  }
}

resource "aws_cognito_user_pool_client" "cognito_user_pool_client" {
  name = "oidc-client"
  user_pool_id = aws_cognito_user_pool.cognito_user_pool.id
  generate_secret = false
  explicit_auth_flows = ["ALLOW_REFRESH_TOKEN_AUTH","ALLOW_ADMIN_USER_PASSWORD_AUTH","ALLOW_USER_PASSWORD_AUTH"]
  allowed_oauth_flows_user_pool_client = false
  allowed_oauth_flows = []
  allowed_oauth_scopes = []
  prevent_user_existence_errors = "ENABLED"
}

resource "aws_cognito_user_pool_domain" "cognito_user_pool_domain" {
  domain = "${var.resource_prefix}-userpool"
  user_pool_id = aws_cognito_user_pool.cognito_user_pool.id
}

resource "aws_cognito_user_group" "cognito_user_group_cluster_admin" {
  name = var.cluster_admin_cognito_group 
  user_pool_id = aws_cognito_user_pool.cognito_user_pool.id
}

resource "aws_cognito_user" "cognito_user_init_admin" {
  user_pool_id = aws_cognito_user_pool.cognito_user_pool.id
  username = var.init_admin_email 
  password = "Blah123$"
  attributes = {
    email = var.init_admin_email
    email_verified = true
  }
}

resource "aws_cognito_user_in_group" "cognito_user_group_assignment" {
  user_pool_id = aws_cognito_user_pool.cognito_user_pool.id
  group_name   = aws_cognito_user_group.cognito_user_group_cluster_admin.name
  username     = aws_cognito_user.cognito_user_init_admin.username
}
