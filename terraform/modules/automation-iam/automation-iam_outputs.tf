# --- IAM Role Output ---
output "automation_role_arn" {
  description = "ARN of the existing automation EC2 role"
  value       = data.aws_iam_role.automation_ec2_role.arn
}

# --- IAM Instance Profile Output ---
output "automation_instance_profile_name" {
  description = "Name of the existing automation EC2 instance profile"
  value       = data.aws_iam_instance_profile.automation_ec2_profile.name
}
