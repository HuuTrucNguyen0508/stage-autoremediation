variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "internal_domain" {
  description = "Internal domain name"
  type        = string
  default     = "internal.aws.ocho.ninja"
}

variable "internal_alb_subdomain" {
  description = "Subdomain for the internal ALB"
  type        = string
  default     = "api.internal.aws.ocho.ninja"
}

variable "internal_alb_dns_name" {
  description = "DNS name of the internal ALB"
  type        = string
}

variable "internal_alb_zone_id" {
  description = "Zone ID of the internal ALB"
  type        = string
}

variable "external_zone_id" {
  description = "ID of the external Route53 zone"
  type        = string
}

variable "frontend_domain" {
  description = "Domain name for the frontend"
  type        = string
  default     = "truhauto.aws.ocho.ninja"
}

variable "frontend_public_ip" {
  description = "Public IP of the frontend instance"
  type        = string
}



variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
