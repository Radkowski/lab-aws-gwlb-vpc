locals {
  user_data        = fileexists("./config.yaml") ? yamldecode(file("./config.yaml")) : jsondecode(file("./config.json"))
  REGION           = local.user_data.Parameters.Region
  DEPLOYMENTPREFIX = local.user_data.Parameters.DeploymentPrefix
  VPC-PARAMS       = local.user_data.Parameters.VPC-Params
  AUTHTAGS         = local.user_data.Parameters.AuthTags
  GWLBESERVICENAME = local.user_data.Parameters.GWLBEServiceName

  NAT-VPC-PARAMS = {
    "AZs" : local.VPC-PARAMS.AZs
    "PublicSubnetsPerAZ" : 1
    "PrivateSubnetsPerAZ" : 0
    "CIDR" : cidrsubnet(local.VPC-PARAMS.Connect-CIDR, 2, 0)
    "SubnetMask" : "/28"
  }

  PRIV-GWLB-VPC-PARAMS = {
    "AZs" : local.VPC-PARAMS.AZs
    "PublicSubnetsPerAZ" : 0
    "PrivateSubnetsPerAZ" : 1
    "CIDR" : cidrsubnet(local.VPC-PARAMS.Connect-CIDR, 2, 1)
    "SubnetMask" : "/28"
  }

  PUB-GWLB-VPC-PARAMS = {
    "AZs" : local.VPC-PARAMS.AZs
    "PublicSubnetsPerAZ" : 0
    "PrivateSubnetsPerAZ" : 1
    "CIDR" : cidrsubnet(local.VPC-PARAMS.Connect-CIDR, 2, 2)
    "SubnetMask" : "/28"
  }

  DEPLOYSUBNETS = {
    "private" : local.VPC-PARAMS.PrivateSubnetsPerAZ == 0 ? false : true
    "public" : local.VPC-PARAMS.PublicSubnetsPerAZ == 0 ? false : true
  }
}

