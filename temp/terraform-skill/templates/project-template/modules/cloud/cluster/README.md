# Módulo: cluster

<!-- TODO: 1-2 frases do que este módulo provisiona (cluster gerenciado EKS/AKS/GKE). -->

## Inputs obrigatórios

<!-- TODO: listar as variables sem default de variables.tf, com 1 linha cada. -->
- `network_id` / `subnet_ids` — vêm do componente `network` via `dependency` (não passar à mão)

## Outputs

<!-- TODO: listar os outputs de outputs.tf que outros componentes consomem (§2 do checklist). -->
- `kube_host` / `kube_ca` / `kube_token` — consumidos pelo componente `workloads`

## Uso (via componente Terragrunt)

```hcl
# environments/<env>/cluster/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/cluster"
}

dependency "network" {
  config_path = "../network"
}

inputs = {
  environment = "dev"
  network_id  = dependency.network.outputs.network_id
  subnet_ids  = dependency.network.outputs.subnet_ids
  # TODO: demais inputs obrigatórios
}
```
