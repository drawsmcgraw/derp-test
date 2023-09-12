variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "environment" {
  type    = string
  default = "derp"
}

variable "ssh_key" {
  type    = string
  default = "kronk"
}

variable "workstation_ami_id" {
  type    = string
  #default = "ami-0001f433d458dcfce"  # Ubuntu 22.10 in us-east-2
  default = "ami-04c27040eb48fd96f"  # Ubuntu 20.04 in us-west-2
}