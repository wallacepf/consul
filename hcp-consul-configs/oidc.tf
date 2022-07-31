resource "consul_acl_auth_method" "vault" {
  name          = "Vault"
  type          = "oidc"
  max_token_ttl = "5m"

  config_json = jsonencode({
    OIDCDiscoveryURL = "${data.tfe_outputs.hcp_vault.values.vault_private_addr}/v1/admin/identity/oidc/provider/vault-oidc",
    OIDCClientID     = var.vault_oidc_client_id,
    OIDCClientSecret = var.vault_oidc_client_secret,
    BoundAudiences   = [var.vault_oidc_client_id],
    AllowedRedirectURIs = [
      "${data.tfe_outputs.hcp_consul.values.consul_public_endpoint}/oidc/callback",
      "${data.tfe_outputs.hcp_consul.values.consul_public_endpoint}/ui/oidc/callback",
      "http://127.0.0.1:8500/ui/oidc/callback"
    ],
    ClaimMappings = {
      "http://consul.internal/email" : "email",
      "http://consul.internal/phone_number" : "phone_number"
    },
    ListClaimMappings = {
      "http://consul.internal/groups" : "groups"
    }
  })

}

resource "consul_acl_auth_method" "okta" {
  name          = "Okta"
  type          = "oidc"
  max_token_ttl = "5m"

  config_json = jsonencode({
    OIDCDiscoveryURL = "https://trial-7800845.okta.com/oauth2/aus1uwgf27Sz7OLEt697",
    OIDCClientID     = var.okta_oidc_client_id,
    OIDCClientSecret = var.okta_oidc_client_secret,
    BoundAudiences   = [var.okta_oidc_client_id],
    AllowedRedirectURIs = [
      "${data.tfe_outputs.hcp_consul.values.consul_public_endpoint}/oidc/callback",
      "${data.tfe_outputs.hcp_consul.values.consul_public_endpoint}/ui/oidc/callback",
      "http://127.0.0.1:8500/ui/oidc/callback"
    ],
    ClaimMappings = {
      "first_name" : "first_name",
      "last_name" : "last_name"
    },
    ListClaimMappings = {
      "groups" : "groups"
    }
  })

}

resource "consul_acl_binding_rule" "okta_users" {
  auth_method = consul_acl_auth_method.okta.name
  selector    = "consulUsers in list.groups"
  bind_type   = "role"
  bind_name   = "dev-ro"
}

resource "consul_acl_auth_method" "auth0" {
  name          = "Auth0"
  type          = "oidc"
  max_token_ttl = "5m"

  config_json = jsonencode({
    OIDCDiscoveryURL = "https://dev-c2lfpu1i.us.auth0.com/",
    OIDCClientID     = var.auth0_oidc_client_id,
    OIDCClientSecret = var.auth0_oidc_client_secret,
    BoundAudiences   = [var.auth0_oidc_client_id],
    AllowedRedirectURIs = [
      "${data.tfe_outputs.hcp_consul.values.consul_public_endpoint}/oidc/callback",
      "${data.tfe_outputs.hcp_consul.values.consul_public_endpoint}/ui/oidc/callback",
      "http://127.0.0.1:8500/ui/oidc/callback"
    ],
    ClaimMappings = {
      "http://consul.internal/first_name" : "first_name",
      "http://consul.internal/last_name" : "last_name"
    },
    ListClaimMappings = {
      "http://consul.internal/groups" : "groups"
    }
  })

}

resource "consul_acl_binding_rule" "auth0_users" {
  auth_method = consul_acl_auth_method.auth0.name
  selector    = "users in list.groups"
  bind_type   = "role"
  bind_name   = "dev-ro"
}