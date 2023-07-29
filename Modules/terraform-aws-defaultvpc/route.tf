# route.tf
resource "aws_route_table" "testPublicRTb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.testIGW.id
  }

  tags = {
    "Name" = "test-public-rtb"
  }
}

resource "aws_route_table" "testPrivateRTb" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "test-private-rtb"
  }
}

## route
### subnet associate
resource "aws_route_table_association" "publicRTbAssociation01" {
  subnet_id      = aws_subnet.publicSubnet1.id
  route_table_id = aws_route_table.testPublicRTb.id
}

resource "aws_route_table_association" "publicRTbAssociation02" {
  subnet_id      = aws_subnet.publicSubnet2.id
  route_table_id = aws_route_table.testPublicRTb.id
}

resource "aws_route_table_association" "privateRTbAssociation01" {
  subnet_id      = aws_subnet.privateSubnet1.id
  route_table_id = aws_route_table.testPrivateRTb.id
}

resource "aws_route_table_association" "privateRTbAssociation02" {
  subnet_id      = aws_subnet.privateSubnet2.id
  route_table_id = aws_route_table.testPrivateRTb.id
}
