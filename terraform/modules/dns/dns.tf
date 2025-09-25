# --- Internal Route53 Hosted Zone ---
resource "aws_route53_zone" "internal" {
  name = var.internal_domain

  vpc {
    vpc_id = var.vpc_id
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-internal-zone" })
}

# --- Internal ALB Route53 Record ---
resource "aws_route53_record" "internal_alb" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = var.internal_alb_subdomain
  type    = "A"

  alias {
    name                   = var.internal_alb_dns_name
    zone_id                = var.internal_alb_zone_id
    evaluate_target_health = true
  }
}

# --- External Route53 Record ---
resource "aws_route53_record" "frontend" {
  zone_id = var.external_zone_id
  name    = var.frontend_domain
  type    = "A"
  ttl     = 300
  records = [var.frontend_public_ip]
}


