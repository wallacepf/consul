output "consul_root_token" {
  value = nonsensitive(hcp_consul_cluster_root_token.token.secret_id)
}

output "consul_datacenter" {
  value = hcp_consul_cluster.main.datacenter
}

output "consul_config_file" {
  value = hcp_consul_cluster.main.consul_config_file
}

output "consul_ca_file" {
  value = hcp_consul_cluster.main.consul_ca_file
}

output "consul_version" {
  value = hcp_consul_cluster.main.consul_version
}

output "consul_public_endpoint" {
  value = hcp_consul_cluster.main.consul_public_endpoint_url
}

output "consul_private_endpoint" {
  value = hcp_consul_cluster.main.consul_private_endpoint_url
}

output "consul_cluster_id" {
  value = hcp_consul_cluster.main.cluster_id
}