variable "NAT-SUBNETS" {}
variable "VPC-ID" {}
variable "IGW" {}
variable "DEPLOYMENTPREFIX" {}
variable "CLIENT-SUBNETS" {}
variable "PRIV-GWLBE" {}



resource "aws_route_table" "nat" {
  vpc_id = var.VPC-ID.id
  tags = {
    Name = join("-", [var.DEPLOYMENTPREFIX, "NAT", regex("[1-9][a-j]$", var.CLIENT-SUBNETS["AZ-name"]), "RTable"])
  }
}


resource "aws_route" "nat-routes" {
  route_table_id         = aws_route_table.nat.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.IGW.id
  depends_on             = [aws_route_table.nat]
}


resource "aws_route" "nat-routes-to-priv" {
  depends_on             = [aws_route_table.nat]
  count                  = length(var.CLIENT-SUBNETS["private-subnets-cidrs"])
  route_table_id         = aws_route_table.nat.id
  destination_cidr_block = var.CLIENT-SUBNETS["private-subnets-cidrs"][count.index]
  vpc_endpoint_id        = var.PRIV-GWLBE[var.CLIENT-SUBNETS["AZ-name"]]["endpoint_id"]
}


resource "aws_route_table_association" "associate-with-nat" {
  subnet_id      = one(var.NAT-SUBNETS["public-subnets"])
  route_table_id = aws_route_table.nat.id
}



output "NAT-SUB-ROUTING-OUTPUT" {
  value = {
    "test" : var.CLIENT-SUBNETS
  }
}

