
variable "VPC-PARAMS" {}
variable "DEPLOYMENTPREFIX" {}
variable "AUTHTAGS" {}


resource "aws_vpc" "MainVPC" {
  cidr_block                       = var.VPC-PARAMS.CIDR
  instance_tenancy                 = "default"
  enable_dns_hostnames             = "true"
  assign_generated_ipv6_cidr_block = "false"
  tags = {
    Name = var.DEPLOYMENTPREFIX
  }
}


resource "aws_vpc_ipv4_cidr_block_association" "connect-cidr" {
  vpc_id     = aws_vpc.MainVPC.id
  cidr_block = var.VPC-PARAMS.Connect-CIDR
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.MainVPC.id
  tags   = merge(var.AUTHTAGS, { Name = join("", [var.DEPLOYMENTPREFIX, "-IGW"]) })
}



output "VPC-ID" {
  value = aws_vpc.MainVPC
}


output "IGW" {
  value = aws_internet_gateway.igw
}