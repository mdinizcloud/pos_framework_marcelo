# Módulo: workloads

<!-- TODO: 1-2 frases do que este módulo provisiona (namespaces, Helm releases, bootstrap GitOps). -->

Não substitui GitOps para deploy contínuo de aplicação — ver `docs/architecture.md` do projeto.

## Inputs obrigatórios

<!-- TODO: listar as variables sem default de variables.tf, com 1 linha cada. -->
- `kube_host` / `kube_ca` / `kube_token` — vêm do componente `cluster` via `dependency` (não passar à mão)

## Outputs

<!-- TODO: listar os outputs de outputs.tf que outros componentes/documentação consomem. -->

## Uso (via componente Terragrunt)

```hcl
# environments/<env>/workloads/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/workloads"
}

dependency "cluster" {
  config_path = "../cluster"
}

inputs = {
  environment = "dev"
  kube_host   = dependency.cluster.outputs.kube_host
  kube_ca     = dependency.cluster.outputs.kube_ca
  kube_token  = dependency.cluster.outputs.kube_token
  # TODO: demais inputs obrigatórios
}
```
