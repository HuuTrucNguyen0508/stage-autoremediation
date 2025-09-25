# --- ALB ---
resource "aws_lb" "internal" {
  name               = "${var.name_prefix}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  subnets = [
    var.private_subnet_id,
    var.private_subnet_az2_id
  ]
  security_groups = [var.alb_security_group_id]
  tags            = merge(var.tags, { Name = "${var.name_prefix}-internal-alb" })
}

resource "aws_lb_target_group" "backend" {
  name     = "${var.name_prefix}-backend-tg"
  port     = var.backend_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-backend-tg" })
}

resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-backend-listener" })
}

# --- Webhook Listener for Internal ALB ---
resource "aws_lb_listener" "webhook" {
  load_balancer_arn = aws_lb.internal.arn
  port              = var.webhook_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webhook.arn
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-webhook-listener" })
}

# --- Webhook Target Group for Internal ALB ---
resource "aws_lb_target_group" "webhook" {
  name     = "${var.name_prefix}-webhook-tg"
  port     = var.webhook_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/hooks/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-webhook-tg" })
}

# --- Webhook Listener Rule for Internal ALB ---
resource "aws_lb_listener_rule" "webhook" {
  listener_arn = aws_lb_listener.webhook.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webhook.arn
  }

  condition {
    path_pattern {
      values = ["/webhook*"]
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-webhook-listener-rule" })
}




