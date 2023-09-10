provider "aws" {
  region = "us-east-2"  # Replace with your desired AWS region
}

resource "aws_vpc" "workstation-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "workstation-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.workstation-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"  # Replace with your desired availability zone

  tags = {
    Name = "workstation-public-subnet"
  }
}

resource "aws_internet_gateway" "workstation-igw" {
  vpc_id = aws_vpc.workstation-vpc.id

  tags = {
    Name = "workstation-internet-gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.workstation-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.workstation-igw.id
  }

  tags = {
    Name = "workstation-public-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "workstation-sg" {
  name        = "workstation-security-group"
  description = "Allow SSH, HTTP, and HTTPS inbound traffic"
  vpc_id      = aws_vpc.workstation-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "workstation-security-group"
  }
}

resource "aws_instance" "workstation-ec2" {
  ami                    = var.workstation_ami_id  
  instance_type          = "t3.large"
  key_name               = var.ssh_key     # Replace with your key pair name
  vpc_security_group_ids = [aws_security_group.workstation-sg.id]
  subnet_id              = aws_subnet.public_subnet.id

  root_block_device {
    volume_size = 500
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = 500
    volume_type = "gp3"
  }

  user_data = <<-EOL
  #!/bin/bash 
  touch /opt/oh-no-mongo.txt

  #apt update
  #apt install openjdk-8-jdk --yes
  #wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
  #echo "deb https://pkg.jenkins.io/debian binary/" >> /etc/apt/sources.list
  #apt update
  #apt install -y jenkins
  #systemctl status jenkins
  #find /usr/lib/jvm/java-1.8* | head -n 3  
  EOL
}

resource "aws_eip" "workstation-eip" {
  domain    = "vpc"
  instance  = aws_instance.workstation-ec2.id

  tags = {
    Name = "workstation-eip"
  }
}

output "elastic_ip" {
  value = aws_eip.workstation-eip.public_ip
}
