variable "VPC-ID" {}
variable "DEPLOYMENTPREFIX" {}
variable "PRIV-GWLBE" {}
variable "GATEWAYS" {}
variable "AZ-NAME" {}



resource "aws_route_table" "priv-gwlbe" {
  vpc_id = var.VPC-ID.id
  tags = {
    Name = join("-", [var.DEPLOYMENTPREFIX, "PRIV-GWLBE", regex("[1-9][a-j]$", var.AZ-NAME), "RTable"])
  }
}


resource "aws_route" "priv-glwbe-routes" {
  route_table_id         = aws_route_table.priv-gwlbe.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.GATEWAYS[var.AZ-NAME]["natgw_id"]
  depends_on             = [aws_route_table.priv-gwlbe]
}


resource "aws_route_table_association" "associate-with-priv-gwlbe" {
  subnet_id      = one(var.PRIV-GWLBE["private-subnets"])
  route_table_id = aws_route_table.priv-gwlbe.id
}



output "PRIV-GWLBE-ROUTING-OUTPUT" {
  value = {
    "gateways" : var.GATEWAYS
    "cli-sub" : var.PRIV-GWLBE
    "AZ" : var.AZ-NAME
    "RTS" : aws_route_table.priv-gwlbe
  }
}

