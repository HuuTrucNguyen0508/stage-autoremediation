output "alb_id" {
  description = "ID of the internal ALB"
  value       = aws_lb.internal.id
}

output "alb_arn" {
  description = "ARN of the internal ALB"
  value       = aws_lb.internal.arn
}

output "alb_dns_name" {
  description = "DNS name of the internal ALB"
  value       = aws_lb.internal.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the internal ALB"
  value       = aws_lb.internal.zone_id
}

output "target_group_arn" {
  description = "ARN of the backend target group"
  value       = aws_lb_target_group.backend.arn
}

output "webhook_target_group_arn" {
  description = "ARN of the webhook target group"
  value       = aws_lb_target_group.webhook.arn
}


