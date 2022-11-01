# output "consul_url" {
#   value = hcp_consul_cluster.main.public_endpoint ? (
#     hcp_consul_cluster.main.consul_public_endpoint_url
#     ) : (
#     hcp_consul_cluster.main.consul_private_endpoint_url
#   )
# }

# output "kubeconfig_filename" {
#   value = abspath(module.eks.kubeconfig_filename)
# }

# output "hashicups_url_eks" {
#   value = module.demo_app.hashicups_url
# }

# output "consul_token" {
#   value     = data.kubernetes_secret.consul_token.data.token
#   sensitive = true
# }

# output "next_steps" {
#   value = "Hashicups Application will be ready in ~2 minutes. Use 'terraform output consul_root_token' to retrieve the root token."
# }

output "nomad_url" {
  value = "http://${module.nlb.lb_dns_name}:8081"
}

output "hashicups_url_ec2" {
  value = "http://${module.nlb.lb_dns_name}"
}

# output "portainer_url" {
#   value = "http://${module.nlb-ec2.lb_dns_name}:9443"
# }

# output "kubernetes_host" {
#   value = data.aws_eks_cluster.cluster.endpoint
# }

# output "kubernetes_ca" {
#   value = data.aws_eks_cluster.cluster.certificate_authority.0.data
# }

# output "kubernetes_token" {
#   value = nonsensitive(data.aws_eks_cluster_auth.cluster.token)
# }