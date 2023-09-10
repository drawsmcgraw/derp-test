variable "ssh_key" {
  type    = string
  default = "kronk"
}

variable "workstation_ami_id" {
  type    = string
  default = "ami-0001f433d458dcfce"  # Ubuntu 22.10 in us-east-2
}