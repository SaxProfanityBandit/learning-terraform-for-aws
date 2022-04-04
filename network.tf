resource "aws_vpc" "flask_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "FlaskDev_VPC"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.flask_vpc.id}"

  tags = {
    Name = "FlaskDev_IG"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.flask_vpc.id}"

  tags = {
    Name = "FlaskDev_Public_Route_Table"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = "${aws_route_table.public_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.flask_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "FlaskDev_Subnet"
  }
}