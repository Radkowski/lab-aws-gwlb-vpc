module "PREPARATION" {
  source     = "./preparation"
  VPC-PARAMS = local.VPC-PARAMS
}


module "NAT-PREPARATION" {
  source     = "./preparation"
  VPC-PARAMS = local.NAT-VPC-PARAMS
}


module "PRIV-GWLBE-PREPARATION" {
  source     = "./preparation"
  VPC-PARAMS = local.PRIV-GWLB-VPC-PARAMS
}


module "PUB-GWLBE-PREPARATION" {
  source     = "./preparation"
  VPC-PARAMS = local.PUB-GWLB-VPC-PARAMS
}


module "VPC-CORE" {
  source           = "./vpc-core"
  DEPLOYMENTPREFIX = local.DEPLOYMENTPREFIX
  VPC-PARAMS       = local.VPC-PARAMS
  AUTHTAGS         = local.AUTHTAGS
}


module "INGRESS-GLOBAL-ROUTE-TABLE" {
  depends_on       = [module.VPC-CORE]
  source           = "./ingress-global-route-table"
  DEPLOYMENTPREFIX = local.DEPLOYMENTPREFIX
  VPC-ID           = module.VPC-CORE.VPC-ID
}


module "CLIENT-SUBNETS" {
  count            = local.VPC-PARAMS.AZs
  depends_on       = [module.VPC-CORE]
  source           = "./subnets"
  DEPLOYMENTPREFIX = join("-", [local.DEPLOYMENTPREFIX, "CLIENT"])
  VPC-ID           = module.VPC-CORE.VPC-ID
  VPC-PARAMS       = local.VPC-PARAMS
  AZ-NAME          = module.PREPARATION.PREP-OUTPUT.AZs-list[count.index]
  AZ-CIDR          = module.PREPARATION.PREP-OUTPUT.AZs-cidr[count.index]
}


module "NAT-SUBNETS" {
  count            = local.DEPLOYSUBNETS["private"] ? local.VPC-PARAMS.AZs : 0
  depends_on       = [module.VPC-CORE]
  source           = "./subnets"
  DEPLOYMENTPREFIX = join("-", [local.DEPLOYMENTPREFIX, "NAT"])
  VPC-ID           = module.VPC-CORE.VPC-ID
  VPC-PARAMS       = local.NAT-VPC-PARAMS
  AZ-NAME          = module.NAT-PREPARATION.PREP-OUTPUT.AZs-list[count.index]
  AZ-CIDR          = module.NAT-PREPARATION.PREP-OUTPUT.AZs-cidr[count.index]
}


module "PRIV-GWLBE-SUBNETS" {
  count            = local.DEPLOYSUBNETS["private"] ? local.VPC-PARAMS.AZs : 0
  depends_on       = [module.VPC-CORE]
  source           = "./subnets"
  DEPLOYMENTPREFIX = join("-", [local.DEPLOYMENTPREFIX, "PRIV-GWLBE"])
  VPC-ID           = module.VPC-CORE.VPC-ID
  VPC-PARAMS       = local.PRIV-GWLB-VPC-PARAMS
  AZ-NAME          = module.PRIV-GWLBE-PREPARATION.PREP-OUTPUT.AZs-list[count.index]
  AZ-CIDR          = module.PRIV-GWLBE-PREPARATION.PREP-OUTPUT.AZs-cidr[count.index]
}


module "PUB-GWLBE-SUBNETS" {
  count            = local.DEPLOYSUBNETS["public"] ? local.VPC-PARAMS.AZs : 0
  depends_on       = [module.VPC-CORE]
  source           = "./subnets"
  DEPLOYMENTPREFIX = join("-", [local.DEPLOYMENTPREFIX, "PUB-GWLBE"])
  VPC-ID           = module.VPC-CORE.VPC-ID
  VPC-PARAMS       = local.PUB-GWLB-VPC-PARAMS
  AZ-NAME          = module.PUB-GWLBE-PREPARATION.PREP-OUTPUT.AZs-list[count.index]
  AZ-CIDR          = module.PUB-GWLBE-PREPARATION.PREP-OUTPUT.AZs-cidr[count.index]
}


module "PREFIX-UPDATE" {
  count            = local.VPC-PARAMS.AZs
  depends_on       = [module.CLIENT-SUBNETS]
  source           = "./prefix-update"
  DEPLOYMENTPREFIX = local.DEPLOYMENTPREFIX
  SUBNETS-OUTPUT   = module.CLIENT-SUBNETS[count.index].SUBNETS-OUTPUT
  AZ-NAME          = module.PREPARATION.PREP-OUTPUT.AZs-list[count.index]
}


module "GATEWAYS" {
  count            = local.DEPLOYSUBNETS["private"] ? local.VPC-PARAMS.AZs : 0
  depends_on       = [module.PREFIX-UPDATE]
  source           = "./gateways"
  DEPLOYMENTPREFIX = local.DEPLOYMENTPREFIX
  AZ-NAME          = module.NAT-PREPARATION.PREP-OUTPUT.AZs-list[count.index]
  NATGW-SUBNET     = one(module.NAT-SUBNETS[count.index].SUBNETS-OUTPUT.public-subnets)
}


module "PRIV-GWLBE" {
  count            = local.DEPLOYSUBNETS["private"] ? local.VPC-PARAMS.AZs : 0
  depends_on       = [module.GATEWAYS]
  source           = "./gwlbe"
  VPC-ID           = module.VPC-CORE.VPC-ID
  GWLBESERVICENAME = local.GWLBESERVICENAME
  GWLBE-SUBNET     = module.PRIV-GWLBE-SUBNETS[count.index].SUBNETS-OUTPUT["private-subnets"]
  DEPLOYMENTPREFIX = join("-", [local.DEPLOYMENTPREFIX, "Priv"])
  AZ-NAME          = module.PRIV-GWLBE-SUBNETS[count.index].SUBNETS-OUTPUT["AZ-name"]
}


module "PUB-GWLBE" {
  count            = local.DEPLOYSUBNETS["public"] ? local.VPC-PARAMS.AZs : 0
  depends_on       = [module.GATEWAYS]
  source           = "./gwlbe"
  VPC-ID           = module.VPC-CORE.VPC-ID
  GWLBESERVICENAME = local.GWLBESERVICENAME
  GWLBE-SUBNET     = module.PUB-GWLBE-SUBNETS[count.index].SUBNETS-OUTPUT["private-subnets"]
  DEPLOYMENTPREFIX = join("-", [local.DEPLOYMENTPREFIX, "Pub"])
  AZ-NAME          = module.PUB-GWLBE-SUBNETS[count.index].SUBNETS-OUTPUT["AZ-name"]
}


module "INGRESS-ROUTING" {
  count          = local.VPC-PARAMS.AZs
  depends_on     = [module.PUB-GWLBE, module.INGRESS-GLOBAL-ROUTE-TABLE]
  source         = "./ingress-routing"
  CLIENT-SUBNETS = module.CLIENT-SUBNETS[count.index].SUBNETS-OUTPUT
  VPC-ID         = module.VPC-CORE.VPC-ID
  IGW            = module.VPC-CORE.IGW
  PRIV-GWLBE     = local.DEPLOYSUBNETS["private"] ? [for y in module.PRIV-GWLBE : y.GWLBE-OUTPUT][count.index] : null
  PUB-GWLBE      = local.DEPLOYSUBNETS["public"] ? [for x in module.PUB-GWLBE : x.GWLBE-OUTPUT][count.index] : null
  EGRT           = module.INGRESS-GLOBAL-ROUTE-TABLE.EGRT
}


module "CLIENT-SUBNETS-ROUTING" {
  count            = local.VPC-PARAMS.AZs
  depends_on       = [module.PUB-GWLBE, module.PRIV-GWLBE]
  source           = "./client-subnets-routing"
  CLIENT-SUBNETS   = module.CLIENT-SUBNETS[count.index].SUBNETS-OUTPUT
  VPC-ID           = module.VPC-CORE.VPC-ID
  PRIV-GWLBE       = local.DEPLOYSUBNETS["private"] ? [for y in module.PRIV-GWLBE : y.GWLBE-OUTPUT][count.index] : null
  PUB-GWLBE        = local.DEPLOYSUBNETS["public"] ? [for x in module.PUB-GWLBE : x.GWLBE-OUTPUT][count.index] : null
  DEPLOYMENTPREFIX = local.DEPLOYMENTPREFIX
}


module "NAT-SUBNETS-ROUTING" {
  count            = local.DEPLOYSUBNETS["private"] ? local.VPC-PARAMS.AZs : 0
  depends_on       = [module.GATEWAYS]
  source           = "./nat-subnets-routing"
  VPC-ID           = module.VPC-CORE.VPC-ID
  IGW              = module.VPC-CORE.IGW
  DEPLOYMENTPREFIX = local.DEPLOYMENTPREFIX
  NAT-SUBNETS      = module.NAT-SUBNETS[count.index].SUBNETS-OUTPUT
  CLIENT-SUBNETS   = module.CLIENT-SUBNETS[count.index].SUBNETS-OUTPUT
  PRIV-GWLBE       = [for y in module.PRIV-GWLBE : y.GWLBE-OUTPUT][count.index]
}


module "PRIV-GWLBE-ROUTING" {
  count            = local.DEPLOYSUBNETS["private"] ? local.VPC-PARAMS.AZs : 0
  depends_on       = [module.PRIV-GWLBE]
  source           = "./priv-gwlbe-routing"
  VPC-ID           = module.VPC-CORE.VPC-ID
  DEPLOYMENTPREFIX = local.DEPLOYMENTPREFIX
  PRIV-GWLBE       = module.PRIV-GWLBE-SUBNETS[count.index].SUBNETS-OUTPUT
  GATEWAYS         = module.GATEWAYS[count.index].NATGW-OUTPUT
  AZ-NAME          = module.PRIV-GWLBE-SUBNETS[count.index].SUBNETS-OUTPUT["AZ-name"]
}


module "PUB-GWLBE-ROUTING" {
  count            = local.DEPLOYSUBNETS["public"] ? local.VPC-PARAMS.AZs : 0
  depends_on       = [module.PUB-GWLBE]
  source           = "./pub-gwlbe-routing"
  VPC-ID           = module.VPC-CORE.VPC-ID
  DEPLOYMENTPREFIX = local.DEPLOYMENTPREFIX
  PUB-GWLBE        = module.PUB-GWLBE-SUBNETS[count.index].SUBNETS-OUTPUT
  IGW              = module.VPC-CORE.IGW
  AZ-NAME          = module.PUB-GWLBE-SUBNETS[count.index].SUBNETS-OUTPUT["AZ-name"]
}



# output "CLIENT-PREP-OUTPUT" {
#   value = module.PREPARATION.PREP-OUTPUT
# }

# output "NAT-PREP-OUTPUT" {
#   value = module.NAT-PREPARATION.PREP-OUTPUT
# }

# output "PRIV-GWLBE-PREP-OUTPUT" {
#   value = module.PRIV-GWLBE-PREPARATION.PREP-OUTPUT
# }

# output "PUB-GWLBE-PREP-OUTPUT" {
#   value = module.PUB-GWLBE-PREPARATION.PREP-OUTPUT
# }

# output "VPC-CORE" {
#   value = module.VPC-CORE.VPC-ID
# }

# output "CLIENT-SUBNETS-OUTPUT" {
#   value = module.CLIENT-SUBNETS[*].SUBNETS-OUTPUT
# }

# output "NAT-SUBNETS-OUTPUT" {
#   value = module.NAT-SUBNETS[*].SUBNETS-OUTPUT
# }

# output "PRIV-GWLBE-SUBNETS-OUTPUT" {
#   value = module.PRIV-GWLBE-SUBNETS[*].SUBNETS-OUTPUT
# }

# output "PUB-GWLBE-SUBNETS-OUTPUT" {
#   value = module.PUB-GWLBE-SUBNETS[*].SUBNETS-OUTPUT
# }

# output "PREFIXES" {
#   value = module.PREFIX-UPDATE[*].PREFIX-LISTS
# }

# output "NATGW-OUTPUT" {
#   value = module.GATEWAYS[*].NATGW-OUTPUT
# }

# output "PRIV-GWLBE-OUTPUT" {
#   value = [for y in module.PRIV-GWLBE : y.GWLBE-OUTPUT]
# }


# output "PUB-GWLBE-OUTPUT" {
#   value = module.PUB-GWLBE[*].GWLBE-OUTPUT
# }

# output "CL-SUB-ROUTING-OUTPUT" {
#   value = module.CLIENT-SUBNETS-ROUTING[*].CL-SUB-ROUTING-OUTPUT
# }


# output "NAT-SUB-ROUTING-OUTPUT" {
#   value = module.NAT-SUBNETS-ROUTING[*].NAT-SUB-ROUTING-OUTPUT
# }

# output "PRIV-GWLBE-ROUTING-OUTPUT" {
#   value = module.PRIV-GWLBE-ROUTING[*].PRIV-GWLBE-ROUTING-OUTPUT
# }

# output "PUB-GWLBE-ROUTING-OUTPUT" {
#   value = module.PUB-GWLBE-ROUTING[*].PUB-GWLBE-ROUTING-OUTPUT
# }