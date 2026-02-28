# --- AMI Lookup (Ubuntu 22.04) per region ---

data "aws_ami" "ubuntu_us" {
  provider    = aws.us
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

data "aws_ami" "ubuntu_eu" {
  provider    = aws.eu
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "ubuntu_ap" {
  provider    = aws.ap
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- User Data: format NVMe SSD (i3 instances) ---

locals {
  # NVMe formatting and mounting is handled by the redpanda.cluster.system_setup
  # Ansible role, which mounts to /mnt/vectorized/redpanda and symlinks
  # /var/lib/redpanda to it. Do not duplicate that here.
  broker_user_data = <<-EOF
    #!/bin/bash
    echo "NVMe setup deferred to Ansible"
  EOF
}

# --- US Brokers ---

resource "aws_instance" "broker_us" {
  provider      = aws.us
  count         = var.brokers_per_region
  ami           = data.aws_ami.ubuntu_us.id
  instance_type = var.broker_instance_type
  key_name      = aws_key_pair.us.key_name
  subnet_id     = aws_subnet.us.id

  vpc_security_group_ids  = [aws_security_group.us.id]
  iam_instance_profile    = aws_iam_instance_profile.redpanda_broker.name
  associate_public_ip_address = true

  user_data = local.broker_user_data

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name   = "${var.deployment_prefix}-broker-us-${count.index}"
    Role   = "broker"
    Region = "us-east-1"
    Rack   = "us-east-1"
  }
}

# --- EU Brokers ---

resource "aws_instance" "broker_eu" {
  provider      = aws.eu
  count         = var.brokers_per_region
  ami           = data.aws_ami.ubuntu_eu.id
  instance_type = var.broker_instance_type
  key_name      = aws_key_pair.eu.key_name
  subnet_id     = aws_subnet.eu.id

  vpc_security_group_ids  = [aws_security_group.eu.id]
  iam_instance_profile    = aws_iam_instance_profile.redpanda_broker.name
  associate_public_ip_address = true

  user_data = local.broker_user_data

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name   = "${var.deployment_prefix}-broker-eu-${count.index}"
    Role   = "broker"
    Region = "eu-west-1"
    Rack   = "eu-west-1"
  }
}

# --- AP Brokers ---

resource "aws_instance" "broker_ap" {
  provider      = aws.ap
  count         = var.brokers_per_region
  ami           = data.aws_ami.ubuntu_ap.id
  instance_type = var.broker_instance_type
  key_name      = aws_key_pair.ap.key_name
  subnet_id     = aws_subnet.ap.id

  vpc_security_group_ids  = [aws_security_group.ap.id]
  iam_instance_profile    = aws_iam_instance_profile.redpanda_broker.name
  associate_public_ip_address = true

  user_data = local.broker_user_data

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name   = "${var.deployment_prefix}-broker-ap-${count.index}"
    Role   = "broker"
    Region = "ap-southeast-1"
    Rack   = "ap-southeast-1"
  }
}
