variable "VPC-ID" {}
variable "GWLBESERVICENAME" {}
variable "DEPLOYMENTPREFIX" {}
variable "GWLBE-SUBNET" {}
variable "AZ-NAME" {}


resource "aws_vpc_endpoint" "gwlbendpoint" {
  service_name      = var.GWLBESERVICENAME
  subnet_ids        = [one(var.GWLBE-SUBNET)]
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id            = var.VPC-ID.id
  tags = {
    Name = join("-", [var.DEPLOYMENTPREFIX, regex("[1-9][a-j]$", var.AZ-NAME), "GWLBE"])
  }
}



output "GWLBE-OUTPUT" {
  value = {
    (var.AZ-NAME) : { "endpoint_id" : aws_vpc_endpoint.gwlbendpoint.id }
  }
}
