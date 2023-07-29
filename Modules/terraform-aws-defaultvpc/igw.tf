resource "aws_internet_gateway" "testIGW" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "testIGW"
  }
}
