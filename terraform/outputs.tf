output "frontend_ip" {
  description = "Public IP of the frontend instance"
  value       = module.compute.frontend_public_ip
}

output "frontend_url" {
  description = "URL of the frontend application"
  value       = "http://truhauto.aws.ocho.ninja"
}

output "backend_instance_id" {
  description = "ID of the backend EC2 instance"
  value       = module.compute.backend_instance_id
}

output "backend_private_ip" {
  description = "Private IP of the backend instance"
  value       = module.compute.backend_private_ip
}

output "frontend_instance_id" {
  description = "ID of the frontend EC2 instance"
  value       = module.compute.frontend_instance_id
}

output "internal_alb_dns" {
  description = "DNS name of the internal load balancer"
  value       = module.loadbalancer.alb_dns_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "internal_zone_id" {
  description = "ID of the internal Route53 zone"
  value       = module.dns.internal_zone_id
}

output "mongodb_volume_id" {
  description = "ID of the EBS volume for MongoDB data"
  value       = module.compute.mongodb_volume_id
}

output "mongodb_volume_attachment_id" {
  description = "ID of the EBS volume attachment for MongoDB data"
  value       = module.compute.mongodb_volume_attachment_id
}

output "mongodb_device_name" {
  description = "Device name of the attached EBS volume for MongoDB data"
  value       = module.compute.mongodb_device_name
}

output "automation_private_ip" {
  description = "Private IP address of the automation runner"
  value       = module.compute.automation_private_ip
}

output "automation_instance_id" {
  description = "ID of the automation runner EC2 instance"
  value       = module.compute.automation_instance_id
}



output "automation_role_arn" {
  description = "ARN of the automation EC2 role"
  value       = module.automation_iam.automation_role_arn
}

output "automation_instance_profile_name" {
  description = "Name of the automation EC2 instance profile"
  value       = module.automation_iam.automation_instance_profile_name
}


