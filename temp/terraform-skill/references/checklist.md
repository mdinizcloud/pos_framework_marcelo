# Checklist de Padrões Terraform + Terragrunt

Fonte única de verdade usada tanto no modo **criar** (aplicar desde o início, a partir do template)
quanto no modo **auditoria** (checar contra isso). Não duplicar essas regras em
outro lugar — se o checklist mudar, muda só aqui.

Modelo do workspace: **Terraform + Terragrunt**, state remoto **dividido por componente**
(um state por componente por ambiente). Sem state central monolítico, sem backend local.

## 1. Layout de arquivos

Segregado por **categoria** sempre — não é modo opcional nem condicionado a tamanho de
projeto (não existe mais gate por quantidade de componente). Categoria é um nível de path a
mais em `modules/` **e** em `environments/<env>/`, espelhado nos dois lados; nasce sob demanda
(`cloud`, `observabilidade`, `seguranca`, `apps`, ... não é enum fixo), nunca pré-criada vazia.

```
<projeto>/
├── terragrunt.hcl              # backend remoto (bucket por categoria) + provider, herdado por todos
├── .gitignore                  # *.tfstate*  .terraform/  .terragrunt-cache/  (lock NÃO ignorado)
├── README.md  CHANGELOG.md
├── scripts/
│   └── bootstrap-state-backend.sh   # cria 1 bucket + lock por CATEGORIA (1x cada, antes de tudo)
├── docs/                       # architecture.md, runbook.md, backend-examples/, auditorias
├── modules/                    # Terraform PURO (sem backend, sem provider block)
│   ├── cloud/                  # categoria = só path, NUNCA tem main.tf/module{} próprio
│   │   ├── network/  aks/  foundation/     # cada um: versions.tf main.tf variables.tf outputs.tf
│   ├── observabilidade/
│   │   ├── prometheus/  grafana/
│   └── apps/
│       └── <nome-do-app>/
└── environments/
    └── <env>/                  # dev | hml | prd — só o que já foi criado
        ├── env.hcl             # vars comuns do ambiente
        ├── README.md  CHANGELOG.md
        ├── cloud/
        │   ├── network/terragrunt.hcl
        │   ├── aks/terragrunt.hcl              # dependency(network)
        │   └── foundation/terragrunt.hcl       # dependency(aks)
        ├── observabilidade/
        │   ├── prometheus/terragrunt.hcl       # dependency("../../cloud/aks")
        │   └── grafana/terragrunt.hcl
        └── apps/
            └── <nome-do-app>/terragrunt.hcl    # dependency("../../cloud/aks")
```

**Checar:**
- [ ] `terragrunt.hcl` na raiz define backend remoto (via `remote_state`) + `generate "provider"`
- [ ] Raiz NÃO tem `.tf` de root module (todo código de recurso vive em `modules/<categoria>/<nome>/`)
- [ ] Cada componente é um dir em `environments/<env>/<categoria>/<componente>/` com só
      `terragrunt.hcl` (o `.tf` real está em `modules/<categoria>/<componente>/`, referenciado
      por `terraform { source = ... }`)
- [ ] Categoria existe **igual** nos dois lados (`modules/` e `environments/<env>/`) — nunca só
      de um lado
- [ ] `README.md` + `CHANGELOG.md` na raiz E em cada `environments/<env>/`
- [ ] `docs/` existe na raiz

## 2. Módulos (`modules/<categoria>/<nome>/`)

```
modules/<categoria>/<nome>/
├── versions.tf     — required_providers só (SEM provider {} block — config vem do componente)
├── main.tf         — resources do domínio; nome de resource não repete o tipo; count/for_each
│                      no topo do bloco, tags/lifecycle/depends_on no fim; config acessória =
│                      resource dedicado, nunca bloco aninhado legado
├── variables.tf    — description + type em toda variável; sensitive = true em segredo;
│                      boolean sempre enable_/is_/use_; sem prefixo de tipo no nome
├── outputs.tf      — description em todo output; nunca o resource inteiro — só o
│                      atributo específico que o componente consumidor precisa
└── README.md       — o que o módulo provisiona, inputs obrigatórios, exemplo mínimo de
                       `terragrunt.hcl` que o consome
```

- [ ] Módulo reutilizável vive em `modules/<categoria>/<nome>/` local ao projeto (reuso cross-repo só quando repetir de fato)
- [ ] Categoria (`modules/<categoria>/`) é **só path** — nunca tem `main.tf`/`variables.tf`/
      `module{}` próprio na raiz da categoria; quem carrega conteúdo é sempre a subpasta `<nome>/`
- [ ] Todo módulo tem `versions.tf` + `main.tf` + `variables.tf` + `outputs.tf` + `README.md`
- [ ] `versions.tf` do módulo declara **só** `required_providers` — **nunca** `provider {}` block
      (config de provider vive no `terragrunt.hcl`, gerada pelo Terragrunt)
- [ ] Módulo não referencia estado/recurso fora do que recebe via variável (sem acoplamento implícito)
- [ ] Config acessória = resource **dedicado**, nunca bloco aninhado legado quando o provider oferece resource próprio
- [ ] **Zero child module** — nenhum `.tf` dentro de `modules/**` declara `module "..." { source =
      "./..." }`/`"../..."` chamando outro módulo local. Árvore sempre **flat, 1 nível**
      (recomendação da HashiCorp: manter a árvore de módulos o mais plana possível). Composição
      entre componentes só acontece via `dependency` do Terragrunt no componente
      (`environments/<env>/<categoria>/<comp>/terragrunt.hcl`), nunca com `module{}` dentro de
      `modules/`. Checagem automática: `scripts/check_naming.py` (`check_child_module_calls_module`)
      já varre `modules/**` recursivamente e falha o gate se achar
- [ ] `for_each` para recursos **não-idênticos**/com chave própria; `count` só para recursos
      verdadeiramente idênticos onde ordem não importa — `count` com item removido do meio desloca
      índice e causa destroy/recreate em cascata

## 3. Provider — sempre a última versão, `~>`, lock commitado, sem legado

- [ ] `required_providers` usa `version = "~> X.Y"` da **última** minor descoberta na geração
- [ ] Número da versão vem da **Terraform Registry API** (`scripts/get_latest_provider_version.sh <namespace> <name>`),
      nunca de memória/treino nem do context7
- [ ] `.terraform.lock.hcl` **commitado** (trava o patch exato — reprodutibilidade). Nunca ignorado no `.gitignore`
- [ ] **Context7 consultado via MCP** antes de gerar o código do módulo, só para **sintaxe/uso** (resource shape, breaking changes)
- [ ] **Guardrail de defasagem:** se a versão indexada no Context7 for menor que a latest da Registry API,
      não copiar a sintaxe cega — preferir a doc da versão latest e confiar no `terraform validate`
- [ ] **Fallback:** se o MCP do Context7 estiver indisponível/sem `context7.api_key`, não bloquear a geração —
      seguir com versão da Registry + `terraform validate`, registrando "Context7 não consultado (MCP indisponível)"
- [ ] **Zero legado:** nenhum resource/argumento deprecado; nenhum exemplo copiado de doc de major antigo
- [ ] Em auditoria: se a versão pinada for menor que a latest da Registry (inclui major novo), reportar como finding
      "atrás da latest" (informativo, não bloqueante)

## 4. State — remoto, 1 por componente-folha, 1 bucket por categoria

- [ ] Backend **remoto** num bucket de state (S3/GCS/azurerm), nunca local
- [ ] **1 state por componente-folha por ambiente** — nunca por categoria, nunca central. Key
      derivada do path completo: `<projeto>/environments/<env>/<categoria>/<componente>/terraform.tfstate`
      (em Terragrunt, `path_relative_to_include()` já gera isso sozinho, não escrever key à mão)
- [ ] **1 bucket por categoria** — nem 1 único pro projeto todo (perde isolamento entre
      categoria), nem 1 por componente-folha (multiplica sem parar a cada componente novo).
      Nome: `<projeto>-tfstate-<categoria>` (AWS/GCP) ou `<projeto>tfstate<categoria>` sem
      hífen (Azure storage account não aceita hífen). `<env>` mora na key, não no nome do bucket
- [ ] Bucket de state **bootstrapado à parte** (`scripts/bootstrap-state-backend.sh`) — chicken-egg,
      o bucket não vive no state que ele guarda. Rodar 1 vez **por categoria**, não 1 vez só
- [ ] Bucket com encryption-at-rest + versionamento (backup) + acesso restrito (nunca público)
- [ ] Lock ativo (DynamoDB no S3, tabela `<projeto>-tflock-<categoria>`; blob lease no azurerm;
      nativo no gcs)
- [ ] `*.tfstate`, `*.tfstate.*`, `.terraform/`, `.terragrunt-cache/` cobertos por `.gitignore`
- [ ] `.terraform.lock.hcl` **NÃO** ignorado (é commitado — ver §3)

## 5. Ambientes & componentes (`environments/`)

```
environments/<env>/<categoria>/<componente>/
└── terragrunt.hcl  — include "root" (herda backend+provider do terragrunt.hcl raiz)
                       + terraform { source = "../../../../modules/<categoria>/<nome>" }
                       + dependency "<de-quem-depende>" { config_path = "../<componente>" }
                         (mesma categoria) ou "../../<outra-categoria>/<componente>" (cruzando
                         categoria) — nunca na direção contrária, componente-base não conhece
                         o dependente
                       + inputs = { ... }  (nunca segredo literal — ver §6)
```

- [ ] Ambiente = diretório, nunca Terraform workspace (`terraform workspace new`)
- [ ] Só existem os diretórios de ambiente já criados — nunca pré-criar `dev/`+`hml/`+`prd/` de uma vez
- [ ] Componentes núcleo, na ordem: `cloud/network` → `cloud/cluster` → `cloud/workloads`.
      Opcionais (`observabilidade/*`, `seguranca/*`, `apps/<nome-do-app>`, `data`, `dns`,
      `identity`) só quando o projeto pedir — nunca pré-criar categoria ou componente vazio
- [ ] Recurso externo **compartilhado** entre ambientes (zona DNS, container registry) é
      **referenciado** via `data source`, nunca recriado/possuído por mais de 1 ambiente — evitar
      2 ambientes criando o mesmo record/registry (colisão silenciosa: 2 IDs independentes pro
      mesmo nome → round-robin de tráfego pro ambiente errado). Se precisar de registro por
      ambiente, isolar por subdomínio (`staging.dominio`) ou zona própria, nunca o mesmo nome
      raiz em dois ambientes
- [ ] Dependência entre componentes explícita via `dependency` do Terragrunt (substitui `terraform_remote_state`)
- [ ] **Gate de concepção** (perguntar ao criar): os ambientes divergem em **estrutura**
      (componente/recurso que existe num env e não noutro) ou só em **tamanho/valores**?
    - só tamanho/valores → mesmo conjunto de componentes em todos os envs; diferença via `inputs`/tfvars
    - estrutura diverge → o env pode ter conjunto de componentes próprio (dir a mais/menos)
- [ ] Ordem de apply documentada no `README.md` do ambiente; `terragrunt run-all apply` resolve pela dependência

## 6. Naming convention (variáveis, outputs, recursos)

- [ ] `snake_case` em tudo: variável, output, resource local name, módulo, componente
- [ ] Nome descritivo, sem prefixo de tipo (`instance_type`, nunca `str_instance_type`)
- [ ] Nome de resource local não repete o tipo (`resource "aws_vpc" "this"`, nunca `"aws_vpc"`)
- [ ] Variável booleana prefixada `enable_`, `is_` ou `use_`
- [ ] Toda variável declara `description` e `type`; `default` só quando fizer sentido
- [ ] Variável/output sensível (senha, token, connection string, CA) marcada `sensitive = true`
- [ ] Toda `output` declara `description`
- [ ] Ordem dentro do bloco de variável/output: `description` → `type` → `default` → `sensitive` → `validation`
- [ ] Meta-argumentos no resource: `count`/`for_each` no topo do bloco; `tags`, `lifecycle`, `depends_on` no fim
- [ ] Recurso com escopo de unicidade **região/conta** (não só o state) — ex: key pair SSH, log
      project, nome de IAM role/policy — leva `var.environment` como prefixo/sufixo no nome
      (`"${var.environment}-deploy"`). Isolamento por state (Terragrunt) **não** evita colisão
      desses recursos entre ambientes; só nomear por ambiente evita
- [ ] Valor sensível **nunca literal** em `inputs = {}` do `terragrunt.hcl` (é arquivo commitado) nem
      em `terraform.tfvars` versionado — vem de `TF_VAR_*`/secret manager/env. `scripts/check_naming.py`
      detecta literal com nome sugestivo de segredo (`password`, `token`, `secret`, `credential`, `api_key`)
      dentro de `inputs {}`
- [ ] `output` nunca expõe o **resource inteiro** (`value = azurerm_storage_account.this`) — só o
      atributo específico que o componente consumidor precisa (`value = azurerm_storage_account.this.id`).
      `scripts/check_naming.py` detecta o caso simples (`value` = `tipo.nome` sem atributo)
- [ ] `validation { condition = ... }` em variável **onde fizer sentido** (formato de CIDR, enum de
      ambiente, faixa numérica) — não é obrigatório em toda variável, é julgamento; não automatizado,
      fica pra revisão humana/auditoria
- [ ] Variável com **3+ settings relacionados** agrupa em `type = object({...})` em vez de 3+ variáveis
      soltas (ex: `variable "database" { type = object({ engine = string, size_gb = number }) }`)
      em vez de `db_engine`/`db_size_gb` separadas — julgamento, não automatizado

## 7. Validação (roda após gerar o código E antes de todo apply futuro)

- [ ] `terraform fmt -check -recursive` e `terragrunt hcl fmt --check` passam
- [ ] `terraform validate` (via `terragrunt validate`) passa em cada componente, sem warning de deprecation
- [ ] `scripts/check_generated.sh` (na skill) roda ao fim da geração (gate determinístico) e no `pre-commit`
- [ ] A skill roda essa validação **em runtime** logo após gerar/alterar código, antes de declarar pronto
- [ ] O `terragrunt.hcl` raiz do projeto gerado tem `before_hook` de `validate` amarrado a
      `plan`/`apply` — o gate não pode depender só de a skill ter sido usada; um `terragrunt apply`
      manual, meses depois, sem a skill no caminho, ainda passa pela validação

## 8. O que essa skill NÃO cobre

- Conteúdo de `resource` blocks específicos (ex: como configurar um EKS/AKS/VNet) — só estrutura/forma
- Conteúdo de deploy de aplicação (values de Helm, manifests, Application do ArgoCD, pipeline CD) —
  a skill define a **fronteira** (componente `workloads`/bootstrap GitOps), o conteúdo é de outra skill
- Módulos de terceiros (Registry/AVM) — decisão de usar módulo interno primeiro
- Varredura de múltiplos projetos numa auditoria — audita 1 projeto por invocação
- **CI/CD de infra** (pipeline que roda `terragrunt plan`/`apply`, drift detection agendado) — o
  `before_hook` (§7) e `check_generated.sh` são o gate de validação; orquestrar isso em pipeline
  GitHub Actions é escopo da skill irmã `terraform-cicd` (`cloud/terraform/terraform-cicd/`)
- Security review de conteúdo de recurso (IAM policy, security group, encryption toggle) — o único
  check de segurança aqui é **onde** o segredo mora (§6: nunca literal commitado), não a postura de
  segurança do recurso provisionado
