module "acl_controller" {
  source  = "hashicorp/consul-ecs/aws//modules/acl-controller"
  version = "~> 0.5.0"

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = local.vpc_region
      awslogs-stream-prefix = "consul-acl-controller"
    }
  }
  consul_bootstrap_token_secret_arn = aws_secretsmanager_secret.bootstrap_token.arn
  consul_server_http_addr           = data.tfe_outputs.hcp_consul.values.consul_private_endpoint
  ecs_cluster_arn                   = aws_ecs_cluster.this.arn
  region                            = local.vpc_region
  subnets                           = data.tfe_outputs.consul_nw.values.vpc_private_subnets
  name_prefix                       = var.name
  consul_ecs_image                  = var.consul_ecs_image
  consul_partitions_enabled         = true
}

#### Demo client-server

module "example_client_app" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.5.0"

  family = "${var.name}-example-client-app"

  port              = "9090"
  log_configuration = local.example_client_app_log_config
  container_definitions = [{
    name             = "example-client-app"
    image            = "ghcr.io/lkysow/fake-service:v0.21.0"
    essential        = true
    logConfiguration = local.example_client_app_log_config
    environment = [
      {
        name  = "NAME"
        value = "${var.name}-example-client-app"
      },
      {
        name  = "UPSTREAM_URIS"
        value = "http://localhost:1234"
      }
    ]
    portMappings = [
      {
        containerPort = 9090
        hostPort      = 9090
        protocol      = "tcp"
      }
    ]
    cpu         = 0
    mountPoints = []
    volumesFrom = []
  }]
  upstreams = [
    {
      destinationName = "${var.name}-example-server-app"
      localBindPort   = 1234
    }
  ]

  retry_join                = jsondecode(base64decode(data.tfe_outputs.hcp_consul.values.consul_config_file))["retry_join"]
  consul_datacenter         = data.tfe_outputs.hcp_consul.values.consul_datacenter
  audit_logging             = true
  tls                       = true
  acls                      = true
  consul_http_addr          = data.tfe_outputs.hcp_consul.values.consul_private_endpoint
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn
  consul_server_ca_cert_arn = aws_secretsmanager_secret.consul_ca_cert.arn
  consul_ecs_image          = var.consul_ecs_image
  consul_image              = var.consul_image

  depends_on = [module.acl_controller, module.example_server_app]
}

module "example_server_app" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.5.0"

  family            = "${var.name}-example-server-app"
  port              = "9090"
  log_configuration = local.example_server_app_log_config

  container_definitions = [{
    name             = "example-server-app"
    image            = "ghcr.io/lkysow/fake-service:v0.21.0"
    essential        = true
    logConfiguration = local.example_server_app_log_config
    environment = [
      {
        name  = "NAME"
        value = "${var.name}-example-server-app"
      }
    ]
  }]


  retry_join                = jsondecode(base64decode(data.tfe_outputs.hcp_consul.values.consul_config_file))["retry_join"]
  consul_datacenter         = data.tfe_outputs.hcp_consul.values.consul_datacenter
  audit_logging             = true
  tls                       = true
  acls                      = true
  consul_http_addr          = data.tfe_outputs.hcp_consul.values.consul_private_endpoint
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn
  consul_server_ca_cert_arn = aws_secretsmanager_secret.consul_ca_cert.arn
  consul_ecs_image          = var.consul_ecs_image
  consul_image              = var.consul_image

  depends_on = [module.acl_controller]
}

###### Hashicups

module "hashicups_frontend" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.5.0"

  family            = "${var.name}-hashicups_frontend"
  port              = "3000"
  log_configuration = local.example_server_app_log_config

  container_definitions = [{
    name             = "frontend-hashicups"
    image            = "hashicorpdemoapp/frontend:v1.0.6"
    essential        = true
    logConfiguration = local.example_hc_fe_log_config
    environment = [
      {
        name  = "NAME"
        value = "${var.name}-hashicups-frontend"
      }
    ]
    portMappings = [
      {
        containerPort = 3000
        hostPort      = 3000
        protocol      = "tcp"
      }
    ]
  }]

  upstreams = [
    {
      destinationName = "${var.name}-hashicups_public_api"
      localBindPort   = 7070
    }
  ]

  retry_join                = jsondecode(base64decode(data.tfe_outputs.hcp_consul.values.consul_config_file))["retry_join"]
  consul_datacenter         = data.tfe_outputs.hcp_consul.values.consul_datacenter
  audit_logging             = true
  tls                       = true
  acls                      = true
  consul_http_addr          = data.tfe_outputs.hcp_consul.values.consul_private_endpoint
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn
  consul_server_ca_cert_arn = aws_secretsmanager_secret.consul_ca_cert.arn
  consul_ecs_image          = var.consul_ecs_image
  consul_image              = var.consul_image

  depends_on = [module.acl_controller]
}

module "hashicups_public_api" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.5.0"

  family            = "${var.name}-hashicups_public_api"
  port              = "7070"
  log_configuration = local.example_hc_papi_log_config

  container_definitions = [{
    name             = "hashicups-public-api"
    image            = "hashicorpdemoapp/public-api:v0.0.6"
    essential        = true
    logConfiguration = local.example_hc_papi_log_config
    environment = [
      {
        name  = "NAME"
        value = "${var.name}-hashicups_public_api"
      },
      {
        name  = "BIND_ADDRESS"
        value = ":7070"
      },
      {
        name  = "PRODUCT_API_URI"
        value = "http://localhost:9090"
      },
      {
        name  = "PAYMENT_API_URI"
        value = "http://localhost:1800"
      }
    ]
        portMappings = [
      {
        containerPort = 7070
        hostPort      = 7070
        protocol      = "tcp"
      }
    ]
  }]

  upstreams = [
    {
      destinationName = "${var.name}-hashicups_product_api"
      localBindPort   = 9090
    }
  ]

  retry_join                = jsondecode(base64decode(data.tfe_outputs.hcp_consul.values.consul_config_file))["retry_join"]
  consul_datacenter         = data.tfe_outputs.hcp_consul.values.consul_datacenter
  audit_logging             = true
  tls                       = true
  acls                      = true
  consul_http_addr          = data.tfe_outputs.hcp_consul.values.consul_private_endpoint
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn
  consul_server_ca_cert_arn = aws_secretsmanager_secret.consul_ca_cert.arn
  consul_ecs_image          = var.consul_ecs_image
  consul_image              = var.consul_image

  depends_on = [module.acl_controller]
}

module "hashicups_payment" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.5.0"

  family            = "${var.name}-hashicups_payment"
  port              = "1800"
  log_configuration = local.example_hc_pay_log_config

  container_definitions = [{
    name             = "hashicups-payments"
    image            = "hashicorpdemoapp/payments:v0.0.16"
    essential        = true
    logConfiguration = local.example_hc_pay_log_config
    environment = [
      {
        name  = "NAME"
        value = "${var.name}-hashicups_payment"
      }
    ]
  }]

  retry_join                = jsondecode(base64decode(data.tfe_outputs.hcp_consul.values.consul_config_file))["retry_join"]
  consul_datacenter         = data.tfe_outputs.hcp_consul.values.consul_datacenter
  audit_logging             = true
  tls                       = true
  acls                      = true
  consul_http_addr          = data.tfe_outputs.hcp_consul.values.consul_private_endpoint
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn
  consul_server_ca_cert_arn = aws_secretsmanager_secret.consul_ca_cert.arn
  consul_ecs_image          = var.consul_ecs_image
  consul_image              = var.consul_image

  depends_on = [module.acl_controller]
}

module "hashicups_product_api" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.5.0"

  family            = "${var.name}-hashicups_product_api"
  port              = "9090"
  log_configuration = local.example_hc_product_log_config

  container_definitions = [{
    name             = "hashicups-product-api"
    image            = "hashicorpdemoapp/product-api:v0.0.20"
    essential        = true
    logConfiguration = local.example_hc_product_log_config
    environment = [
      {
        name  = "NAME"
        value = "${var.name}-hashicups_product_api"
      },
      {
        name  = "BIND_ADDRESS"
        value = "localhost:9090"
      },
      {
        name  = "DB_CONNECTION"
        value = "host=localhost port=5432 user=postgres password=password dbname=products sslmode=disable"
      }
    ]
  }]

  retry_join                = jsondecode(base64decode(data.tfe_outputs.hcp_consul.values.consul_config_file))["retry_join"]
  consul_datacenter         = data.tfe_outputs.hcp_consul.values.consul_datacenter
  audit_logging             = true
  tls                       = true
  acls                      = true
  consul_http_addr          = data.tfe_outputs.hcp_consul.values.consul_private_endpoint
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn
  consul_server_ca_cert_arn = aws_secretsmanager_secret.consul_ca_cert.arn
  consul_ecs_image          = var.consul_ecs_image
  consul_image              = var.consul_image

  depends_on = [module.acl_controller]
}

module "hashicups_db" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.5.0"

  family            = "${var.name}-hashicups_db"
  port              = "5432"
  log_configuration = local.example_hc_db_log_config

  container_definitions = [{
    name             = "hashicups-product-db"
    image            = "hashicorpdemoapp/product-api-db:v0.0.20"
    essential        = true
    logConfiguration = local.example_hc_db_log_config
    environment = [
      {
        name  = "NAME"
        value = "${var.name}-hashicups_db"
      }
    ]
  }]

  retry_join                = jsondecode(base64decode(data.tfe_outputs.hcp_consul.values.consul_config_file))["retry_join"]
  consul_datacenter         = data.tfe_outputs.hcp_consul.values.consul_datacenter
  audit_logging             = true
  tls                       = true
  acls                      = true
  consul_http_addr          = data.tfe_outputs.hcp_consul.values.consul_private_endpoint
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn
  consul_server_ca_cert_arn = aws_secretsmanager_secret.consul_ca_cert.arn
  consul_ecs_image          = var.consul_ecs_image
  consul_image              = var.consul_image

  depends_on = [module.acl_controller]
}