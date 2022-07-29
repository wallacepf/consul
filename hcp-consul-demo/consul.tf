######## LOCALS BLOCK

locals {
  vpc_region = "us-east-1"
  hvn_region = "us-east-1"
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

# data "aws_availability_zones" "available" {
#   filter {
#     name   = "zone-type"
#     values = ["availability-zone"]
#   }
# }

####### RESOURCE BLOCK

resource "random_id" "id" {
  prefix      = "consul-pov"
  byte_length = 3
}

# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "3.14.2"

#   name                 = "${random_id.id.dec}-vpc"
#   cidr                 = "10.0.0.0/16"
#   azs                  = data.aws_availability_zones.available.names
#   public_subnets       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
#   private_subnets      = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
#   enable_nat_gateway   = true
#   single_nat_gateway   = true
#   enable_dns_hostnames = true
# }

# module "aws_hcp_consul" {
#   source  = "hashicorp/hcp-consul/aws"
#   version = "~> 0.7.0"

#   hvn             = data.tfe_outputs.hcp_vault.values.hvn
#   vpc_id          = module.vpc.vpc_id
#   subnet_ids      = module.vpc.private_subnets
#   route_table_ids = module.vpc.private_route_table_ids
# }