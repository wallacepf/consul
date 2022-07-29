data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "nomad_host" {
  count                       = 1
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.medium"
  key_name                    = "wallace-keys"
  associate_public_ip_address = false
  subnet_id                   = data.tfe_outputs.consul_nw.values.vpc_private_subnets[0]
  vpc_security_group_ids      = [data.tfe_outputs.consul_nw.values.hcp_consul_sg]
  user_data = templatefile("${path.module}/misc/templates/user_data.sh", {
    setup = base64gzip(templatefile("${path.module}/misc/templates/setup.sh", {
      consul_config    = data.tfe_outputs.hcp_consul.values.consul_config_file,
      consul_ca        = data.tfe_outputs.hcp_consul.values.consul_ca_file,
      consul_acl_token = data.tfe_outputs.hcp_consul.values.consul_root_token,
      consul_version   = data.tfe_outputs.hcp_consul.values.consul_version,
      consul_service = base64encode(templatefile("${path.module}/misc/templates/service", {
        service_name = "consul",
        service_cmd  = "/usr/bin/consul agent -data-dir /var/consul -config-dir=/etc/consul.d/",
      })),
      nomad_service = base64encode(templatefile("${path.module}/misc/templates/service", {
        service_name = "nomad",
        service_cmd  = "sudo /usr/bin/nomad agent -dev-connect -consul-token=${data.tfe_outputs.hcp_consul.values.consul_root_token}",
      })),
      # hashicups  = base64encode(file("${path.module}/misc/templates/hashicups.nomad")),
      nginx_conf = base64encode(file("${path.module}/misc/templates/nginx.conf")),
      vpc_cidr   = data.tfe_outputs.consul_nw.values.vpc_cidr
    })),
  })

  tags = {
    Name = "${random_id.id.dec}-hcp-nomad-host"
  }

  lifecycle {
    create_before_destroy = false
    prevent_destroy       = false
  }
}

module "nlb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "nomad-host-elb"

  load_balancer_type = "network"

  vpc_id  = data.tfe_outputs.consul_nw.values.vpc_id
  subnets = data.tfe_outputs.consul_nw.values.vpc_public_subnets

  target_groups = [
    {
      name_prefix      = "fe-"
      backend_protocol = "TCP"
      backend_port     = 80
      target_type      = "instance"
      targets = {
        frontend = {
          target_id = aws_instance.nomad_host[0].id
          port      = 80
        }
      }
    },
    {
      name_prefix      = "nmd-"
      backend_protocol = "TCP"
      backend_port     = 8081
      target_type      = "instance"
      targets = {
        nomad = {
          target_id = aws_instance.nomad_host[0].id
          port      = 8081
        }
      }
    },
    {
      name_prefix      = "srv-"
      backend_protocol = "TCP"
      backend_port     = 22
      target_type      = "instance"
      targets = {
        nomad = {
          target_id = aws_instance.nomad_host[0].id
          port      = 22
        }
      }
    },
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 0
    },
    {
      port               = 8081
      protocol           = "TCP"
      target_group_index = 1
    },
    {
      port               = 22
      protocol           = "TCP"
      target_group_index = 2
    },
  ]
}