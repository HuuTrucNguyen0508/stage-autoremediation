output "internal_zone_id" {
  description = "ID of the internal Route53 zone"
  value       = aws_route53_zone.internal.zone_id
}

output "internal_zone_name_servers" {
  description = "Name servers of the internal Route53 zone"
  value       = aws_route53_zone.internal.name_servers
}


