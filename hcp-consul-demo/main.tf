terraform {
  cloud {
    organization = "my-demo-account"
    workspaces {
      name = "hcp-consul-demo"
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

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.12.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.6.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
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

####### PROVIDER BLOCK

provider "aws" {
  region     = local.vpc_region
  access_key = data.doormat_aws_credentials.creds.access_key
  secret_key = data.doormat_aws_credentials.creds.secret_key
  token      = data.doormat_aws_credentials.creds.token
}

provider "tfe" {}

provider "doormat" {}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

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

  role_arn = data.tfe_outputs.iam-arn.values.doormat_iam_role
}