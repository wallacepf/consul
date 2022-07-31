variable "vault_oidc_client_id" {}

variable "vault_oidc_client_secret" {
  sensitive = true
}

variable "okta_oidc_client_id" {}

variable "okta_oidc_client_secret" {
  sensitive = true
}

variable "auth0_oidc_client_id" {}

variable "auth0_oidc_client_secret" {
  sensitive = true
}

variable "vault_token" {}