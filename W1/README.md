# **테라폼 기본 개념**

**resource** : 실제로 생성할 인프라 자원을 의미합니다.

ex) aws_security_group, aws_lb, aws_instance

**provider** : Terraform으로 정의할 Infrastructure Provider를 의미합니다.

https://www.terraform.io/docs/providers/index.html

**output** : 인프라를 프로비저닝 한 후에 생성된 자원을 output 부분으로 뽑을 수 있습니다. Output으로 추출한 부분은 이후에 `remote state`에서 활용할 수 있습니다.

**backend** : terraform의 상태를 저장할 공간을 지정하는 부분입니다. backend를 사용하면 현재 배포된 최신 상태를 외부에 저장하기 때문에 다른 사람과의 협업이 가능합니다. 가장 대표적으로는 AWS S3가 있습니다.

**module** : 공통적으로 활용할 수 있는 인프라 코드를 한 곳으로 모아서 정의하는 부분입니다. Module을 사용하면 변수만 바꿔서 동일한 리소스를 손쉽게 생성할 수 있다는 장점이 있습니다.

**remote state** : remote state를 사용하면 VPC, IAM 등과 같은 공용 서비스를 다른 서비스에서 참조할 수 있습니다. tfstate파일(최신 테라폼 상태정보)이 저장되어 있는 backend 정보를 명시하면, terraform이 해당 backend에서 output 정보들을 가져옵니다.

# **테라폼 기본 환경 설정**

```jsx
# tfenv 설치
brew install tfenv

# 설치 가능 버전 리스트 확인
tfenv list-remote

# 테라폼 1.5.1 버전 설치
tfenv install 1.5.1

# 테라폼 1.5.1 버전 사용 설정 
tfenv use 1.5.1

# tfenv로 설치한 버전 확인
tfenv list

# 테라폼 버전 정보 확인
terraform version

# 자동완성
terraform -install-autocomplete
## 참고 .zshrc 에 아래 추가됨
cat ~/.zshrc
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/terraform terraform
```

결과
![image](https://github.com/adm1njeh0/T101-2/assets/52900923/2d95b2e6-2549-4dbc-b530-78f75c5f99f8)


# **테라폼 형상**

**Terraform init**
지정한 backend에 상태 저장을 위한 .tfstate 파일을 생성합니다. 여기에는 가장 마지막에 적용한 테라폼 내역이 저장됩니다.
init 작업을 완료하면, local에는 .tfstate에 정의된 내용을 담은 .terraform 파일이 생성됩니다.

**Terraform plan**
정의한 코드가 어떤 인프라를 만들게 되는지 미리 예측 결과를 보여줍니다. 단, plan을 한 내용에 에러가 없다고 하더라도, 실제 적용되었을 때는 에러가 발생할 수 있습니다.
Plan 명령어는 어떠한 형상에도 변화를 주지 않습니다.

**Terraform apply**
실제로 인프라를 배포하기 위한 명령어입니다. apply를 완료하면, AWS 상에 실제로 해당 인프라가 생성되고 작업 결과가 backend의 .tfstate 파일에 저장됩니다.
해당 결과는 local의 .terraform 파일에도 저장됩니다.

**Terraform Destroy**

apply로 배포한 인프라를 회수하는 작업입니다.

**Terraform import**
AWS 인프라에 배포된 리소스를 terraform state로 옮겨주는 작업입니다.
이는 local의 .terraform에 해당 리소스의 상태 정보를 저장해주는 역할을 합니다. (절대 코드를 생성해주지 않습니다.)
Apply 전까지는 backend에 저장되지 않습니다.
Import 이후에 plan을 하면 로컬에 해당 코드가 없기 때문에 리소스가 삭제 또는 변경된다는 결과를 보여줍니다. 이 결과를 바탕으로 코드를 작성하실 수 있습니다.

# **테라폼 실습**

1. **EC2 1대 생성 및 삭제**

```jsx
cat <<EOT > main.tf
provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_instance" "example" {
  ami           = "ami-0a0064415cdedc552"
  instance_type = "t2.micro"

  tags = {
    Name = "t101-j2h0-study"
  }

}
EOT
```

**terraform init / terraform plan / terraform apply 단계를 거침**

결과
![image](https://github.com/adm1njeh0/T101-2/assets/52900923/10a49168-b27e-4614-8c85-c0c64590dbb6)
![image](https://github.com/adm1njeh0/T101-2/assets/52900923/c5aa7ab9-e1f2-4f91-9562-d54b1af3956b)


1. **최신 AMI 찾기**

```jsx
aws ssm get-parameters-by-path --path /aws/service/ami-amazon-linux-latest --query "Parameters[].{Name:Name,Value:Value,LastModifiedDate:LastModifiedDate}"
```

→ 이렇게 하면 너무 많은 결과가 나오므로 이름을 기준으로 필터링

결과
![image](https://github.com/adm1njeh0/T101-2/assets/52900923/1bd4e412-cf87-400e-9823-bdff2556a108)


1. **EC2 1대를 배포하면서 Userdata 활용하여 웹서버 운용**

```jsx
cat <<EOT > main.tf
provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_instance" "example" {
  ami                    = "ami-0c9c942bd7bf113a2"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, T101 Study 9090" > index.html
              nohup busybox httpd -f -p 9090 &
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = "Single-WebSrv"
  }
}

resource "aws_security_group" "instance" {
  name = var.security_group_name

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "security_group_name" {
  description = "The name of the security group"
  type        = string
  default     = "terraform-example-instance"
}

output "public_ip" {
  value       = aws_instance.example.public_ip
  description = "The public IP of the Instance"
}
EOT
```

결과
![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/51974a55-24f8-4a02-beb4-ea5c439b6b5c/Untitled.png)

1. **업무수행 중 빈번하게 환경을 만들어 테스트 해야해서, 모듈 구분없이 [main.tf](http://main.tf) 만 이용하여 VPC, Subnet, RT, IGW, NAT + 테스트 서버 까지 테라폼 코드로 테스트 함**

```jsx
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
```

결과
1VPC / 4Subnet / 1IGW / 1NAT / 1EC2 잘 배포되고 원하는 라우팅까지도 설정 문제 없음 확인
