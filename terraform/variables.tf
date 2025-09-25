variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "truh1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "truh1-autoremediation"
}

variable "key_name" {
  description = "Name of the EC2 key pair"
  type        = string
  default     = "truh-autoremed2"
}

variable "my_ip" {
  description = "Your IP address for SSH access"
  type        = string
}

variable "backend_port" {
  description = "Port for the backend application"
  type        = number
  default     = 80
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_az2_cidr" {
  description = "CIDR block for public subnet AZ2"
  type        = string
  default     = "10.0.4.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_az2_cidr" {
  description = "CIDR block for private subnet AZ2"
  type        = string
  default     = "10.0.3.0/24"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "aws.ocho.ninja"
}

variable "frontend_subdomain" {
  description = "Frontend subdomain"
  type        = string
  default     = "truhauto"
}

variable "alb_port" {
  description = "Port for ALB"
  type        = number
  default     = 80
}

variable "mongodb_volume_size" {
  description = "Size of the EBS volume for MongoDB data in GB"
  type        = number
  default     = 20
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
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Owner       = "truh1"
    Project     = "autoremediation"
    InfraName   = "truh1-autoremediation"
  }
}
