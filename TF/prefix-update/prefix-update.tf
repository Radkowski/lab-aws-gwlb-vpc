variable "DEPLOYMENTPREFIX" {}
variable "AZ-NAME" {}
variable "SUBNETS-OUTPUT" {}


resource "aws_ec2_managed_prefix_list" "pub-prefix-list" {
  name           = join("-", [var.DEPLOYMENTPREFIX, "Public", regex("[1-9][a-j]$", var.AZ-NAME)])
  address_family = "IPv4"
  max_entries    = 5
  entry {
    cidr        = var.SUBNETS-OUTPUT.public-cidr
    description = "Public"
  }
}


resource "aws_ec2_managed_prefix_list" "priv-prefix-list" {
  name           = join("-", [var.DEPLOYMENTPREFIX, "Private", regex("[1-9][a-j]$", var.AZ-NAME)])
  address_family = "IPv4"
  max_entries    = 5
  entry {
    cidr        = var.SUBNETS-OUTPUT.private-cidr
    description = "Private"
  }
}



output "PREFIX-LISTS" {
  value = {
    (var.AZ-NAME) : {
      "Public" : aws_ec2_managed_prefix_list.pub-prefix-list.id
      "Private" : aws_ec2_managed_prefix_list.priv-prefix-list.id
    }
  }
}