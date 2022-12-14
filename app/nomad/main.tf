provider "nomad" {
  address = "http://consul-pov13247324-nmd-elb-0198dea444aeae6e.elb.us-east-1.amazonaws.com:8081"
}

provider "consul" {
  address = "https://consul-pov-11814103.consul.5bbc50e3-a284-4743-877e-ffd388d684f2.aws.hashicorp.cloud"
  token   = "8cb075d5-c808-95bf-9f2c-83dd3aaa70b5"
}

resource "nomad_job" "app" {
  purge_on_destroy = true
  hcl2 {
    enabled = true
    # vars = {
    #   "frontend_port" = 3000,
    #   "public_api_port" = 7070,
    #   "payment_api_port" = 8080,
    #   "product_api_port" = 9090,
    #   "product_db_port" = 5432,
    # }
  }
  jobspec = <<EOT
variable "frontend_port" {
  type        = number
  default     = 3000
}

variable "public_api_port" {
  type        = number
  default     = 7070
}

variable "payment_api_port" {
  type        = number
  default     = 1800
}

variable "product_api_port" {
  type        = number
  default     = 9090
}

variable "product_db_port" {
  type        = number
  default     = 5432
}

job "hashicups" {
  datacenters = ["dc1"]

  group "frontend" {
    network {
      mode = "bridge"

      port "http" {
        static = var.frontend_port
      }
    }

    service {
      name = "frontend-ec2"
      port = "http"
    }

    task "frontend" {
      driver = "docker"

      config {
        image = "hashicorpdemoapp/frontend:v1.0.2"
        ports = ["http"]
      }

      env {
        NEXT_PUBLIC_PUBLIC_API_URL = "/"
      }
    }
  }

  group "public-api" {
    network {
      mode = "bridge"

      port "http" {
        static = var.public_api_port
      }
    }

    service {
      name = "public-api-ec2"
      port = "http"

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "product-api"
              local_bind_port  = var.product_api_port
            }
            upstreams {
              destination_name = "payment-docker"
              local_bind_port  = var.payment_api_port
            }
          }
        }
      }
    }

    task "public-api" {
      driver = "docker"

      config {
        image = "hashicorpdemoapp/public-api:v0.0.6"
        ports = ["http"]
      }

      env {
        BIND_ADDRESS = ":$${var.public_api_port}"
        PRODUCT_API_URI = "http://$${NOMAD_UPSTREAM_ADDR_product-api}"
        PAYMENT_API_URI = "http://$${NOMAD_UPSTREAM_ADDR_payment-docker}"
      }
    }
  }

  group "payment-api" {
    network {
      mode = "bridge"

      port "http" {
        static = var.payment_api_port
      }
    }

    service {
      name = "payment-api-ec2"
      port = "http"

      connect {
        sidecar_service {}
      }
    }

    task "payment-api" {
      driver = "docker"

      config {
        image = "hashicorpdemoapp/payments:v0.0.16"
        ports = ["http"]
      }
    }
  }

  group "product-api" {
    network {
      mode = "bridge"

      port "http" {
        static = var.product_api_port
      }

      port "healthcheck" {
        to = -1
      }
    }

    service {
      name = "product-api-ec2"
      port = "http"

      check {
        type     = "http"
        path     = "/health"
        interval = "5s"
        timeout  = "2s"
        expose   = true
        port     = "healthcheck"
      }

      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "product-db-ec2"
              local_bind_port  = var.product_db_port
            }
          }
        }
      }
    }

    task "product-api" {
      driver = "docker"

      config {
        image = "hashicorpdemoapp/product-api:v0.0.20"
      }

      env {
        DB_CONNECTION = "host=localhost port=$${var.product_db_port} user=postgres password=password dbname=products sslmode=disable"
        BIND_ADDRESS  = "localhost:$${var.product_api_port}"
      }
    }
  }

  group "product-db" {
    network {
      mode = "bridge"

      port "http" {
        static = var.product_db_port
      }
    }

    service {
      name = "product-db-ec2"
      port = "http"

      connect {
        sidecar_service {}
      }
    }

    task "db" {
      driver = "docker"

      config {
        image = "hashicorpdemoapp/product-api-db:v0.0.20"
        ports = ["http"]
      }

      env {
        POSTGRES_DB       = "products"
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "password"
      }
    }
  }
}
EOT

  # depends_on = [
  #   consul_config_entry.fe-ec2,
  #   # consul_config_entry.public_api
  # ]
}

# resource "consul_config_entry" "int_payment_api_ec2" {
#   name = "payment-api-ec2"
#   kind = "service-intentions"

#   config_json = jsonencode({
#     Sources = [
#       {
#         Action     = "allow"
#         Name       = "public-api-ec2"
#         Precedence = 9
#         Type       = "consul"
#       }
#     ]
#   })

#   depends_on = [
#     nomad_job.app
#   ]
# }

# resource "consul_config_entry" "int_product_api_ec2" {
#   name = "product-api-ec2"
#   kind = "service-intentions"

#   config_json = jsonencode({
#     Sources = [
#       {
#         Action     = "allow"
#         Name       = "public-api-ec2"
#         Precedence = 9
#         Type       = "consul"
#       }
#     ]
#   })

#   depends_on = [
#     nomad_job.app
#   ]
# }

# resource "consul_config_entry" "int_product_db_ec2" {
#   name = "product-db-ec2"
#   kind = "service-intentions"

#   config_json = jsonencode({
#     Sources = [
#       {
#         Action     = "allow"
#         Name       = "product-api-ec2"
#         Precedence = 9
#         Type       = "consul"
#       }
#     ]
#   })

#   depends_on = [
#     nomad_job.app
#   ]
# }

########## INTENTIONS EC2-EKS

# resource "consul_config_entry" "int_product_api" {
#   name = "product-api"
#   kind = "service-intentions"

#   config_json = jsonencode({
#     Sources = [
#       {
#         Action     = "allow"
#         Name       = "public-api-ec2"
#         Precedence = 9
#         Type       = "consul"
#       },
#       {
#         Action     = "allow"
#         Name       = "public-api"
#         Precedence = 9
#         Type       = "consul"
#       }
#     ]
#   })

#   depends_on = [
#     nomad_job.app
#   ]
# }