#api ALB in US-WEST-2
resource "aws_lb" "api-west" {
  name               = var.api
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.api-west.id]
  subnets            = var.pub_subnets

  tags               = {
    Terraform   = "true"
    Environment = "dev"
    Owner       = "cliwhite"
  }
}

#ACM Cert was previously created
resource "aws_lb_listener" "api-west-https" {
  load_balancer_arn = aws_lb.api-west.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api-west.arn
  }
}

resource "aws_lb_listener" "api-west-http" {
  load_balancer_arn = aws_lb.api-west.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "api-west" {
  name     = var.api
  port     = 5050
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = var.vpc_west
  deregistration_delay  = 90

  health_check {
    healthy_threshold   = 2
    timeout             = 2
    unhealthy_threshold = 2
  }
}

resource "aws_security_group" "api-west" {
  name        = var.api
  description = "Allow inbound web traffic from anywhere"
  vpc_id      = var.vpc_west

  ingress {
    description = "443 from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    description = "80 from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
