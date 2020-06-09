provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "csye6225_a4_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  enable_classiclink_dns_support = true
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name = "csye6225_a4_vpc",
    Tag2 = "new tag"
  }
}

resource "aws_internet_gateway" "csye6225_a4_gateway" {
    vpc_id = "${aws_vpc.csye6225_a4_vpc.id}"
}

resource "aws_subnet" "csye6225_subnet1" {
  cidr_block = "10.0.0.0/24"
  vpc_id = "${aws_vpc.csye6225_a4_vpc.id}"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "csye6225_a4_subnet_1"
  }
}

resource "aws_subnet" "csye6225_subnet2" {
  cidr_block = "10.0.1.0/24"
  vpc_id = "${aws_vpc.csye6225_a4_vpc.id}"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "csye6225_a4_subnet_2"
  }
}

resource "aws_subnet" "csye6225_subnet3" {
  cidr_block = "10.0.2.0/24"
  vpc_id = "${aws_vpc.csye6225_a4_vpc.id}"
  availability_zone = "us-east-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "csye6225_a4_subnet_3"
  }
}

resource "aws_route_table" "csye6225_a4_route_table" {
    vpc_id = "${aws_vpc.csye6225_a4_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.csye6225_a4_gateway.id}"
    }
}

resource "aws_route_table_association" "csye6225_route_table_subnet1" {
  subnet_id      = aws_subnet.csye6225_subnet1.id
  route_table_id = aws_route_table.csye6225_a4_route_table.id
}

resource "aws_route_table_association" "csye6225_route_table_subnet2" {
  subnet_id      = aws_subnet.csye6225_subnet2.id
  route_table_id = aws_route_table.csye6225_a4_route_table.id
}

resource "aws_route_table_association" "csye6225_route_table_subnet3" {
  subnet_id      = aws_subnet.csye6225_subnet3.id
  route_table_id = aws_route_table.csye6225_a4_route_table.id
}
