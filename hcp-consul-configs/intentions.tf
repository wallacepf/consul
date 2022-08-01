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

# }

resource "consul_config_entry" "int_nginx_eks" {
  name = "nginx"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "ingress-gateway"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })

}

resource "consul_config_entry" "int_frontend_eks" {
  name = "frontend"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "nginx"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })

}

resource "consul_config_entry" "int_public_api_eks" {
  name = "public-api"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "nginx"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })

}

resource "consul_config_entry" "int_product_api_ec2" {
  name = "product-api-ec2"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "public-api"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })

}

resource "consul_config_entry" "int_payments_eks" {
  name = "payments"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "public-api"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })

}

resource "consul_config_entry" "int_product_db_ec2" {
  name = "product-db-ec2"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "product-api-ec2"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })

}

resource "consul_config_entry" "int_payment_api_ec2" {
  name = "payment-api-ec2"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "public-api-ec2"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })

}

resource "consul_config_entry" "int_product_api_eks" {
  name = "product-api"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "public-api-ec2"
        Precedence = 9
        Type       = "consul"
      },
            {
        Action     = "allow"
        Name       = "public-api"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })

}

resource "consul_config_entry" "int_product_api_db_eks" {
  name = "product-api-db"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "product-api"
        Precedence = 9
        Type       = "consul"
      }
    ]
  })

}

resource "consul_config_entry" "int_payment_docker" {
  name = "payment-docker"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Action     = "allow"
        Name       = "public-api-ec2"
        Precedence = 9
        Type       = "consul"
      },
      {
        Action     = "allow"
        Name       = "public-api"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })

}