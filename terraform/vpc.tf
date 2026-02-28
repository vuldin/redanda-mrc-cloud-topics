# --- US-EAST-1 VPC ---

resource "aws_vpc" "us" {
  provider             = aws.us
  cidr_block           = local.regions.us.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.deployment_prefix}-vpc-us" }
}

resource "aws_subnet" "us" {
  provider                = aws.us
  vpc_id                  = aws_vpc.us.id
  cidr_block              = local.regions.us.subnet_cidr
  availability_zone       = local.regions.us.az
  map_public_ip_on_launch = true

  tags = { Name = "${var.deployment_prefix}-subnet-us" }
}

resource "aws_internet_gateway" "us" {
  provider = aws.us
  vpc_id   = aws_vpc.us.id

  tags = { Name = "${var.deployment_prefix}-igw-us" }
}

resource "aws_route_table" "us" {
  provider = aws.us
  vpc_id   = aws_vpc.us.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.us.id
  }

  tags = { Name = "${var.deployment_prefix}-rt-us" }
}

resource "aws_route_table_association" "us" {
  provider       = aws.us
  subnet_id      = aws_subnet.us.id
  route_table_id = aws_route_table.us.id
}

# --- EU-WEST-1 VPC ---

resource "aws_vpc" "eu" {
  provider             = aws.eu
  cidr_block           = local.regions.eu.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.deployment_prefix}-vpc-eu" }
}

resource "aws_subnet" "eu" {
  provider                = aws.eu
  vpc_id                  = aws_vpc.eu.id
  cidr_block              = local.regions.eu.subnet_cidr
  availability_zone       = local.regions.eu.az
  map_public_ip_on_launch = true

  tags = { Name = "${var.deployment_prefix}-subnet-eu" }
}

resource "aws_internet_gateway" "eu" {
  provider = aws.eu
  vpc_id   = aws_vpc.eu.id

  tags = { Name = "${var.deployment_prefix}-igw-eu" }
}

resource "aws_route_table" "eu" {
  provider = aws.eu
  vpc_id   = aws_vpc.eu.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eu.id
  }

  tags = { Name = "${var.deployment_prefix}-rt-eu" }
}

resource "aws_route_table_association" "eu" {
  provider       = aws.eu
  subnet_id      = aws_subnet.eu.id
  route_table_id = aws_route_table.eu.id
}

# --- AP-SOUTHEAST-1 VPC ---

resource "aws_vpc" "ap" {
  provider             = aws.ap
  cidr_block           = local.regions.ap.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.deployment_prefix}-vpc-ap" }
}

resource "aws_subnet" "ap" {
  provider                = aws.ap
  vpc_id                  = aws_vpc.ap.id
  cidr_block              = local.regions.ap.subnet_cidr
  availability_zone       = local.regions.ap.az
  map_public_ip_on_launch = true

  tags = { Name = "${var.deployment_prefix}-subnet-ap" }
}

resource "aws_internet_gateway" "ap" {
  provider = aws.ap
  vpc_id   = aws_vpc.ap.id

  tags = { Name = "${var.deployment_prefix}-igw-ap" }
}

resource "aws_route_table" "ap" {
  provider = aws.ap
  vpc_id   = aws_vpc.ap.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ap.id
  }

  tags = { Name = "${var.deployment_prefix}-rt-ap" }
}

resource "aws_route_table_association" "ap" {
  provider       = aws.ap
  subnet_id      = aws_subnet.ap.id
  route_table_id = aws_route_table.ap.id
}

# --- SSH Key Pairs (one per region) ---

resource "aws_key_pair" "us" {
  provider   = aws.us
  key_name   = "${var.deployment_prefix}-key"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_key_pair" "eu" {
  provider   = aws.eu
  key_name   = "${var.deployment_prefix}-key"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_key_pair" "ap" {
  provider   = aws.ap
  key_name   = "${var.deployment_prefix}-key"
  public_key = file(var.ssh_public_key_path)
}
