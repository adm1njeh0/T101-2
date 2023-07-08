provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_vpc" "Test_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Test_vpc"
  }
}

#enable_dns_hostnames = true
#enable_dns_support = true

resource "aws_subnet" "Test_public_subnet1" {
  vpc_id     = aws_vpc.Test_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  availability_zone = "ap-northeast-2a"
  
  tags = {
    Name = "Test_public_subnet1"
  }
}

resource "aws_subnet" "Test_public_subnet2" {
  vpc_id     = aws_vpc.Test_vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "Test_public_subnet2"
  }
}

resource "aws_internet_gateway" "Test_IGW" {
  vpc_id = aws_vpc.Test_vpc.id

  tags = {
    Name = "Test_IGW"
  }
}

resource "aws_route_table" "Test_public_rt" {
  vpc_id = aws_vpc.Test_vpc.id
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.Test_IGW.id
    }

  tags = {
    Name = "Test_public_rt"
  }
}

resource "aws_route_table_association" "Test_public_rt_association_1" {
  subnet_id      = aws_subnet.Test_public_subnet1.id
  route_table_id = aws_route_table.Test_public_rt.id
}

resource "aws_route_table_association" "Test_public_rt_association_2" {
  subnet_id      = aws_subnet.Test_public_subnet2.id
  route_table_id = aws_route_table.Test_public_rt.id
}

resource "aws_subnet" "Test_private_subnet1" {
  vpc_id     = aws_vpc.Test_vpc.id
  cidr_block = "10.0.11.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "Test_private_subnet1"
  }
}

resource "aws_subnet" "Test_private_subnet2" {
  vpc_id     = aws_vpc.Test_vpc.id
  cidr_block = "10.0.12.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "Test_private_subnet2"
  }
}

resource "aws_eip" "Test_nat_ip" {
  vpc   = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "Test_nat_gateway" {
  allocation_id = aws_eip.Test_nat_ip.id

  subnet_id = aws_subnet.Test_public_subnet1.id

  tags = {
    Name = "Test_nat_gateway"
  }
}

resource "aws_route_table" "Test_private_rt" {
  vpc_id = aws_vpc.Test_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Test_nat_gateway.id
    }

  tags = {
    Name = "Test_private_rt"
  }
}

resource "aws_route_table_association" "Test_private_rt_association1" {
  subnet_id      = aws_subnet.Test_private_subnet1.id
  route_table_id = aws_route_table.Test_private_rt.id
}

resource "aws_route_table_association" "Test_private_rt_association2" {
  subnet_id      = aws_subnet.Test_private_subnet2.id
  route_table_id = aws_route_table.Test_private_rt.id
}

resource "aws_instance" "Test_pub_instance" {
  ami                    = "ami-0462a914135d20297"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.Test_pub_sg.id]
  subnet_id              = aws_subnet.Test_public_subnet1.id

  user_data = <<-EOF
              #!/bin/bash
              sudo su
              yum -y update 
              yum -y install httpd
              echo "this is j2h0 test instance <p>" > /var/www/html/index.html
              hostname >> /var/www/html/index.html
              service httpd start
              EOF
  #user_data_replace_on_change          = true   

  tags = {
    Name = "Test_pub_instance"
  }
}

resource "aws_security_group" "Test_pub_sg" {
  name = var.security_group_name
  vpc_id     = aws_vpc.Test_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

}

variable "security_group_name" {
  description = "The name of the security group"
  type        = string
  default     = "Test_pub_sg"
}

output "public_ip" {
  value       = aws_instance.Test_pub_instance.public_ip
  description = "The public IP of the Instance"
}
