variable "VPC-ID" {}
variable "DEPLOYMENTPREFIX" {}



resource "aws_route_table" "ingress" {
  vpc_id = var.VPC-ID.id
  tags = {
    Name = join("-", [var.DEPLOYMENTPREFIX, "INGRESS-GLOBAL-RTable"])
  }
}



output "EGRT" {
  value = aws_route_table.ingress
}