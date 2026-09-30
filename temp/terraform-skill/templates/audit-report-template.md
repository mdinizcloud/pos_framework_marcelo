---
title: Auditoria Terraform — <nome-do-projeto>
audited_at: <data ISO>
audited_path: <caminho absoluto do projeto auditado>
---

# Auditoria Terraform — <nome-do-projeto>

## Resumo

- Itens verificados: <N>
- Conformes: <N>
- Não conformes: <N>
- Providers atrás da latest: <N>
- Findings de código legado/deprecated: <N>

## 1. Layout (Terraform + Terragrunt)

| Item | Status | Observação |
|---|---|---|
| `terragrunt.hcl` raiz (backend + provider gerados) | ✅/❌ | |
| Raiz sem `.tf` de root module (recurso só em `modules/`) | ✅/❌ | |
| Componente = `environments/<env>/<comp>/terragrunt.hcl` | ✅/❌ | |
| `README.md`+`CHANGELOG.md` na raiz e por ambiente | ✅/❌ | |
| `docs/` presente | ✅/❌ | |

## 2. Módulos

| Item | Status | Observação |
|---|---|---|
| Módulos em `modules/<nome>/` local | ✅/❌ | |
| Cada módulo com versions/main/variables/outputs/README.md | ✅/❌ | |
| `versions.tf` só com `required_providers` (sem `provider {}` block) | ✅/❌ | |
| Config acessória como resource dedicado (sem bloco aninhado legado) | ✅/❌ | |
| `output` expõe atributo específico, nunca o resource inteiro | ✅/❌ | |

## 3. Provider — versão, lock, legado

| Provider | Versão pinada | Latest (Registry API) | `~>`? | Status |
|---|---|---|---|---|
| <namespace/name> | <~> X.Y> | <X.Y.Z> | ✅/❌ | ✅ atualizado / ⚠️ atrás da latest |

| Item | Status | Observação |
|---|---|---|
| `.terraform.lock.hcl` commitado | ✅/❌ | |
| Sem resource/argumento deprecado | ✅/❌ | |
| `terraform validate` sem warning de deprecation | ✅/❌ | |

## 4. State (remoto + split)

| Item | Status | Observação |
|---|---|---|
| Backend remoto (não local) | ✅/❌ | |
| 1 state por componente (sem state central) | ✅/❌ | |
| Key = `<projeto>/environments/<env>/<comp>/terraform.tfstate` | ✅/❌ | |
| Lock ativo (DynamoDB/blob lease/nativo) | ✅/❌ | |
| `*.tfstate`/`.terraform/`/`.terragrunt-cache/` no `.gitignore` | ✅/❌ | |
| Sem cruzamento de resource address entre states de ambientes diferentes (`terraform state list` de cada env, comparado) | ✅/❌ | |
| Recurso globalmente único (key pair, log project, IAM role) nomeado com prefixo/sufixo de ambiente | ✅/❌ | |
| Recurso externo compartilhado (DNS zone, registry) referenciado via data source, não recriado por env | ✅/❌ | |

## 5. Ambientes & componentes

| Item | Status | Observação |
|---|---|---|
| Ambiente = diretório (não workspace) | ✅/❌ | |
| Só ambientes/componentes já criados (sem pré-criar) | ✅/❌ | |
| Ordem network→cluster→workloads + `dependency` explícita | ✅/❌ | |

## 6. Naming convention

| Item | Status | Observação |
|---|---|---|
| snake_case consistente | ✅/❌ | |
| Nome de resource não repete o tipo | ✅/❌ | |
| Boolean com enable_/is_/use_ | ✅/❌ | |
| description+type em toda variável | ✅/❌ | |
| description em toda output | ✅/❌ | |
| sensitive = true onde aplicável | ✅/❌ | |
| Meta-args (count/for_each topo; tags/lifecycle fim) | ✅/❌ | |

## 7. Validação

| Item | Status | Observação |
|---|---|---|
| `terraform fmt`/`terragrunt hcl fmt` limpos | ✅/❌ | |
| `terraform validate` por componente passa | ✅/❌ | |
| `scripts/check_generated.sh` sem finding | ✅/❌ | |

## Findings detalhados

<!-- Um item por não-conformidade, com arquivo:linha quando aplicável -->

- <arquivo>:<linha> — <descrição do problema> — <sugestão de fix>

## Recomendações priorizadas

1. <ação mais importante>
2. <próxima ação>
