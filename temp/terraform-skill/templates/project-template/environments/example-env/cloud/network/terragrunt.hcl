# Componente: network — camada base, sem dependency.
include "root" {
  path = find_in_parent_folders()
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "../../../../modules/cloud/network"
}

inputs = {
  environment = local.env.environment
  # TODO: inputs reais do módulo network (cidr, nº de subnets, etc).
}
