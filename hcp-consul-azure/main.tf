locals {
  hvn_region     = "eastus"
  hvn_id         = "consul-quickstart-1664905303353-hvn"
  cluster_id     = "consul-quickstart-1664905303353"
  network_region = ["eastus", "northcentralus"]
  vnet_cidrs     = ["10.0.0.0/16", "10.1.0.0/16"]
  vnet_subnets_rg1 = {
    "subnet1" = "10.0.1.0/24",
    "subnet2" = "10.0.2.0/24",
  }
  vnet_subnets_rg2 = {
    "subnet1" = "10.1.1.0/24",
    "subnet2" = "10.1.2.0/24",
  }
}

terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "~> 2.65"
      configuration_aliases = [azurerm.azure]
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.14"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.23.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.4.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.3.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.11.3"
    }
  }

  required_version = ">= 1.0.11"

}

# Configure providers to use the credentials from the AKS cluster.
provider "helm" {
  kubernetes {
    client_certificate     = base64decode(azurerm_kubernetes_cluster.k8.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.k8.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k8.kube_config.0.cluster_ca_certificate)
    host                   = azurerm_kubernetes_cluster.k8.kube_config.0.host
    password               = azurerm_kubernetes_cluster.k8.kube_config.0.password
    username               = azurerm_kubernetes_cluster.k8.kube_config.0.username
  }
}

provider "kubernetes" {
  client_certificate     = base64decode(azurerm_kubernetes_cluster.k8.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.k8.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k8.kube_config.0.cluster_ca_certificate)
  host                   = azurerm_kubernetes_cluster.k8.kube_config.0.host
  password               = azurerm_kubernetes_cluster.k8.kube_config.0.password
  username               = azurerm_kubernetes_cluster.k8.kube_config.0.username
}

provider "kubectl" {
  client_certificate     = base64decode(azurerm_kubernetes_cluster.k8.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.k8.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k8.kube_config.0.cluster_ca_certificate)
  host                   = azurerm_kubernetes_cluster.k8.kube_config.0.host
  load_config_file       = false
  password               = azurerm_kubernetes_cluster.k8.kube_config.0.password
  username               = azurerm_kubernetes_cluster.k8.kube_config.0.username
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

provider "hcp" {
    client_id = var.client_id
    client_secret = var.client_secret
}

# provider "consul" {
#   address    = hcp_consul_cluster.main.consul_public_endpoint_url
#   datacenter = hcp_consul_cluster.main.datacenter
#   token      = hcp_consul_cluster_root_token.token.secret_id
# }

data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "rg1" {
  name     = "${substr(local.cluster_id, 0, 22)}-01-gid"
  location = local.network_region[0]
}

resource "azurerm_resource_group" "rg2" {
  name     = "${substr(local.cluster_id, 0, 22)}-02-gid"
  location = local.network_region[1]
}

resource "azurerm_route_table" "rt-rg1" {
  name                = "${substr(local.cluster_id, 0, 22)}-rg1-rt"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
}

resource "azurerm_route_table" "rt-rg2" {
  name                = "${substr(local.cluster_id, 0, 22)}-rg2-rt"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
}

resource "azurerm_network_security_group" "nsg-rg1" {
  name                = "${substr(local.cluster_id, 0, 22)}-rg1-nsg"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
}

resource "azurerm_network_security_group" "nsg-rg2" {
  name                = "${substr(local.cluster_id, 0, 22)}-rg2-nsg"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
}

# Create an Azure vnet and authorize Consul server traffic.
module "network-rg1" {
  source              = "Azure/vnet/azurerm"
  address_space       = [local.vnet_cidrs[0]]
  resource_group_name = azurerm_resource_group.rg1.name
  subnet_names        = keys(local.vnet_subnets_rg1)
  subnet_prefixes     = values(local.vnet_subnets_rg1)
  vnet_name           = "${substr(local.cluster_id, 0, 22)}-rg1-vnet"
  subnet_delegation = {
    "subnet1" = {
      "aks-delegation" = {
        service_name = "Microsoft.ContainerService/managedClusters"
        service_actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
  # Every subnet will share a single route table
  route_tables_ids = { for i, subnet in keys(local.vnet_subnets_rg1) : subnet => azurerm_route_table.rt-rg1.id }

  # Every subnet will share a single network security group
  nsg_ids = { for i, subnet in keys(local.vnet_subnets_rg1) : subnet => azurerm_network_security_group.nsg-rg1.id }

  depends_on = [azurerm_resource_group.rg1]
}

module "network-rg2" {
  source              = "Azure/vnet/azurerm"
  address_space       = [local.vnet_cidrs[1]]
  resource_group_name = azurerm_resource_group.rg2.name
  subnet_names        = keys(local.vnet_subnets_rg2)
  subnet_prefixes     = values(local.vnet_subnets_rg2)
  vnet_name           = "${substr(local.cluster_id, 0, 22)}-rg2-vnet"
  subnet_delegation = {
    "subnet1" = {
      "aks-delegation" = {
        service_name = "Microsoft.ContainerService/managedClusters"
        service_actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
  # Every subnet will share a single route table
  route_tables_ids = { for i, subnet in keys(local.vnet_subnets_rg2) : subnet => azurerm_route_table.rt-rg2.id }

  # Every subnet will share a single network security group
  nsg_ids = { for i, subnet in keys(local.vnet_subnets_rg2) : subnet => azurerm_network_security_group.nsg-rg2.id }

  depends_on = [azurerm_resource_group.rg2]
}

resource "azurerm_virtual_network_peering" "peer1to2" {
  name                      = "peer1to2"
  resource_group_name       = azurerm_resource_group.rg1.name
  virtual_network_name      = module.network-rg1.vnet_name
  remote_virtual_network_id = module.network-rg2.vnet_id
}

resource "azurerm_virtual_network_peering" "peer2to1" {
  name                      = "peer2to1"
  resource_group_name       = azurerm_resource_group.rg2.name
  virtual_network_name      = module.network-rg2.vnet_name
  remote_virtual_network_id = module.network-rg1.vnet_id
}

# Create an HCP HVN.
# resource "hcp_hvn" "hvn" {
#   cidr_block     = "172.25.32.0/20"
#   cloud_provider = "azure"
#   hvn_id         = local.hvn_id
#   region         = local.hvn_region
# }

# Peer the HVN to the vnet.
# module "hcp_peering" {
#   source  = "hashicorp/hcp-consul/azurerm"
#   version = "~> 0.2.5"

#   hvn    = hcp_hvn.hvn
#   prefix = local.cluster_id

#   security_group_names = [azurerm_network_security_group.nsg.name]
#   subscription_id      = data.azurerm_subscription.current.subscription_id
#   tenant_id            = data.azurerm_subscription.current.tenant_id

#   subnet_ids = module.network.vnet_subnets
#   vnet_id    = module.network.vnet_id
#   vnet_rg    = azurerm_resource_group.rg.name

#   depends_on = [
#     azurerm_network_security_group.nsg,
#     data.azurerm_subscription.current,
#     azurerm_resource_group.rg,
#     module.network,
#     hcp_hvn.hvn
#   ]
# }

# Create the Consul cluster.
# resource "hcp_consul_cluster" "main" {
#   cluster_id      = local.cluster_id
#   hvn_id          = hcp_hvn.hvn.hvn_id
#   public_endpoint = true
#   tier            = "development"
# }

# resource "hcp_consul_cluster_root_token" "token" {
#   cluster_id = hcp_consul_cluster.main.id
# }

# Create a user assigned identity (required for UserAssigned identity in combination with brining our own subnet/nsg/etc)
resource "azurerm_user_assigned_identity" "identity-rg1" {
  name                = "aks-identity"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
}

resource "azurerm_user_assigned_identity" "identity-rg2" {
  name                = "aks-identity"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
}

# Create the AKS cluster.
resource "azurerm_kubernetes_cluster" "k8-rg1" {
  name                    = "${substr(local.cluster_id, 0, 22)}-rg1"
  dns_prefix              = local.cluster_id
  location                = azurerm_resource_group.rg1.location
  private_cluster_enabled = false
  resource_group_name     = azurerm_resource_group.rg1.name

  network_profile {
    network_plugin     = "azure"
    service_cidr       = "10.30.0.0/16"
    dns_service_ip     = "10.30.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  default_node_pool {
    name            = "default"
    node_count      = 3
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
    pod_subnet_id   = module.network-rg1.vnet_subnets[0]
    vnet_subnet_id  = module.network-rg1.vnet_subnets[1]
  }

  identity {
    type                      = "UserAssigned"
    user_assigned_identity_id = azurerm_user_assigned_identity.identity-rg1.id
  }

  depends_on = [
    module.network-rg1,
    azurerm_virtual_network_peering.peer1to2,
    azurerm_virtual_network_peering.peer2to1,
  ]
}

resource "azurerm_kubernetes_cluster" "k8-rg2" {
  name                    = "${substr(local.cluster_id, 0, 22)}-rg2"
  dns_prefix              = local.cluster_id
  location                = azurerm_resource_group.rg2.location
  private_cluster_enabled = false
  resource_group_name     = azurerm_resource_group.rg2.name

  network_profile {
    network_plugin     = "azure"
    service_cidr       = "10.30.0.0/16"
    dns_service_ip     = "10.30.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  default_node_pool {
    name            = "default"
    node_count      = 3
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
    pod_subnet_id   = module.network-rg2.vnet_subnets[0]
    vnet_subnet_id  = module.network-rg2.vnet_subnets[1]
  }

  identity {
    type                      = "UserAssigned"
    user_assigned_identity_id = azurerm_user_assigned_identity.identity-rg2.id
  }

  depends_on = [
    module.network-rg2,
    azurerm_virtual_network_peering.peer1to2,
    azurerm_virtual_network_peering.peer2to1,
  ]
}

# Create a Kubernetes client that deploys Consul and its secrets.
# module "aks_consul_client" {
#   source  = "hashicorp/hcp-consul/azurerm//modules/hcp-aks-client"
#   version = "~> 0.2.5"

#   cluster_id       = hcp_consul_cluster.main.cluster_id
#   consul_hosts     = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["retry_join"]
#   consul_version   = hcp_consul_cluster.main.consul_version
#   k8s_api_endpoint = azurerm_kubernetes_cluster.k8.kube_config.0.host

#   boostrap_acl_token    = hcp_consul_cluster_root_token.token.secret_id
#   consul_ca_file        = base64decode(hcp_consul_cluster.main.consul_ca_file)
#   datacenter            = hcp_consul_cluster.main.datacenter
#   gossip_encryption_key = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["encrypt"]

#   # The AKS node group will fail to create if the clients are
#   # created at the same time. This forces the client to wait until
#   # the node group is successfully created.
#   depends_on = [azurerm_kubernetes_cluster.k8]
# }

# Deploy Hashicups.
# module "demo_app" {
#   source  = "hashicorp/hcp-consul/azurerm//modules/k8s-demo-app"
#   version = "~> 0.2.5"

#   depends_on = [module.aks_consul_client]
# }

# Authorize HTTP ingress to the load balancer.
resource "azurerm_network_security_rule" "consul-ui-rg1" {
  name                        = "consul-ui-rg1"
  priority                    = 301
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "52.151.206.74"
  resource_group_name         = azurerm_resource_group.rg1.name
  network_security_group_name = azurerm_network_security_group.nsg-rg1.name

  # depends_on = [module.demo_app]
}

resource "azurerm_network_security_rule" "consul-ui-rg2" {
  name                        = "consul-ui-rg2"
  priority                    = 401
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "65.52.63.55"
  resource_group_name         = azurerm_resource_group.rg2.name
  network_security_group_name = azurerm_network_security_group.nsg-rg2.name

  # depends_on = [module.demo_app]
}

resource "azurerm_network_security_rule" "mesh-gw-rg1" {
  name                        = "mesh-gw-rg1"
  priority                    = 302
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "52.151.207.4"
  resource_group_name         = azurerm_resource_group.rg1.name
  network_security_group_name = azurerm_network_security_group.nsg-rg1.name

  # depends_on = [module.demo_app]
}

resource "azurerm_network_security_rule" "mesh-gw-rg2" {
  name                        = "mesh-gw-rg2"
  priority                    = 402
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "23.100.73.27"
  resource_group_name         = azurerm_resource_group.rg2.name
  network_security_group_name = azurerm_network_security_group.nsg-rg2.name

  # depends_on = [module.demo_app]
}

resource "azurerm_network_security_rule" "ingress-rg1" {
  name                        = "http-ingress-rg1"
  priority                    = 303
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "52.151.207.5"
  resource_group_name         = azurerm_resource_group.rg1.name
  network_security_group_name = azurerm_network_security_group.nsg-rg1.name

  # depends_on = [module.demo_app]
}

resource "azurerm_network_security_rule" "ingress-rg2" {
  name                        = "http-ingress-rg2"
  priority                    = 403
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "23.100.73.130"
  resource_group_name         = azurerm_resource_group.rg2.name
  network_security_group_name = azurerm_network_security_group.nsg-rg2.name

  # depends_on = [module.demo_app]
}