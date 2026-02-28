# --- VPC Peering: US <-> EU ---

resource "aws_vpc_peering_connection" "us_eu" {
  provider    = aws.us
  vpc_id      = aws_vpc.us.id
  peer_vpc_id = aws_vpc.eu.id
  peer_region = "eu-west-1"

  tags = { Name = "${var.deployment_prefix}-peer-us-eu" }
}

resource "aws_vpc_peering_connection_accepter" "us_eu" {
  provider                  = aws.eu
  vpc_peering_connection_id = aws_vpc_peering_connection.us_eu.id
  auto_accept               = true

  tags = { Name = "${var.deployment_prefix}-peer-us-eu" }
}

resource "aws_route" "us_to_eu" {
  provider                  = aws.us
  route_table_id            = aws_route_table.us.id
  destination_cidr_block    = local.regions.eu.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_eu.id
}

resource "aws_route" "eu_to_us" {
  provider                  = aws.eu
  route_table_id            = aws_route_table.eu.id
  destination_cidr_block    = local.regions.us.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_eu.id
}

# --- VPC Peering: US <-> AP ---

resource "aws_vpc_peering_connection" "us_ap" {
  provider    = aws.us
  vpc_id      = aws_vpc.us.id
  peer_vpc_id = aws_vpc.ap.id
  peer_region = "ap-southeast-1"

  tags = { Name = "${var.deployment_prefix}-peer-us-ap" }
}

resource "aws_vpc_peering_connection_accepter" "us_ap" {
  provider                  = aws.ap
  vpc_peering_connection_id = aws_vpc_peering_connection.us_ap.id
  auto_accept               = true

  tags = { Name = "${var.deployment_prefix}-peer-us-ap" }
}

resource "aws_route" "us_to_ap" {
  provider                  = aws.us
  route_table_id            = aws_route_table.us.id
  destination_cidr_block    = local.regions.ap.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_ap.id
}

resource "aws_route" "ap_to_us" {
  provider                  = aws.ap
  route_table_id            = aws_route_table.ap.id
  destination_cidr_block    = local.regions.us.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.us_ap.id
}

# --- VPC Peering: EU <-> AP ---

resource "aws_vpc_peering_connection" "eu_ap" {
  provider    = aws.eu
  vpc_id      = aws_vpc.eu.id
  peer_vpc_id = aws_vpc.ap.id
  peer_region = "ap-southeast-1"

  tags = { Name = "${var.deployment_prefix}-peer-eu-ap" }
}

resource "aws_vpc_peering_connection_accepter" "eu_ap" {
  provider                  = aws.ap
  vpc_peering_connection_id = aws_vpc_peering_connection.eu_ap.id
  auto_accept               = true

  tags = { Name = "${var.deployment_prefix}-peer-eu-ap" }
}

resource "aws_route" "eu_to_ap" {
  provider                  = aws.eu
  route_table_id            = aws_route_table.eu.id
  destination_cidr_block    = local.regions.ap.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.eu_ap.id
}

resource "aws_route" "ap_to_eu" {
  provider                  = aws.ap
  route_table_id            = aws_route_table.ap.id
  destination_cidr_block    = local.regions.eu.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.eu_ap.id
}
