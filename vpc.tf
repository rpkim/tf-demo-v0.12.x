locals {
  name       = "Terraform Testing"
  cidr_block = "10.0.0.0/16"
  app_name   = "suite"
  tag_name   = "${local.app_name} ${local.name}"
}

resource "aws_vpc" "main" {
  cidr_block       = local.cidr_block
  instance_tenancy = "dedicated"

  tags = {
    Name  = local.tag_name
    Owner = "SRED"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = local.tag_name
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = local.tag_name
  }
}

resource "aws_subnet" "db" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = local.tag_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = local.tag_name
  }
}


resource "aws_eip" "nat_eips" {
  vpc   = "true"
}


resource "aws_nat_gateway" "nats" {
  subnet_id     = aws_subnet.public.id
  allocation_id = aws_eip.nat_eips.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
		Name = "${local.app_name} private"
	}
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.app_name} public"
	}
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.app_name} db"
	}
}

resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  route_table_id         = aws_route_table.public.id
}

resource "aws_route" "private" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nats.id
  route_table_id         = aws_route_table.private.id
}

resource "aws_route" "db" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nats.id
  route_table_id         = aws_route_table.db.id
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public.id
}

resource "aws_route_table_association" "private" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private.id
}

resource "aws_route_table_association" "db" {
  route_table_id = aws_route_table.db.id
  subnet_id      = aws_subnet.db.id
}
