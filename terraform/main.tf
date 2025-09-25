provider "aws" {
  region = var.aws_region
}

# --- Data Sources ---
data "aws_route53_zone" "truhauto" {
  name         = "aws.ocho.ninja."
  private_zone = false
}

# --- Network Module ---
module "network" {
  source = "./modules/network"

  aws_region              = var.aws_region
  name_prefix             = var.name_prefix
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidr      = var.public_subnet_cidr
  public_subnet_az2_cidr  = var.public_subnet_az2_cidr
  private_subnet_cidr     = var.private_subnet_cidr
  private_subnet_az2_cidr = var.private_subnet_az2_cidr
  tags                    = var.tags
}

# --- Security Module ---
module "security" {
  source = "./modules/security"

  name_prefix  = var.name_prefix
  vpc_id       = module.network.vpc_id
  my_ip        = var.my_ip
  backend_port = var.backend_port
  tags         = var.tags
}

# --- Load Balancer Module ---
module "loadbalancer" {
  source = "./modules/loadbalancer"

  name_prefix           = var.name_prefix
  vpc_id                = module.network.vpc_id
  private_subnet_id     = module.network.private_subnet_id
  private_subnet_az2_id = module.network.private_subnet_az2_id
  alb_security_group_id = module.security.alb_security_group_id
  backend_port          = var.backend_port
  webhook_port          = 9000
  tags                  = var.tags

  depends_on = [module.network, module.security]
}

# --- Compute Module ---
module "compute" {
  source = "./modules/compute"

  name_prefix                          = var.name_prefix
  key_name                             = var.key_name
  public_subnet_id                     = module.network.public_subnet_id
  private_subnet_id                    = module.network.private_subnet_id
  frontend_security_group_id           = module.security.frontend_security_group_id
  backend_security_group_id            = module.security.backend_security_group_id
  automation_security_group_id         = module.security.automation_runner_security_group_id
  automation_iam_instance_profile_name = module.automation_iam.automation_instance_profile_name
  nat_gateway_id                       = module.network.nat_gateway_id
  mongodb_volume_size                  = var.mongodb_volume_size
  mongodb_volume_type                  = var.mongodb_volume_type
  tags                                 = var.tags
}

# --- Load Balancer Target Group Attachment ---
resource "aws_lb_target_group_attachment" "backend" {
  target_group_arn = module.loadbalancer.target_group_arn
  target_id        = module.compute.backend_instance_id
  port             = var.backend_port

  depends_on = [module.compute, module.loadbalancer]
}

# --- Webhook Target Group Attachment ---
resource "aws_lb_target_group_attachment" "webhook" {
  target_group_arn = module.loadbalancer.webhook_target_group_arn
  target_id        = module.compute.automation_instance_id
  port             = 9000

  depends_on = [module.compute, module.loadbalancer]
}

# --- DNS Module ---
module "dns" {
  source = "./modules/dns"

  name_prefix           = var.name_prefix
  vpc_id                = module.network.vpc_id
  internal_alb_dns_name = module.loadbalancer.alb_dns_name
  internal_alb_zone_id  = module.loadbalancer.alb_zone_id
  external_zone_id      = data.aws_route53_zone.truhauto.zone_id
  frontend_public_ip    = module.compute.frontend_public_ip

  tags = var.tags

  depends_on = [module.network, module.loadbalancer, module.compute]
}

# --- Automation IAM Module ---
module "automation_iam" {
  source = "./modules/automation-iam"

  name_prefix = var.name_prefix
  tags        = var.tags
}


