output "frontend_instance_id" {
  description = "ID of the frontend EC2 instance"
  value       = aws_instance.frontend.id
}

output "frontend_public_ip" {
  description = "Public IP of the frontend EC2 instance"
  value       = aws_eip.frontend.public_ip
}

output "backend_instance_id" {
  description = "ID of the backend EC2 instance"
  value       = aws_instance.backend.id
}

output "backend_private_ip" {
  description = "Private IP of the backend EC2 instance"
  value       = aws_instance.backend.private_ip
}

output "mongodb_volume_id" {
  description = "ID of the EBS volume for MongoDB data"
  value       = aws_ebs_volume.mongodb_data.id
}

output "mongodb_volume_attachment_id" {
  description = "ID of the EBS volume attachment for MongoDB data"
  value       = aws_volume_attachment.mongodb_data_attachment.id
}

output "mongodb_device_name" {
  description = "Device name of the attached EBS volume for MongoDB data"
  value       = aws_volume_attachment.mongodb_data_attachment.device_name
}

# --- Automation Outputs ---
output "automation_instance_id" {
  description = "ID of the automation EC2 instance"
  value       = aws_instance.automation.id
}

output "automation_private_ip" {
  description = "Private IP of the automation EC2 instance"
  value       = aws_instance.automation.private_ip
} 
