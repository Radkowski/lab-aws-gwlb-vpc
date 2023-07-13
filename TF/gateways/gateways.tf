variable "DEPLOYMENTPREFIX" {}
variable "NATGW-SUBNET" {}
variable "AZ-NAME" {}


resource "aws_eip" "natgw_ip" {
  tags = {
    Name = join("-", [var.DEPLOYMENTPREFIX, regex("[1-9][a-j]$", var.AZ-NAME), "NATGW-IP"])
  }
}


resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.natgw_ip.id
  subnet_id     = var.NATGW-SUBNET
  depends_on    = [aws_eip.natgw_ip]
  tags = {
    Name = join("-", [var.DEPLOYMENTPREFIX, regex("[1-9][a-j]$", var.AZ-NAME), "NATGW"])
  }
}



output "NATGW-OUTPUT" {
  value = {
    (var.AZ-NAME) : {
      "subnet_id" : var.NATGW-SUBNET
      "natgw_id" : aws_nat_gateway.natgw.id
    }
  }
}


