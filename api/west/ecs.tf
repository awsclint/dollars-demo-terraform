resource "aws_ecs_cluster" "west" {
  name = "dollar-demo-cluster-west"
  capacity_providers = ["FARGATE"]
  tags               = {
    Terraform   = "true"
    Environment = "dev"
    Owner       = "cliwhite"
  }
}

resource "aws_ecs_task_definition" "api-west" {
    family = var.api
    container_definitions = file("task-definitions/api.json")
    network_mode             = "awsvpc"

    requires_compatibilities = ["FARGATE"]
    cpu                      = 256
    memory                   = 512
    execution_role_arn       = var.fargate_execution_role

}

resource "aws_ecs_service" "api-west" {
    name = var.api
    cluster = aws_ecs_cluster.west.id
    task_definition = aws_ecs_task_definition.api-west.arn
    desired_count = 3
    launch_type = "FARGATE"

    lifecycle {
    ignore_changes = [desired_count,task_definition]
     }
    
    network_configuration {
      subnets = var.priv_subnets
      security_groups = [aws_security_group.api-west-fargate.id]
    }

    load_balancer {
        target_group_arn = aws_lb_target_group.api-west.arn
        container_name = var.api
        container_port = 5050
    }
}

resource "aws_security_group" "api-west-fargate" {
  name        = "${var.api}-fargate"
  description = "Allow traffic from ALB SG"
  vpc_id      = var.vpc_west

    ingress {
    description = "5050 from VPC"
    from_port   = 5050
    to_port     = 5050
    protocol    = "tcp"
    security_groups = [aws_security_group.api-west.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags               = {
    Terraform   = "true"
    Environment = "dev"
    Owner       = "cliwhite"
  }
}