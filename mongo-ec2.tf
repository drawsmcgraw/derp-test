provider "aws" {
  region = var.aws_region  
}

resource "aws_vpc" "workstation-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "workstation-vpc"
  }
}

#
# public subnet
#
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.workstation-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"  

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

#
# private subnet
#
resource "aws_subnet" "private_subnet_01" {
  vpc_id                  = aws_vpc.workstation-vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-west-2b"  

  tags = {
    Name = "eks-private-subnet-01"
  }
}

resource "aws_subnet" "private_subnet_02" {
  vpc_id                  = aws_vpc.workstation-vpc.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "us-west-2c"  

  tags = {
    Name = "eks-private-subnet-02"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.workstation-vpc.id
  tags = {
    Name        = "${var.environment}-private-route-table"
    Environment = "${var.environment}"
  }
}

resource "aws_eip" "nat_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.workstation-igw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)
  depends_on    = [aws_internet_gateway.workstation-igw]
  tags = {
    Name        = "nat"
    Environment = "${var.environment}"
  }
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_subnet_01_association" {
  subnet_id      = aws_subnet.private_subnet_01.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_subnet_02_association" {
  subnet_id      = aws_subnet.private_subnet_02.id
  route_table_id = aws_route_table.private.id
}

#
# connectivity to the workstation
#
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

  ingress {
    from_port   = 27017
    to_port     = 27017
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
  key_name               = var.ssh_key     
  vpc_security_group_ids = [aws_security_group.workstation-sg.id]
  subnet_id              = aws_subnet.public_subnet.id
  iam_instance_profile   = aws_iam_instance_profile.s3-write-profile.name  



  root_block_device {
    volume_size = 500
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = 500
    volume_type = "gp3"
  }

  user_data = data.cloudinit_config.mongo-files.rendered
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


# cloud-init config for user-data scrit and backup script
data "cloudinit_config" "mongo-files" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content = file("user-data.sh")
  }

  part {
    content_type = "text/cloud-config"
    filename     = "cloud.conf"
    content = yamlencode(
      {
        "write_files" : [
          {
            "path" : "/opt/backup-mongo.sh",
            "content" : file("backup-mongo.sh"),
          }
        ],
      }
    )
  }
}

