# Runbook

## Ordem de apply

`network → cluster → workloads`. `terragrunt run --all apply --parallelism 1` resolve sozinho
pela dependência. Destroy: ordem inversa (`terragrunt run --all destroy --parallelism 1`).

**NUNCA rodar `terragrunt run --all` sem `--parallelism 1`** — sem essa flag,
componentes sem dependência entre si rodam em paralelo e podem estourar rate limit de API da cloud
ou disputar lock de state.

## Rotinas

| Ação | Comando |
|---|---|
| Bootstrap do bucket (1x) | `./scripts/bootstrap-state-backend.sh <cloud> <bucket> <region>` |
| Aplicar ambiente inteiro | `cd environments/<env> && terragrunt run --all apply --parallelism 1` |
| Aplicar 1 componente | `cd environments/<env>/<comp> && terragrunt apply` |
| Ver plan de tudo | `cd environments/<env> && terragrunt run --all plan --parallelism 1` |
| Destruir ambiente | `cd environments/<env> && terragrunt run --all destroy --parallelism 1` |
| Validar código gerado | `terragrunt hcl fmt --check && terraform fmt -check -recursive` |

## Troubleshooting

- **`terragrunt` erra em `dependency` antes de o componente-base existir** → usar `run --all`,
  que aplica na ordem; `mock_outputs` nos `terragrunt.hcl` permitem `plan`/`validate` isolado.
- **Provider desatualizado** → `scripts/get_latest_provider_version.sh` (na skill) e ajustar
  o `~>` no `versions.tf` do módulo; rodar `terraform init -upgrade` e commitar o lock atualizado.
- **State travado** → checar lock no bucket (DynamoDB/blob lease); só liberar após confirmar
  que nenhum apply está rodando.

<!-- TODO: runbooks específicos do projeto (incidentes, rollback por componente). -->
