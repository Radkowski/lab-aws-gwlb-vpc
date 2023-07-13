
variable "VPC-PARAMS" {}



data "aws_availability_zones" "available_AZs" {
  state = "available"
  lifecycle {
    postcondition {
      condition     = (length(self.names)) >= var.VPC-PARAMS.AZs
      error_message = format("Current region doesn't support requested number of availability zones")
    }
  }
}



locals {

  AZ-2-CIDR-mapping = try({
    "1" : [var.VPC-PARAMS.CIDR]
    "2" : cidrsubnets(var.VPC-PARAMS.CIDR, 1, 1)
    "3" : cidrsubnets(var.VPC-PARAMS.CIDR, 2, 2, 2)
    "4" : cidrsubnets(var.VPC-PARAMS.CIDR, 2, 2, 2, 2)
    "5" : cidrsubnets(var.VPC-PARAMS.CIDR, 3, 3, 3, 3, 3)
    "6" : cidrsubnets(var.VPC-PARAMS.CIDR, 3, 3, 3, 3, 3, 3)
    "7" : cidrsubnets(var.VPC-PARAMS.CIDR, 3, 3, 3, 3, 3, 3, 3)
    "8" : cidrsubnets(var.VPC-PARAMS.CIDR, 3, 3, 3, 3, 3, 3, 3, 3)
  })

  outputs = {
    "AZs-count" : length(data.aws_availability_zones.available_AZs.names)
    "AZs-list" : slice(data.aws_availability_zones.available_AZs.names, 0, var.VPC-PARAMS.AZs)
    "AZs-cidr" : local.AZ-2-CIDR-mapping[var.VPC-PARAMS.AZs]
  }
}



resource "null_resource" "verify_subnet_request" {
  triggers = {
    privsub = var.VPC-PARAMS.PrivateSubnetsPerAZ
    pubsub  = var.VPC-PARAMS.PublicSubnetsPerAZ
  }
  lifecycle {
    postcondition {
      condition     = !((var.VPC-PARAMS.PublicSubnetsPerAZ == 0) && (var.VPC-PARAMS.PrivateSubnetsPerAZ == 0))
      error_message = "VPC without any subnets is an interesting construct but not Today"
    }
  }
}


output "PREP-OUTPUT" {
  value = local.outputs
}
