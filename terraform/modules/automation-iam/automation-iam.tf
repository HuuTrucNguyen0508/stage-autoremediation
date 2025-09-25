# --- Reference Existing IAM Role for Automation EC2 ---
data "aws_iam_role" "automation_ec2_role" {
  name = "truh-autoremed-role"
}

# --- Reference Existing IAM Instance Profile ---
data "aws_iam_instance_profile" "automation_ec2_profile" {
  name = "truh-autoremed-role"
}




