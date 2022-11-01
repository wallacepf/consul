terraform {
  cloud {
    organization = "my-demo-account"
    workspaces {
      name = "hcp-consul-demo-nw"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.43"
    }

    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.33.0"
    }

    doormat = {
      source  = "doormat.hashicorp.services/hashicorp-security/doormat"
      version = "~> 0.0.2"
    }

    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.32.1"
    }
  }

}

######## LOCALS BLOCK

locals {
  vpc_region = "us-east-1"
}

####### PROVIDER BLOCK

provider "aws" {
  region     = local.vpc_region
  access_key = data.doormat_aws_credentials.creds.access_key
  secret_key = data.doormat_aws_credentials.creds.secret_key
  token      = data.doormat_aws_credentials.creds.token
}

provider "tfe" {}

provider "doormat" {}

provider "consul" {
  address    = data.tfe_outputs.hcp_consul.values.consul_public_endpoint
  datacenter = data.tfe_outputs.hcp_consul.values.consul_datacenter
  token      = data.tfe_outputs.hcp_consul.values.consul_root_token
}

###### DATA BLOCK

data "tfe_outputs" "iam-arn" {
  organization = "my-demo-account"
  workspace    = "doormat-iam-role"
}

data "doormat_aws_credentials" "creds" {
  provider = doormat

  role_arn = data.tfe_outputs.iam-arn.values.doormat_iam_role_nw
}

######## DATA BLOCK

data "tfe_outputs" "hcp_vault" {
  organization = "my-demo-account"
  workspace    = "hcp-vault"
}

data "tfe_outputs" "hcp_consul" {
  organization = "my-demo-account"
  workspace    = "hcp-consul"
}

data "aws_availability_zones" "available" {
  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

####### RESOURCE BLOCK

resource "random_id" "id" {
  prefix      = "consul-pov"
  byte_length = 3
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.4"

  name                 = "${random_id.id.dec}-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets      = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

module "aws_hcp_consul" {
  source  = "hashicorp/hcp-consul/aws"
  version = "0.7.3"

  hvn             = data.tfe_outputs.hcp_vault.values.hvn
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  route_table_ids = module.vpc.private_route_table_ids
  # security_group_ids = [module.vpc.default_security_group_id]
}