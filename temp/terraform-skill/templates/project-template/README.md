# <nome-do-projeto>

Infra como código em **Terraform + Terragrunt**, state remoto **dividido por componente**
(blast radius pequeno). Um state por componente por ambiente.

## Layout

```
.
├── terragrunt.hcl              # backend + provider definidos 1x (herdado por todos)
├── modules/                    # Terraform puro (sem backend/provider block)
│   └── cloud/                  # categoria = só path, NUNCA tem main.tf/module{} próprio
│       ├── network/  cluster/  workloads/   # cada um é módulo-folha independente
├── environments/
│   ├── <env>/
│   │   ├── env.hcl             # vars comuns do ambiente
│   │   ├── README.md  CHANGELOG.md
│   │   └── cloud/
│   │       ├── network/terragrunt.hcl
│   │       ├── cluster/terragrunt.hcl      # dependency(network)
│   │       └── workloads/terragrunt.hcl    # dependency(cluster)  + providers kubernetes/helm
├── scripts/bootstrap-state-backend.sh  # cria 1 bucket por categoria (1x cada, antes de tudo)
├── docs/                       # arquitetura, runbook, exemplos de backend
├── README.md  CHANGELOG.md
└── .gitignore
```

Categoria (`cloud`, `observabilidade`, `seguranca`, `apps`, ...) é sempre um nível a mais em
`modules/` **e** em `environments/<env>/` — nunca só de um lado. Nasce sob demanda, não é enum
fixo. Cada componente-folha (`network`, `cluster`, `workloads`, ...) é módulo Terraform
independente — nenhum módulo chama outro módulo local (`source = "./..."`) dentro de `modules/`.

State: **1 bucket por categoria** (não 1 único pro projeto, não 1 por componente-folha), key
derivada do path completo dentro dele:
`<bucket-da-categoria>/<projeto>/environments/<env>/<categoria>/<componente>/terraform.tfstate`

Nome do bucket: `<projeto>-tfstate-<categoria>` (AWS/GCP) ou `<projeto>tfstate<categoria>`
sem hífen (Azure storage account não aceita hífen).

## Pré-requisitos

- Terraform (ou OpenTofu) `>= 1.9`
- [Terragrunt](https://terragrunt.gruntwork.io) (binário à parte)
- Credencial da cloud exportada no shell (`az login` / `aws configure` / `gcloud auth`)

## Bootstrap do bucket de state (1 vez, antes de tudo)

O bucket não pode viver no state que ele guarda (chicken-egg). Criar à parte:

```bash
./scripts/bootstrap-state-backend.sh <cloud> <bucket-da-categoria> <region>
# 1 vez por categoria:
./scripts/bootstrap-state-backend.sh aws acme-tfstate-cloud us-east-1
```

Depois preencher `project`/`state_bucket`/`state_region` no `terragrunt.hcl` da raiz (ou por
categoria, se o `generate "backend"` variar o bucket conforme o path — ver `docs/backend-examples/`).

## Aplicar

```bash
cd environments/<env>

# TUDO na ordem certa (network → cluster → workloads), 1 comando:
# NUNCA sem --parallelism 1 (paralelismo default estoura rate limit/state lock)
terragrunt run --all apply --parallelism 1

# só 1 componente:
cd cloud/cluster && terragrunt apply
```

A ordem é descoberta sozinha pelos blocos `dependency` — não precisa lembrar.

## Destruir (ordem inversa automática)

```bash
cd environments/<env>
terragrunt run --all destroy --parallelism 1
```

## Adicionar ambiente

Copiar `environments/<env>/` → `environments/<novo>/`, ajustar `env.hcl` + inputs.
Nunca pré-criar ambiente que ninguém pediu.

## Adicionar componente

1. Criar `modules/<categoria>/<novo>/` (Terraform puro) — categoria existente ou nova.
2. Criar `environments/<env>/<categoria>/<novo>/terragrunt.hcl` com `source` + `dependency` do
   que precisa (path cruzando categoria: `../../<outra-categoria>/<componente>`).
3. `terragrunt run --all apply --parallelism 1` já inclui ele na ordem.

## Versão de provider — sempre a última, sem legado

- Constraint `~> X.Y` da última versão descoberta na geração (Terraform Registry API).
- `.terraform.lock.hcl` **commitado** trava o patch exato (reprodutível).
- Zero resource/argumento deprecado. Config acessória = resource dedicado, nunca bloco aninhado legado.

## State — nunca commitar

`.gitignore` cobre `*.tfstate*`, `.terraform/`, `.terragrunt-cache/`. State guarda **segredo em
texto plano** — só vive no bucket cifrado. O `.terraform.lock.hcl`, ao contrário, **é** commitado.

## Documentação

- `docs/` — arquitetura, runbook, exemplos de backend, relatórios de auditoria.
- `CHANGELOG.md` (raiz) — mudança de código/estrutura do projeto.
- `environments/<env>/CHANGELOG.md` — mudança operacional daquele ambiente.
