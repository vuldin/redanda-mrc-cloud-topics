# --- Workload Generator Instances (1 per region) ---

resource "aws_instance" "client_us" {
  provider      = aws.us
  ami           = data.aws_ami.ubuntu_us.id
  instance_type = var.client_instance_type
  key_name      = aws_key_pair.us.key_name
  subnet_id     = aws_subnet.us.id

  vpc_security_group_ids      = [aws_security_group.us.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name   = "${var.deployment_prefix}-client-us"
    Role   = "client"
    Region = "us-east-1"
    Rack   = "us-east-1"
  }
}

resource "aws_instance" "client_eu" {
  provider      = aws.eu
  ami           = data.aws_ami.ubuntu_eu.id
  instance_type = var.client_instance_type
  key_name      = aws_key_pair.eu.key_name
  subnet_id     = aws_subnet.eu.id

  vpc_security_group_ids      = [aws_security_group.eu.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name   = "${var.deployment_prefix}-client-eu"
    Role   = "client"
    Region = "eu-west-1"
    Rack   = "eu-west-1"
  }
}

resource "aws_instance" "client_ap" {
  provider      = aws.ap
  ami           = data.aws_ami.ubuntu_ap.id
  instance_type = var.client_instance_type
  key_name      = aws_key_pair.ap.key_name
  subnet_id     = aws_subnet.ap.id

  vpc_security_group_ids      = [aws_security_group.ap.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name   = "${var.deployment_prefix}-client-ap"
    Role   = "client"
    Region = "ap-southeast-1"
    Rack   = "ap-southeast-1"
  }
}
