terraform {
  cloud {
    organization = "my-demo-account"
    workspaces {
      name = "hcp-consul-configs"
    }
  }
  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.15.1"
    }
  }
}

######## PROVIDER BLOCK

provider "consul" {
  address = data.tfe_outputs.hcp_consul.values.consul_public_endpoint
  token   = data.tfe_outputs.hcp_consul.values.consul_root_token
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

data "tfe_outputs" "hcp_consul" {
  organization = "my-demo-account"
  workspace    = "hcp-consul"
}