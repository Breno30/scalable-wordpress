# Core networking
resource "aws_vpc" "app" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}


# Public subnets contain only internet-facing resources such as the ALB and NAT.
resource "aws_subnet" "app_a" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

}

resource "aws_subnet" "app_b" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

}

# Private application subnets contain EC2, EFS mount targets, and Valkey.
# They can start outbound connections through NAT, but cannot receive connections
# directly from the internet.
resource "aws_subnet" "private_app_a" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private_app_b" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = "10.0.22.0/24"
  availability_zone = "us-east-1b"
}

# Private database subnets have no route to the internet gateway.
resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "db_b" {
  vpc_id            = aws_vpc.app.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "us-east-1b"
}

locals {
  public_subnet_ids = {
    subnet_a = aws_subnet.app_a.id
    subnet_b = aws_subnet.app_b.id
  }

  private_app_subnet_ids = {
    subnet_a = aws_subnet.private_app_a.id
    subnet_b = aws_subnet.private_app_b.id
  }
}

# Public network routing
resource "aws_internet_gateway" "app" {
  vpc_id = aws_vpc.app.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app.id
  }

}

resource "aws_route_table_association" "app_a" {
  subnet_id      = aws_subnet.app_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "app_b" {
  subnet_id      = aws_subnet.app_b.id
  route_table_id = aws_route_table.public.id
}

# One NAT gateway per Availability Zone keeps private application instances able
# to download updates without assigning them public IP addresses.
resource "aws_eip" "nat" {
  for_each = local.public_subnet_ids
  domain   = "vpc"

  depends_on = [aws_internet_gateway.app]
}

resource "aws_nat_gateway" "app" {
  for_each      = local.public_subnet_ids
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value

  depends_on = [aws_internet_gateway.app]
}

resource "aws_route_table" "private_app" {
  for_each = local.private_app_subnet_ids
  vpc_id   = aws_vpc.app.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.app[each.key].id
  }
}

resource "aws_route_table_association" "private_app" {
  for_each       = local.private_app_subnet_ids
  subnet_id      = each.value
  route_table_id = aws_route_table.private_app[each.key].id
}