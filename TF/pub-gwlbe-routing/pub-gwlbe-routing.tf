variable "VPC-ID" {}
variable "DEPLOYMENTPREFIX" {}
variable "PUB-GWLBE" {}
variable "AZ-NAME" {}
variable "IGW" {}



resource "aws_route_table" "pub-gwlbe" {
  vpc_id = var.VPC-ID.id
  tags = {
    Name = join("-", [var.DEPLOYMENTPREFIX, "PUB-GWLBE", regex("[1-9][a-j]$", var.AZ-NAME), "RTable"])
  }
}


resource "aws_route" "pub-glwbe-routes" {
  route_table_id         = aws_route_table.pub-gwlbe.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.IGW.id
  depends_on             = [aws_route_table.pub-gwlbe]
}


resource "aws_route_table_association" "associate-with-pub-gwlbe" {
  subnet_id      = one(var.PUB-GWLBE["private-subnets"])
  route_table_id = aws_route_table.pub-gwlbe.id
}



output "PUB-GWLBE-ROUTING-OUTPUT" {
  value = {
    "cli-sub" : var.PUB-GWLBE
    "AZ" : var.AZ-NAME
    "RTS" : aws_route_table.pub-gwlbe
  }
}
