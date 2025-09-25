# --- Security Groups ---
resource "aws_security_group" "frontend" {
  name_prefix = "${var.name_prefix}-frontend-sg"
  vpc_id      = var.vpc_id
  description = "Frontend security group"
  tags        = merge(var.tags, { Name = "${var.name_prefix}-frontend-sg" })
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-alb-sg"
  vpc_id      = var.vpc_id
  description = "Internal ALB security group"
  tags        = merge(var.tags, { Name = "${var.name_prefix}-alb-sg" })
}

resource "aws_security_group" "backend" {
  name_prefix = "${var.name_prefix}-backend-sg"
  vpc_id      = var.vpc_id
  description = "Backend security group"
  tags        = merge(var.tags, { Name = "${var.name_prefix}-backend-sg" })
}

resource "aws_security_group" "automation_runner" {
  name_prefix = "${var.name_prefix}-automation-runner-sg"
  vpc_id      = var.vpc_id
  description = "Automation runner security group"
  tags        = merge(var.tags, { Name = "${var.name_prefix}-automation-runner-sg" })
}



# --- Security Group Rules ---
## Frontend SG Rules
resource "aws_security_group_rule" "frontend_http_in" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend.id
}

resource "aws_security_group_rule" "frontend_ssh_in" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${var.my_ip}"]
  security_group_id = aws_security_group.frontend.id
}

resource "aws_security_group_rule" "frontend_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend.id
}

## ALB SG Rules
resource "aws_security_group_rule" "alb_http_from_frontend" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.frontend.id
}

resource "aws_security_group_rule" "alb_webhook_from_frontend" {
  type                     = "ingress"
  from_port                = 9000
  to_port                  = 9000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.frontend.id
  description              = "Webhook traffic from frontend instance"
}

resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_to_backend" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.backend.id
}

resource "aws_security_group_rule" "alb_to_automation" {
  type                     = "egress"
  from_port                = 9000
  to_port                  = 9000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.automation_runner.id
  description              = "Webhook traffic to automation instance"
}

## Backend SG Rules
resource "aws_security_group_rule" "backend_from_alb" {
  type                     = "ingress"
  from_port                = var.backend_port
  to_port                  = var.backend_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.backend.id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "backend_ssh_from_frontend" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.backend.id
  source_security_group_id = aws_security_group.frontend.id
}

resource "aws_security_group_rule" "backend_ssh_from_automation_runner" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.backend.id
  source_security_group_id = aws_security_group.automation_runner.id
  description              = "SSH from automation runner instance"
}

resource "aws_security_group_rule" "backend_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend.id
}

## Automation Runner SG Rules
resource "aws_security_group_rule" "automation_runner_ssh_from_backend" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.automation_runner.id
  source_security_group_id = aws_security_group.backend.id
  description              = "SSH from backend instance"
}

resource "aws_security_group_rule" "automation_runner_webhook_from_backend" {
  type                     = "ingress"
  from_port                = 9000
  to_port                  = 9000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.automation_runner.id
  source_security_group_id = aws_security_group.backend.id
  description              = "Webhook server from backend"
}

resource "aws_security_group_rule" "automation_http_webhook_from_backend" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.automation_runner.id
  source_security_group_id = aws_security_group.backend.id
  description              = "Webhook server from backend"
}

resource "aws_security_group_rule" "automation_runner_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.automation_runner.id
  description       = "All outbound traffic"
}

resource "aws_security_group_rule" "automation_ssh_from_frontend" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.automation_runner.id
  source_security_group_id = aws_security_group.frontend.id
  description              = "SSH from frontend"
}



resource "aws_security_group_rule" "automation_webhook_from_internal_alb" {
  type                     = "ingress"
  from_port                = 9000
  to_port                  = 9000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.automation_runner.id
  source_security_group_id = aws_security_group.alb.id
  description              = "Webhook traffic from internal ALB"
}


