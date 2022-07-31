terraform {
  cloud {
    organization = "my-demo-account"
    workspaces {
      name = "hcp-consul"
    }
  }
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.34.0"
    }

  }
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