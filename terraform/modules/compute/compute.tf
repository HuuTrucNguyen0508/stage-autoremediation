# --- Data Sources ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# --- EC2 Instances ---
resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.frontend_instance_type
  subnet_id                   = var.public_subnet_id
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.frontend_security_group_id]

  # Root volume configuration
  root_block_device {
    volume_size           = var.frontend_root_volume_size
    volume_type           = var.frontend_root_volume_type
    encrypted             = var.frontend_root_volume_encrypted
    delete_on_termination = true
    tags = merge(var.tags, {
      Name        = "${var.name_prefix}-frontend-root-volume"
      role        = "root-volume"
      environment = "dev"
      truh1       = "truh1"
      app_type    = "frontend"
      component   = "storage"
    })
  }

  # Enable IMDSv2 (Instance Metadata Service version 2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # This enforces IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-frontend-ec2"
    role        = "frontend"
    environment = "dev"
    truh1       = "truh1"
    app_type    = "frontend"
    component   = "web"
  })
}

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.backend_instance_type
  subnet_id              = var.private_subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.backend_security_group_id]

  # Root volume configuration
  root_block_device {
    volume_size           = var.backend_root_volume_size
    volume_type           = var.backend_root_volume_type
    encrypted             = var.backend_root_volume_encrypted
    delete_on_termination = true
    tags = merge(var.tags, {
      Name        = "${var.name_prefix}-backend-root-volume"
      role        = "root-volume"
      environment = "dev"
      truh1       = "truh1"
      app_type    = "backend"
      component   = "storage"
    })
  }

  # Enable IMDSv2 (Instance Metadata Service version 2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # This enforces IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  depends_on = [
    var.nat_gateway_id
  ]

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-backend-ec2"
    role        = "backend"
    environment = "dev"
    truh1       = "truh1"
    app_type    = "backend"
    component   = "api"
  })
}

# --- EBS Volume for MongoDB Data ---
resource "aws_ebs_volume" "mongodb_data" {
  availability_zone = aws_instance.backend.availability_zone
  size              = var.mongodb_volume_size
  type              = var.mongodb_volume_type
  encrypted         = true

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-mongodb-data-volume"
    role        = "mongodb-data"
    environment = "dev"
    truh1       = "truh1"
    app_type    = "database"
    component   = "mongodb"
  })
}

# --- EBS Volume Attachment ---
resource "aws_volume_attachment" "mongodb_data_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.mongodb_data.id
  instance_id = aws_instance.backend.id

  depends_on = [aws_instance.backend, aws_ebs_volume.mongodb_data]

  # Add lifecycle rule to handle detachment gracefully
  lifecycle {
    ignore_changes = [instance_id]
  }
}

# --- Elastic IP ---
resource "aws_eip" "frontend" {
  instance = aws_instance.frontend.id
  domain   = "vpc"
  tags     = merge(var.tags, { Name = "${var.name_prefix}-frontend-eip" })
}

# --- Null resource to handle EBS volume detachment ---
resource "null_resource" "ebs_volume_cleanup" {
  triggers = {
    instance_id = aws_instance.backend.id
    volume_id   = aws_ebs_volume.mongodb_data.id
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Attempting to detach EBS volume ${self.triggers.volume_id} from instance ${self.triggers.instance_id}..."
      aws ec2 detach-volume --volume-id ${self.triggers.volume_id} --force || true
      echo "Waiting for volume to be available..."
      aws ec2 wait volume-available --volume-ids ${self.triggers.volume_id} || true
    EOT
  }

  depends_on = [aws_volume_attachment.mongodb_data_attachment, aws_instance.backend]
}

# --- Automation EC2 Instance ---
resource "aws_instance" "automation" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.automation_instance_type
  subnet_id              = var.private_subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.automation_security_group_id]
  iam_instance_profile   = var.automation_iam_instance_profile_name

  # Root volume configuration
  root_block_device {
    volume_size           = var.automation_root_volume_size
    volume_type           = var.automation_root_volume_type
    encrypted             = var.automation_root_volume_encrypted
    delete_on_termination = true
    tags = merge(var.tags, {
      Name        = "${var.name_prefix}-automation-root-volume"
      role        = "root-volume"
      environment = "dev"
      truh1       = "truh1"
      app_type    = "automation"
      component   = "storage"
    })
  }

  # Enable IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  depends_on = [
    var.nat_gateway_id
  ]

  tags = merge(var.tags, {
    Name        = "${var.name_prefix}-automation-runner"
    role        = "automation"
    environment = "dev"
    truh1       = "truh1"
    app_type    = "automation"
    component   = "runner"
  })
}
