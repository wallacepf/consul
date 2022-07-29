terraform {
  cloud {
    organization = "my-demo-account"
    workspaces {
      name = "hcp-consul"
    }
  }
  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.15.1"
    }

    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.34.0"
    }

  }
}

provider "consul" {
  address = hcp_consul_cluster.main.consul_public_endpoint_url
  token   = hcp_consul_cluster_root_token.token.secret_id
}

######## LOCALS BLOCK

locals {
  vpc_region = "us-east-1"
  hvn_region = "us-east-1"
  cluster_id = random_id.id.dec
}

######## DATA BLOCK

data "tfe_outputs" "hcp_vault" {
  organization = "my-demo-account"
  workspace    = "hcp-vault"
}

data "tfe_outputs" "vault_configs" {
  organization = "my-demo-account"
  workspace    = "hcp-vault-configs"
}

####### RESOURCE BLOCK
resource "random_id" "id" {
  prefix      = "consul-pov-"
  byte_length = 3
}

resource "hcp_consul_cluster" "main" {
  cluster_id         = local.cluster_id
  hvn_id             = data.tfe_outputs.hcp_vault.values.hvn_id
  public_endpoint    = true
  tier               = "standard"
  size               = "small"
  min_consul_version = "1.12.3"
}

resource "hcp_consul_cluster_root_token" "token" {
  cluster_id = hcp_consul_cluster.main.id
}

resource "consul_certificate_authority" "connect" {
  connect_provider = "vault"

  config = {
    Address             = data.tfe_outputs.hcp_vault.values.vault_private_addr
    Token               = var.vault_token
    RootPKIPath         = "connect_root"
    IntermediatePKIPath = "connect_inter"
    LeafCertTTL         = "1h"
    RotationPeriod      = "144h"
    IntermediateCertTTL = "288h"
    PrivateKeyType      = "ec"
    PrivateKeyBits      = 256
    Namespace           = "admin"
  }

  depends_on = [
    hcp_consul_cluster.main
  ]
}

resource "consul_acl_auth_method" "vault" {
  name = "auth_method"
  type = "oidc"
  max_token_ttl = "5m"

  config_json = jsonencode({
    OIDCDiscoveryURL = "${data.tfe_outputs.hcp_vault.values.vault_private_addr}/v1/admin/identity/oidc/provider/vault-oidc",
    OIDCClientID = var.oidc_client_id,
    OIDCClientSecret = var.oidc_client_secret,
    BoundAudiences = [var.oidc_client_id],
    AllowedRedirectURIs = [
      "https://consul-pov-11814103.consul.5bbc50e3-a284-4743-877e-ffd388d684f2.aws.hashicorp.cloud/oidc/callback",
      "https://consul-pov-11814103.consul.5bbc50e3-a284-4743-877e-ffd388d684f2.aws.hashicorp.cloud/ui/oidc/callback",
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

  depends_on = [
    hcp_consul_cluster.main
  ]
}