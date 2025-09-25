variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "truh1"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "frontend_instance_type" {
  description = "Instance type for frontend"
  type        = string
  default     = "t2.micro"
}

variable "backend_instance_type" {
  description = "Instance type for backend"
  type        = string
  default     = "t2.large"
}

variable "key_name" {
  description = "Name of the EC2 key pair"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet"
  type        = string
}

variable "private_subnet_id" {
  description = "ID of the private subnet"
  type        = string
}

variable "frontend_security_group_id" {
  description = "Security group ID for frontend"
  type        = string
}

variable "backend_security_group_id" {
  description = "Security group ID for backend"
  type        = string
}

variable "nat_gateway_id" {
  description = "ID of the NAT gateway"
  type        = string
}

variable "mongodb_volume_size" {
  description = "Size of the EBS volume for MongoDB data in GB"
  type        = number
  default     = 10
}

variable "mongodb_volume_type" {
  description = "Type of EBS volume for MongoDB data"
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.mongodb_volume_type)
    error_message = "Volume type must be one of: gp2, gp3, io1, io2."
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Owner       = "truh1"
    Project     = "autoremediation"
    InfraName   = "truh1-autoremediation"
  }
}

# --- Root Volume Variables ---
variable "frontend_root_volume_size" {
  description = "Size of the root volume for frontend instance in GB"
  type        = number
  default     = 10
}

variable "frontend_root_volume_type" {
  description = "Type of root volume for frontend instance"
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.frontend_root_volume_type)
    error_message = "Volume type must be one of: gp2, gp3, io1, io2."
  }
}

variable "frontend_root_volume_encrypted" {
  description = "Whether to encrypt the root volume for frontend instance"
  type        = bool
  default     = true
}

variable "backend_root_volume_size" {
  description = "Size of the root volume for backend instance in GB"
  type        = number
  default     = 10
}

variable "backend_root_volume_type" {
  description = "Type of root volume for backend instance"
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.backend_root_volume_type)
    error_message = "Volume type must be one of: gp2, gp3, io1, io2."
  }
}

variable "backend_root_volume_encrypted" {
  description = "Whether to encrypt the root volume for backend instance"
  type        = bool
  default     = true
}

# --- Automation Variables ---
variable "automation_instance_type" {
  description = "Instance type for automation runner"
  type        = string
  default     = "t3.micro"
}

variable "automation_security_group_id" {
  description = "Security group ID for automation runner"
  type        = string
}

variable "automation_iam_instance_profile_name" {
  description = "IAM instance profile name for automation runner"
  type        = string
}





variable "automation_root_volume_size" {
  description = "Size of the root volume for automation instance in GB"
  type        = number
  default     = 10
}

variable "automation_root_volume_type" {
  description = "Type of root volume for automation instance"
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.automation_root_volume_type)
    error_message = "Volume type must be one of: gp2, gp3, io1, io2."
  }
}

variable "automation_root_volume_encrypted" {
  description = "Whether to encrypt the root volume for automation instance"
  type        = bool
  default     = true
}
