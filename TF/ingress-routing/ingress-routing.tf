variable "VPC-ID" {}
variable "IGW" {}
variable "CLIENT-SUBNETS" {}
variable "PRIV-GWLBE" {}
variable "PUB-GWLBE" {}
variable "EGRT" {}


resource "aws_route" "ingress-routes-to-priv" {
  count                  = length(var.CLIENT-SUBNETS["private-subnets-cidrs"])
  route_table_id         = var.EGRT.id
  destination_cidr_block = var.CLIENT-SUBNETS["private-subnets-cidrs"][count.index]
  vpc_endpoint_id        = var.PRIV-GWLBE[var.CLIENT-SUBNETS["AZ-name"]]["endpoint_id"]
}


resource "aws_route" "ingress-routes-to-pub" {
  count                  = length(var.CLIENT-SUBNETS["public-subnets-cidrs"])
  route_table_id         = var.EGRT.id
  destination_cidr_block = var.CLIENT-SUBNETS["public-subnets-cidrs"][count.index]
  vpc_endpoint_id        = var.PUB-GWLBE[var.CLIENT-SUBNETS["AZ-name"]]["endpoint_id"]
}


resource "aws_route_table_association" "associate-with-igw" {
  gateway_id     = var.IGW.id
  route_table_id = var.EGRT.id
}

