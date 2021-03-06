data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.64.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.username}-main-vpc"
  }
}

resource "aws_subnet" "main_az_1_public" {
  vpc_id                  = aws_vpc.main_vpc.id
  availability_zone       = local.region_az_1
  cidr_block              = "10.64.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    "Name" = "${var.username}-main-public-subnet-1"
  }
}

resource "aws_internet_gateway" "main_vpc_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.username}-main-vpc-igw"
  }
}

resource "aws_security_group" "main" {
  name        = "${var.username}-main-sg"
  description = "Allow SSH ICMP and HTTPS"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Allow SSH"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow ICMP"
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    protocol    = "tcp"
    from_port   = 0
    to_port     = 6443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alpha" {
  name        = "${var.username}-alpha-sg"
  description = "Allow all communication within the alpha security group"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Allow all traffic sourced from this security group"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    self        = true
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "internal" {
  name        = "${var.username}-internal-sg"
  description = "Allow all communication within the VPC CIDR"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Allow all traffic from within the VPC CIDR"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["10.64.0.0/16"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main_vpc.id
  
  tags = {
    Name = "${var.username}-main-route-table"
  }
}

resource "aws_route" "main_igw_route" {
  route_table_id = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main_vpc_igw.id
}

resource "aws_route_table_association" "main_az_1_public_association" {
  subnet_id = aws_subnet.main_az_1_public.id 
  route_table_id = aws_route_table.main.id 
}

resource "aws_eip" "lb_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.main_vpc_igw]

  tags = {
    Name = "${var.username}-lb-eip"
  }
}
