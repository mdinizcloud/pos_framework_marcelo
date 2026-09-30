# Ambiente: <nome> (dev | hml | prd)

## Componentes

| Ordem | Componente | Depende de | Bucket | State (key) |
|---|---|---|---|---|
| 1 | `cloud/network` | — | `<projeto>-tfstate-cloud` | `<projeto>/environments/<env>/cloud/network/terraform.tfstate` |
| 2 | `cloud/cluster` | cloud/network | `<projeto>-tfstate-cloud` | `<projeto>/environments/<env>/cloud/cluster/terraform.tfstate` |
| 3 | `cloud/workloads` | cloud/cluster | `<projeto>-tfstate-cloud` | `<projeto>/environments/<env>/cloud/workloads/terraform.tfstate` |

## Aplicar

```bash
terragrunt run --all apply --parallelism 1     # ordem 1→2→3 resolvida sozinha
terragrunt run --all destroy --parallelism 1   # ordem inversa
```

## Endpoints

<!-- TODO: preencher após o primeiro apply (app_url, ingress_ip, etc). -->
