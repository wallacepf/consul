resource "aws_cloudwatch_log_group" "log_group" {
  name = var.name
}

locals {
  example_server_app_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = local.vpc_region
      awslogs-stream-prefix = "app"
    }
  }

  example_client_app_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = local.vpc_region
      awslogs-stream-prefix = "client"
    }
  }

  example_hc_fe_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = local.vpc_region
      awslogs-stream-prefix = "hc-fe"
    }
  }

  example_hc_papi_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = local.vpc_region
      awslogs-stream-prefix = "hc-papi"
    }
  }

  example_hc_pay_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = local.vpc_region
      awslogs-stream-prefix = "hc-pay"
    }
  }

  example_hc_product_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = local.vpc_region
      awslogs-stream-prefix = "hc-product"
    }
  }

  example_hc_db_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = local.vpc_region
      awslogs-stream-prefix = "hc-db"
    }
  }
}