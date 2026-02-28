# --- Monitoring Instance (Prometheus + Grafana in us-east-1) ---

resource "aws_instance" "monitor" {
  provider      = aws.us
  ami           = data.aws_ami.ubuntu_us.id
  instance_type = var.monitor_instance_type
  key_name      = aws_key_pair.us.key_name
  subnet_id     = aws_subnet.us.id

  vpc_security_group_ids      = [aws_security_group.monitor.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  tags = {
    Name   = "${var.deployment_prefix}-monitor"
    Role   = "monitor"
    Region = "us-east-1"
  }
}
