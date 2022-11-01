# The client app is part of the service mesh. It calls
# the server app through the service mesh.
# It's exposed via a load balancer.
resource "aws_ecs_service" "example_client_app" {
  name            = "${var.name}-example-client-app"
  cluster         = aws_ecs_cluster.this.arn
  task_definition = module.example_client_app.task_definition_arn
  desired_count   = 1
  network_configuration {
    subnets = data.tfe_outputs.consul_nw.values.vpc_private_subnets
  }
  launch_type    = "FARGATE"
  propagate_tags = "TASK_DEFINITION"
  load_balancer {
    target_group_arn = aws_lb_target_group.example_client_app.arn
    container_name   = "example-client-app"
    container_port   = 9090
  }
  enable_execute_command = true
}

# The server app is part of the service mesh. It's called
# by the client app.
resource "aws_ecs_service" "example_server_app" {
  name            = "${var.name}-example-server-app"
  cluster         = aws_ecs_cluster.this.arn
  task_definition = module.example_server_app.task_definition_arn
  desired_count   = 1
  network_configuration {
    subnets = data.tfe_outputs.consul_nw.values.vpc_private_subnets
  }
  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}

resource "aws_ecs_service" "hashicups_frontend" {
  name            = "${var.name}-hashicups_frontend"
  cluster         = aws_ecs_cluster.this.arn
  task_definition = module.hashicups_frontend.task_definition_arn
  desired_count   = 1
  network_configuration {
    subnets = data.tfe_outputs.consul_nw.values.vpc_private_subnets
  }
  launch_type    = "FARGATE"
  propagate_tags = "TASK_DEFINITION"
  load_balancer {
    target_group_arn = aws_lb_target_group.hashicups_frontend.arn
    container_name   = "frontend-hashicups"
    container_port   = 3000
  }
  enable_execute_command = true
}

resource "aws_ecs_service" "hashicups_public_api" {
  name            = "${var.name}-hashicups_public_api"
  cluster         = aws_ecs_cluster.this.arn
  task_definition = module.hashicups_public_api.task_definition_arn
  desired_count   = 1
  network_configuration {
    subnets = data.tfe_outputs.consul_nw.values.vpc_private_subnets
  }
  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}

resource "aws_ecs_service" "hashicups_payment" {
  name            = "${var.name}-hashicups_payment"
  cluster         = aws_ecs_cluster.this.arn
  task_definition = module.hashicups_payment.task_definition_arn
  desired_count   = 1
  network_configuration {
    subnets = data.tfe_outputs.consul_nw.values.vpc_private_subnets
  }
  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}

resource "aws_ecs_service" "hashicups_product_api" {
  name            = "${var.name}-hashicups_product_api"
  cluster         = aws_ecs_cluster.this.arn
  task_definition = module.hashicups_product_api.task_definition_arn
  desired_count   = 1
  network_configuration {
    subnets = data.tfe_outputs.consul_nw.values.vpc_private_subnets
  }
  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}

resource "aws_ecs_service" "hashicups_db" {
  name            = "${var.name}-hashicups_db"
  cluster         = aws_ecs_cluster.this.arn
  task_definition = module.hashicups_db.task_definition_arn
  desired_count   = 1
  network_configuration {
    subnets = data.tfe_outputs.consul_nw.values.vpc_private_subnets
  }
  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}