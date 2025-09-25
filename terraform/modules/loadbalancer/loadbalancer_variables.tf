variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_id" {
  description = "ID of the private subnet in AZ1"
  type        = string
}

variable "private_subnet_az2_id" {
  description = "ID of the private subnet in AZ2"
  type        = string
}

variable "alb_security_group_id" {
  description = "ID of the ALB security group"
  type        = string
}

variable "backend_port" {
  description = "Port for the backend application"
  type        = number
  default     = 80
}

variable "webhook_port" {
  description = "Port for webhook traffic"
  type        = number
  default     = 9000
}



variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
