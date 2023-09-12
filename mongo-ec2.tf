provider "aws" {
  region = var.aws_region  
}

#
# connectivity to the workstation
#
resource "aws_security_group" "workstation-sg" {
  name        = "workstation-security-group"
  description = "Allow SSH, HTTP, and HTTPS inbound traffic"
  vpc_id      = module.vpc.vpc_id

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
  subnet_id              = module.vpc.public_subnets[0]
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


# cloud-init config for user-data script and backup script
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

