# Componente: cluster — depende de network.
include "root" {
  path = find_in_parent_folders()
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "../../../../modules/cloud/cluster"
}

# Substitui terraform_remote_state — Terragrunt injeta a ordem de apply a partir disto.
dependency "network" {
  config_path = "../network"

  # Permite plan/validate isolado antes de o network existir.
  mock_outputs = {
    network_id = "network-mock"
    subnet_ids = ["subnet-mock-a", "subnet-mock-b"]
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

inputs = {
  environment = local.env.environment
  network_id  = dependency.network.outputs.network_id
  subnet_ids  = dependency.network.outputs.subnet_ids
  # TODO: inputs reais do cluster.
}
