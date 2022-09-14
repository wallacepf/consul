locals {
  vpc_region = "us-east-1"
}

terraform {
  cloud {
    organization = "my-demo-account"
    workspaces {
      name = "hcp-consul-demo-ecs"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.43"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.18.0"
    }
    doormat = {
      source  = "doormat.hashicorp.services/hashicorp-security/doormat"
      version = "~> 0.0.2"
    }
  }
}

data "tfe_outputs" "iam-arn" {
  organization = "my-demo-account"
  workspace    = "doormat-iam-role"
}

data "tfe_outputs" "hcp_consul" {
  organization = "my-demo-account"
  workspace    = "hcp-consul"
}

data "tfe_outputs" "consul_nw" {
  organization = "my-demo-account"
  workspace    = "hcp-consul-demo-nw"
}

data "doormat_aws_credentials" "creds" {
  provider = doormat

  role_arn = data.tfe_outputs.iam-arn.values.doormat_iam_role_ecs
}

provider "aws" {
  region     = local.vpc_region
  access_key = data.doormat_aws_credentials.creds.access_key
  secret_key = data.doormat_aws_credentials.creds.secret_key
  token      = data.doormat_aws_credentials.creds.token
}

provider "consul" {
  address    = data.tfe_outputs.hcp_consul.values.consul_public_endpoint
  datacenter = data.tfe_outputs.hcp_consul.values.consul_datacenter
  token      = data.tfe_outputs.hcp_consul.values.consul_root_token
}

provider "doormat" {

}

# module "aws_ecs_cluster" {
#   source  = "hashicorp/hcp-consul/aws//modules/hcp-ecs-client"
#   version = "~> 0.7.3"

#   private_subnet_ids       = data.tfe_outputs.consul_nw.values.vpc_private_subnets
#   public_subnet_ids        = data.tfe_outputs.consul_nw.values.vpc_public_subnets
#   vpc_id                   = data.tfe_outputs.consul_nw.values.vpc_id
#   security_group_id        = data.tfe_outputs.consul_nw.values.hcp_consul_sg
#   allowed_ssh_cidr_blocks  = ["0.0.0.0/0"]
#   allowed_http_cidr_blocks = ["0.0.0.0/0"]
#   client_config_file       = data.tfe_outputs.hcp_consul.values.consul_config_file
#   client_ca_file           = data.tfe_outputs.hcp_consul.values.consul_ca_file
#   client_gossip_key        = jsondecode(base64decode(data.tfe_outputs.hcp_consul.values.consul_config_file))["encrypt"]
#   client_retry_join        = jsondecode(base64decode(data.tfe_outputs.hcp_consul.values.consul_config_file))["retry_join"]
#   region                   = local.vpc_region
#   root_token               = data.tfe_outputs.hcp_consul.values.consul_root_token
#   consul_url               = data.tfe_outputs.hcp_consul.values.consul_private_endpoint
#   consul_version           = substr(data.tfe_outputs.hcp_consul.values.consul_version, 1, -1)
#   datacenter               = data.tfe_outputs.hcp_consul.values.consul_datacenter
# }

# output "hashicups_url" {
#   value = "http://${module.aws_ecs_cluster.hashicups_url}"
# }
