# --- Security Group: US ---

resource "aws_security_group" "us" {
  provider    = aws.us
  name_prefix = "${var.deployment_prefix}-redpanda-"
  description = "Redpanda MRC cluster - us-east-1"
  vpc_id      = aws_vpc.us.id

  tags = { Name = "${var.deployment_prefix}-sg-us" }
}

resource "aws_security_group" "monitor" {
  provider    = aws.us
  name_prefix = "${var.deployment_prefix}-monitor-"
  description = "Monitoring stack - us-east-1"
  vpc_id      = aws_vpc.us.id

  tags = { Name = "${var.deployment_prefix}-sg-monitor" }
}

# --- Security Group: EU ---

resource "aws_security_group" "eu" {
  provider    = aws.eu
  name_prefix = "${var.deployment_prefix}-redpanda-"
  description = "Redpanda MRC cluster - eu-west-1"
  vpc_id      = aws_vpc.eu.id

  tags = { Name = "${var.deployment_prefix}-sg-eu" }
}

# --- Security Group: AP ---

resource "aws_security_group" "ap" {
  provider    = aws.ap
  name_prefix = "${var.deployment_prefix}-redpanda-"
  description = "Redpanda MRC cluster - ap-southeast-1"
  vpc_id      = aws_vpc.ap.id

  tags = { Name = "${var.deployment_prefix}-sg-ap" }
}

# --- Common Redpanda rules applied to all regional SGs ---

locals {
  redpanda_sgs = {
    us = aws_security_group.us.id
    eu = aws_security_group.eu.id
    ap = aws_security_group.ap.id
  }

  redpanda_sg_providers = {
    us = "aws.us"
    eu = "aws.eu"
    ap = "aws.ap"
  }

  # Ports open to all VPC CIDRs (cross-region Raft/Kafka)
  internal_ports = [
    { port = 33145, desc = "Redpanda RPC" },
    { port = 9092, desc = "Kafka API" },
    { port = 9644, desc = "Admin API" },
    { port = 8082, desc = "HTTP Proxy" },
    { port = 8081, desc = "Schema Registry" },
    { port = 9100, desc = "Node Exporter" },
  ]
}

# US security group rules
resource "aws_vpc_security_group_ingress_rule" "us_ssh" {
  provider          = aws.us
  security_group_id = aws_security_group.us.id
  description       = "SSH"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "us_internal" {
  for_each          = { for p in local.internal_ports : "${p.port}" => p }
  provider          = aws.us
  security_group_id = aws_security_group.us.id
  description       = "${each.value.desc} from all VPCs"
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
  cidr_ipv4         = "10.0.0.0/8"
}

resource "aws_vpc_security_group_ingress_rule" "us_kafka_external" {
  for_each          = toset(var.allowed_ssh_cidrs)
  provider          = aws.us
  security_group_id = aws_security_group.us.id
  description       = "Kafka API external"
  from_port         = 9092
  to_port           = 9092
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "us_admin_external" {
  for_each          = toset(var.allowed_ssh_cidrs)
  provider          = aws.us
  security_group_id = aws_security_group.us.id
  description       = "Admin API external"
  from_port         = 9644
  to_port           = 9644
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "us_envoy" {
  provider          = aws.us
  security_group_id = aws_security_group.us.id
  description       = "Envoy S3 proxy"
  from_port         = 9000
  to_port           = 9000
  ip_protocol       = "tcp"
  cidr_ipv4         = local.regions.us.vpc_cidr
}

resource "aws_vpc_security_group_ingress_rule" "us_envoy_admin" {
  provider          = aws.us
  security_group_id = aws_security_group.us.id
  description       = "Envoy admin"
  from_port         = 9901
  to_port           = 9901
  ip_protocol       = "tcp"
  cidr_ipv4         = "10.0.0.0/8"
}

resource "aws_vpc_security_group_egress_rule" "us_all" {
  provider          = aws.us
  security_group_id = aws_security_group.us.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# EU security group rules
resource "aws_vpc_security_group_ingress_rule" "eu_ssh" {
  provider          = aws.eu
  security_group_id = aws_security_group.eu.id
  description       = "SSH"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "eu_internal" {
  for_each          = { for p in local.internal_ports : "${p.port}" => p }
  provider          = aws.eu
  security_group_id = aws_security_group.eu.id
  description       = "${each.value.desc} from all VPCs"
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
  cidr_ipv4         = "10.0.0.0/8"
}

resource "aws_vpc_security_group_ingress_rule" "eu_kafka_external" {
  for_each          = toset(var.allowed_ssh_cidrs)
  provider          = aws.eu
  security_group_id = aws_security_group.eu.id
  description       = "Kafka API external"
  from_port         = 9092
  to_port           = 9092
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "eu_admin_external" {
  for_each          = toset(var.allowed_ssh_cidrs)
  provider          = aws.eu
  security_group_id = aws_security_group.eu.id
  description       = "Admin API external"
  from_port         = 9644
  to_port           = 9644
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "eu_envoy" {
  provider          = aws.eu
  security_group_id = aws_security_group.eu.id
  description       = "Envoy S3 proxy"
  from_port         = 9000
  to_port           = 9000
  ip_protocol       = "tcp"
  cidr_ipv4         = local.regions.eu.vpc_cidr
}

resource "aws_vpc_security_group_ingress_rule" "eu_envoy_admin" {
  provider          = aws.eu
  security_group_id = aws_security_group.eu.id
  description       = "Envoy admin"
  from_port         = 9901
  to_port           = 9901
  ip_protocol       = "tcp"
  cidr_ipv4         = "10.0.0.0/8"
}

resource "aws_vpc_security_group_egress_rule" "eu_all" {
  provider          = aws.eu
  security_group_id = aws_security_group.eu.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# AP security group rules
resource "aws_vpc_security_group_ingress_rule" "ap_ssh" {
  provider          = aws.ap
  security_group_id = aws_security_group.ap.id
  description       = "SSH"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ap_internal" {
  for_each          = { for p in local.internal_ports : "${p.port}" => p }
  provider          = aws.ap
  security_group_id = aws_security_group.ap.id
  description       = "${each.value.desc} from all VPCs"
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
  cidr_ipv4         = "10.0.0.0/8"
}

resource "aws_vpc_security_group_ingress_rule" "ap_kafka_external" {
  for_each          = toset(var.allowed_ssh_cidrs)
  provider          = aws.ap
  security_group_id = aws_security_group.ap.id
  description       = "Kafka API external"
  from_port         = 9092
  to_port           = 9092
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "ap_admin_external" {
  for_each          = toset(var.allowed_ssh_cidrs)
  provider          = aws.ap
  security_group_id = aws_security_group.ap.id
  description       = "Admin API external"
  from_port         = 9644
  to_port           = 9644
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_ingress_rule" "ap_envoy" {
  provider          = aws.ap
  security_group_id = aws_security_group.ap.id
  description       = "Envoy S3 proxy"
  from_port         = 9000
  to_port           = 9000
  ip_protocol       = "tcp"
  cidr_ipv4         = local.regions.ap.vpc_cidr
}

resource "aws_vpc_security_group_ingress_rule" "ap_envoy_admin" {
  provider          = aws.ap
  security_group_id = aws_security_group.ap.id
  description       = "Envoy admin"
  from_port         = 9901
  to_port           = 9901
  ip_protocol       = "tcp"
  cidr_ipv4         = "10.0.0.0/8"
}

resource "aws_vpc_security_group_egress_rule" "ap_all" {
  provider          = aws.ap
  security_group_id = aws_security_group.ap.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# --- Monitoring security group rules ---

resource "aws_vpc_security_group_ingress_rule" "monitor_ssh" {
  provider          = aws.us
  security_group_id = aws_security_group.monitor.id
  description       = "SSH"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "monitor_prometheus" {
  provider          = aws.us
  security_group_id = aws_security_group.monitor.id
  description       = "Prometheus"
  from_port         = 9090
  to_port           = 9090
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "monitor_grafana" {
  provider          = aws.us
  security_group_id = aws_security_group.monitor.id
  description       = "Grafana"
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "monitor_all" {
  provider          = aws.us
  security_group_id = aws_security_group.monitor.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
