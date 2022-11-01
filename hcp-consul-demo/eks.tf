###### LOCAL BLOCK

locals {
  consul_dc        = "consul-us-east-1"
  consul_license   = "consul-ent-license"
  consul_namespace = "consul"
  consul_version   = "1.12.3"
}

###### DATA BLOCK

# data "aws_eks_cluster" "cluster" {
#   name = module.eks.cluster_id
# }

# data "aws_eks_cluster_auth" "cluster" {
#   name = module.eks.cluster_id
# }

data "tfe_outputs" "consul_nw" {
  organization = "my-demo-account"
  workspace    = "hcp-consul-demo-nw"
}

###### RESOURCE BLOCK

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "18.26.3"

#   cluster_name                    = "${random_id.id.dec}-eks"
#   cluster_version                 = "1.22"
#   subnet_ids                      = data.tfe_outputs.consul_nw.values.vpc_private_subnets
#   vpc_id                          = data.tfe_outputs.consul_nw.values.vpc_id
#   cluster_endpoint_private_access = true
#   cluster_endpoint_public_access  = true

#   cluster_addons = {
#     vpc-cni = {
#       resolve_conflicts = "OVERWRITE"
#       addon_version     = "v1.11.2-eksbuild.1"
#     }

#     kube-proxy = {
#       resolve_conflicts = "OVERWRITE"
#       addon_version     = "v1.22.11-eksbuild.2"
#     }

#     coredns = {
#       resolve_conflicts = "OVERWRITE"
#       addon_version     = "v1.8.7-eksbuild.1"
#     }
#   }

#   eks_managed_node_groups = {
#     consul_demo = {
#       name_prefix    = "hashicups"
#       instance_types = ["t3a.medium"]

#       min_size     = 3
#       max_size     = 3
#       desired_size = 3
#     }
#   }

#   cluster_security_group_additional_rules = {
#     egress_nodes_ephemeral_ports_tcp = {
#       description                = "To node 1025-65535"
#       protocol                   = "tcp"
#       from_port                  = 1025
#       to_port                    = 65535
#       type                       = "egress"
#       source_node_security_group = true
#     }
#   }

#   node_security_group_additional_rules = {
#     ingress_self_all = {
#       description = "Node to node all ports/protocols"
#       protocol    = "-1"
#       from_port   = 0
#       to_port     = 0
#       type        = "ingress"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#     egress_all = {
#       description = "Node all egress"
#       protocol    = "-1"
#       from_port   = 0
#       to_port     = 0
#       type        = "egress"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }

#   manage_aws_auth_configmap = true
#   aws_auth_roles = [
#     {
#       rolearn  = "arn:aws:iam::711129375688:role/se_demos_dev-developer"
#       username = "se_demos_dev-developer"
#       groups   = ["system:masters"]
#     },
#   ]

#   tags = {
#     Environment = "demo"
#     Terraform   = "true"
#     Owner       = "Wallace-SE-LATAM"
#   }

# }

# module "eks_consul_client" {
#   source  = "hashicorp/hcp-consul/aws//modules/hcp-eks-client"
#   version = "~> 0.7.1"

#   cluster_id       = data.tfe_outputs.hcp_consul.values.consul_cluster_id
#   consul_hosts     = jsondecode(base64decode(data.tfe_outputs.hcp_consul.values.consul_config_file))["retry_join"]
#   k8s_api_endpoint = module.eks.cluster_endpoint
#   consul_version   = data.tfe_outputs.hcp_consul.values.consul_version

#   boostrap_acl_token    = data.tfe_outputs.hcp_consul.values.consul_root_token
#   consul_ca_file        = base64decode(data.tfe_outputs.hcp_consul.values.consul_ca_file)
#   datacenter            = data.tfe_outputs.hcp_consul.values.consul_datacenter
#   gossip_encryption_key = jsondecode(base64decode(data.tfe_outputs.hcp_consul.values.consul_config_file))["encrypt"]
#   chart_version         = "0.45.0"

#   depends_on = [module.eks]
# }

# module "demo_app" {
#   source  = "hashicorp/hcp-consul/aws//modules/k8s-demo-app"
#   version = "~> 0.7.0"

#   depends_on = [module.eks_consul_client]
# }