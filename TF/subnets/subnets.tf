variable "DEPLOYMENTPREFIX" {}
variable "VPC-PARAMS" {}
variable "VPC-ID" {}
variable "AZ-NAME" {}
variable "AZ-CIDR" {}


locals {
  public_usable_cidr    = var.VPC-PARAMS.PrivateSubnetsPerAZ == 0 ? var.AZ-CIDR : cidrsubnet(var.AZ-CIDR, 1, 0)
  private_usable_cidr   = var.VPC-PARAMS.PublicSubnetsPerAZ == 0 ? var.AZ-CIDR : cidrsubnet(var.AZ-CIDR, 1, 1)
  pub_cidrsubnet_param  = tonumber(regex("[1-9][0-9]$", var.VPC-PARAMS.SubnetMask) - regex("[1-9][0-9]$", local.public_usable_cidr))
  priv_cidrsubnet_param = tonumber(regex("[1-9][0-9]$", var.VPC-PARAMS.SubnetMask) - regex("[1-9][0-9]$", local.private_usable_cidr))
}


resource "aws_subnet" "Pub-Subnets" {
  count                           = var.VPC-PARAMS.PublicSubnetsPerAZ
  vpc_id                          = var.VPC-ID.id
  cidr_block                      = cidrsubnet(local.public_usable_cidr, local.pub_cidrsubnet_param, count.index)
  availability_zone               = var.AZ-NAME
  assign_ipv6_address_on_creation = false
  map_public_ip_on_launch         = true
  tags = {
    Name   = join("-", [var.DEPLOYMENTPREFIX, "Public", count.index, regex("[1-9][a-j]$", var.AZ-NAME)])
    Public = true
  }
}


resource "aws_subnet" "Priv-Subnets" {
  count                           = var.VPC-PARAMS.PrivateSubnetsPerAZ
  vpc_id                          = var.VPC-ID.id
  cidr_block                      = cidrsubnet(local.private_usable_cidr, local.priv_cidrsubnet_param, count.index)
  availability_zone               = var.AZ-NAME
  assign_ipv6_address_on_creation = false
  map_public_ip_on_launch         = false
  tags = {
    Name   = join("-", [var.DEPLOYMENTPREFIX, "Private", count.index, regex("[1-9][a-j]$", var.AZ-NAME)])
    Public = false
  }
}



output "SUBNETS-OUTPUT" {
  value = {
    "AZ-name" : var.AZ-NAME
    "base-cidr" : var.AZ-CIDR
    "public-subnets" : aws_subnet.Pub-Subnets[*].id
    "public-subnets-cidrs" : aws_subnet.Pub-Subnets[*].cidr_block
    "private-subnets" : aws_subnet.Priv-Subnets[*].id
    "private-subnets-cidrs" : aws_subnet.Priv-Subnets[*].cidr_block
    "public-cidr" : local.public_usable_cidr
    "private-cidr" : local.private_usable_cidr
    "pub_cidrsubnet_param " : local.pub_cidrsubnet_param
    "priv_cidrsubnet_param" : local.priv_cidrsubnet_param
  }
}