# Módulo: network

<!-- TODO: 1-2 frases do que este módulo provisiona (VPC/VNet, subnets, route tables). -->

## Inputs obrigatórios

<!-- TODO: listar as variables sem default de variables.tf, com 1 linha cada. -->

## Outputs

<!-- TODO: listar os outputs de outputs.tf que outros componentes consomem (§2 do checklist). -->

## Uso (via componente Terragrunt)

```hcl
# environments/<env>/network/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/network"
}

inputs = {
  environment = "dev"
  # TODO: demais inputs obrigatórios
}
```
