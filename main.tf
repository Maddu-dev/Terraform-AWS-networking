#---------networking/main.tf-----------
data "aws_availability_zones" "available" {}

resource "random_integer" "random" {

  min = 1
  max = 100
}

resource "random_shuffle" "az_list" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}

resource "aws_vpc" "maddu_vpc" {
  #cidr_block = var.vpc_cidr
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "maddu_vpc-${random_integer.random.id}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "maddu_public_subnet" {
  count                   = var.public_sn_count
  vpc_id                  = aws_vpc.maddu_vpc.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "maddu_public-${count.index + 1}"
  }
}

resource "aws_route_table_association" "maddu_public_assoc" {
  count          = var.public_sn_count
  subnet_id      = aws_subnet.maddu_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.maddu_public_rt.id
}
resource "aws_subnet" "maddu_private_subnet" {
  count                   = var.private_sn_count
  vpc_id                  = aws_vpc.maddu_vpc.id
  cidr_block              = var.private_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "maddu_private-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "maddu_igw" {
  vpc_id = aws_vpc.maddu_vpc.id
  tags = {
    Name = "maddu_igw"
  }
}

resource "aws_route_table" "maddu_public_rt" {
  vpc_id = aws_vpc.maddu_vpc.id
  tags = {
    Name = "maddu_public_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.maddu_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.maddu_igw.id
}

resource "aws_default_route_table" "maddu_private_rt" {
  default_route_table_id = aws_vpc.maddu_vpc.default_route_table_id
  tags = {
    Name = "maddu_private_rt"
  }
}

resource "aws_security_group" "maddu_sg" {
  for_each    = var.security_groups
  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.maddu_vpc.id
  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "maddu_rds_subnetgroup" {
  count      = var.db_subnet_group == true ? 1 : 0
  name       = "maddu_rds_subnetgroup"
  subnet_ids = aws_subnet.maddu_private_subnet.*.id
  tags = {
    Name = "maddu_rds_sng"
  }
}





