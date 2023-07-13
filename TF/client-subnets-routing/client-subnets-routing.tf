variable "CLIENT-SUBNETS" {}
variable "VPC-ID" {}
variable "PRIV-GWLBE" {}
variable "PUB-GWLBE" {}
variable "DEPLOYMENTPREFIX" {}



resource "aws_route_table" "private" {
  count  = (length(var.CLIENT-SUBNETS["private-subnets"]) != 0 ? 1 : 0)
  vpc_id = var.VPC-ID.id
  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = var.PRIV-GWLBE[var.CLIENT-SUBNETS["AZ-name"]]["endpoint_id"]
  }
  tags = {
    Name = join("-", [var.DEPLOYMENTPREFIX, "Private", regex("[1-9][a-j]$", var.CLIENT-SUBNETS["AZ-name"]), "RTable"])
  }
}


resource "aws_route_table_association" "associate-with-private" {
  count          = length(var.CLIENT-SUBNETS["private-subnets"])
  subnet_id      = var.CLIENT-SUBNETS["private-subnets"][count.index]
  route_table_id = one(aws_route_table.private).id
}


resource "aws_route_table" "public" {
  count  = (length(var.CLIENT-SUBNETS["public-subnets"]) != 0 ? 1 : 0)
  vpc_id = var.VPC-ID.id
  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = var.PUB-GWLBE[var.CLIENT-SUBNETS["AZ-name"]]["endpoint_id"]
  }
  tags = {
    Name = join("-", [var.DEPLOYMENTPREFIX, "Public", regex("[1-9][a-j]$", var.CLIENT-SUBNETS["AZ-name"]), "RTable"])
  }
}


resource "aws_route_table_association" "associate-with-public" {
  count          = length(var.CLIENT-SUBNETS["public-subnets"])
  subnet_id      = var.CLIENT-SUBNETS["public-subnets"][count.index]
  route_table_id = one(aws_route_table.public).id
}



output "CL-SUB-ROUTING-OUTPUT" {
  value = {
    "priv-association" : {
      "route_table_id" = can(one(aws_route_table.private).id) ? one(aws_route_table.private).id : null
      "subnet_id"      = var.CLIENT-SUBNETS["private-subnets"]
    }
    "pub-association" : {
      "route_table_id" = can(one(aws_route_table.public).id) ? one(aws_route_table.public).id : null
      "subnet_id"      = var.CLIENT-SUBNETS["public-subnets"]
    }
  }
}
