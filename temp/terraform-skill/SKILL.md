---
name: terraform-skill
description: >-
  Usar essa skill ao criar um projeto Terraform novo do zero, ao adicionar um componente/módulo novo
  a um projeto Terraform já existente, ou ao auditar um projeto Terraform existente contra os padrões
  de organização/formatação desse workspace (Terraform + Terragrunt, state remoto dividido por
  componente, ambientes como diretório, provider sempre na última versão via ~> + lock file
  commitado, naming convention). Não cobre conteúdo de recurso específico (ex: como configurar um
  AKS) nem conteúdo de deploy de aplicação (Helm/ArgoCD) — só estrutura, layout e formatação do
  projeto. Dispara em pedidos como "cria um projeto Terraform novo pra X", "adiciona um componente/
  módulo de X nesse projeto terraform", "preciso de um novo componente terraform nesse projeto",
  "audita esse projeto Terraform", "essa estrutura Terraform tá no padrão?", "estrutura terraform",
  "configurar terraform", "montar terraform com terragrunt", "preparar infra com terraform",
  "iniciar projeto terraform", "projeto tf", ou qualquer variação que indique criação, extensão ou
  revisão de estrutura de projeto Terraform — mesmo sem usar esses termos exatos.
---

# Terraform Skill

## Visão geral

Padronizar organização e formatação de projetos **Terraform + Terragrunt** nesse workspace, em três
modos: **criar** (gerar projeto novo a partir do template), **adicionar componente** (estender projeto existente
com módulo/componente novo, sem recriar nem auditar) e **auditar** (revisar projeto existente,
read-only, e gerar relatório). Não gera conteúdo de `resource` block específico de provider nem
conteúdo de deploy de aplicação — só estrutura, layout de arquivo, módulos, componentes, ambientes
e naming convention.

Modelo do workspace: `modules/`/`environments/<env>/` sempre segregados por **categoria**
(`cloud`, `observabilidade`, `seguranca`, `apps`, ... — nasce sob demanda, nunca condicionado a
tamanho de projeto). Núcleo é `cloud/network` → `cloud/cluster` → `cloud/workloads`. State remoto
**1 por componente-folha**, **1 bucket por categoria** (nunca 1 único pro projeto, nunca 1 por
componente-folha). Zero child module — árvore de módulo sempre flat, 1 nível (HashiCorp).
Provider sempre na **última versão** (`~>` + `.terraform.lock.hcl` commitado), **sem código legado**.

Toda regra concreta vive em `references/checklist.md` — **única fonte de verdade**, usada pelos dois
modos. Não duplicar essas regras aqui.

## Modo de operação

Freeform + iterativo:
1. Identificar o modo — **criar** (§1), **adicionar componente** (§2) ou **auditar** (§3):
   - Path sem `.tf`/`terragrunt.hcl`/`modules/`/`environments/` → **criar** (projeto não existe ainda)
   - Path já com estrutura Terraform **e** o pedido pede algo novo (verbo de adição: "adiciona",
     "cria um módulo/componente novo nesse projeto", "preciso de um componente de X aqui") →
     **adicionar componente** — nunca cair em auditar só porque a estrutura já existe
   - Path já com estrutura Terraform **e** o pedido é revisão/checagem, sem pedir nada novo
     ("audita", "tá no padrão?", "revisa esse projeto") → **auditar**
   - Ambíguo → perguntar qual dos três antes de agir
2. Fazer perguntas de esclarecimento só quando a informação não estiver no pedido
3. Executar, mostrando o que foi gerado/encontrado
4. Usuário refina → a skill evolui a saída

---

## 1. Criar projeto novo (a partir do template)

### 1.1 Perguntas de esclarecimento (só as não respondidas no pedido)

- Nome do projeto e onde salvar (path)
- Cloud + provider(s) principal(is) (ex: `aws`, `azurerm`, `kubernetes`, `helm`)
- Nome do primeiro ambiente (ex: `dev`) — **nunca pré-criar `dev`+`hml`+`prd` de uma vez** (ver `checklist.md` §5)
- **Gate de concepção** (`checklist.md` §5): os ambientes divergem em **estrutura** (componente/recurso
  que existe num env e não noutro) ou só em **tamanho/valores**? Só tamanho → mesmo conjunto de
  componentes, diferença via `inputs`. Estrutura diverge → env pode ter componentes próprios.
- Quais componentes agora, e em qual **categoria** cada um (`cloud`, `observabilidade`,
  `seguranca`, `apps`, ...; categoria nova nasce sob demanda) — núcleo é `cloud/network` →
  `cloud/cluster` → `cloud/workloads`; opcionais só se pedido

### 1.2 Descobrir versão do provider + consultar Context7 (antes de gerar módulo)

Para cada provider:

1. **Versão (número)** — rodar, nunca inventar:
   ```bash
   scripts/get_latest_provider_version.sh <namespace> <name>
   # ex: scripts/get_latest_provider_version.sh hashicorp aws
   ```
   Terraform Registry API é a **autoridade de versão**. context7 nunca dá número de versão.
2. **Sintaxe/uso** — consultar **Context7 via MCP** (resolver a library id do provider → docs) para o
   resource shape da versão latest (breaking changes, exemplos de resource/data source).
3. **Guardrail de defasagem** — se a versão indexada no Context7 for menor que a latest da Registry,
   não copiar a sintaxe cega: preferir a doc da versão latest e confiar no `terraform validate`.
4. **Fallback** — se o MCP do Context7 estiver indisponível (ex: `context7.api_key` não configurado),
   não bloquear: seguir com a versão da Registry + `terraform validate`, e registrar no resumo
   "Context7 não consultado (MCP indisponível)".

Setup do usuário (1x, pré-requisito do MCP): `docker mcp secret set context7.api_key=<valor>`.

### 1.3 Copiar e adaptar `templates/project-template/`

Fonte em `templates/project-template/` (Terraform + Terragrunt), categoria de exemplo `cloud`:
```
terragrunt.hcl · .gitignore · README.md · CHANGELOG.md
scripts/bootstrap-state-backend.sh
docs/{architecture.md,runbook.md,backend-examples/{s3,gcs,azurerm}.hcl}
modules/cloud/{network,cluster,workloads}/{versions,main,variables,outputs}.tf + README.md
environments/example-env/{env.hcl,README.md,CHANGELOG.md}
environments/example-env/cloud/{network,cluster,workloads}/terragrunt.hcl
```

Passos:
1. Copiar a árvore inteira para o path do projeto novo — se a categoria pedida não for `cloud`,
   renomear `modules/cloud/`→`modules/<categoria>/` e o espelho em `environments/example-env/`
2. Preencher `terragrunt.hcl` raiz: `project`, `cloud` (provider), `state_region` — **não** existe
   mais campo de bucket a preencher à mão: o bucket já sai calculado como
   `${project}-tfstate-${categoria}` a partir de `path_relative_to_include()` (ver o próprio
   arquivo gerado). Usar `docs/backend-examples/` só se trocar de `s3` pra `azurerm`/`gcs`
3. Preencher cada `modules/<categoria>/<nome>/versions.tf` com o(s) provider(s) real(is) + `~> X.Y`
   da versão descoberta em §1.2 — nunca deixar `TODO_MAJOR.TODO_MINOR`
4. Implementar o conteúdo real de cada módulo com a sintaxe da **versão latest** (§1.2), zero
   deprecado — nunca `module{}` chamando outro módulo local dentro de `modules/` (checklist §2)
5. Renomear `environments/example-env/` para o ambiente pedido; criar só o(s) componente(s) pedido(s)
6. Rodar `scripts/bootstrap-state-backend.sh <cloud> <projeto>-tfstate-<categoria> <region>` — 1 vez
   por categoria usada, antes do 1º apply
7. Preencher `README.md`/`CHANGELOG.md` (raiz e env) com nome real e árvore gerada
8. **Validar** (§1.4) e conferir contra `references/checklist.md` inteiro
9. Mostrar, na conversa, a **árvore anotada** de cada módulo e componente criados
   (`checklist.md` §2/§5 como molde), marcando ✓ em cada linha confirmada — não só texto solto,
   é a confirmação visual de que a estrutura bate com o checklist
10. Exibir resumo final (§4)

### 1.4 Validar após gerar (self-validation em runtime)

Rodar antes de declarar pronto (gate determinístico):
```bash
terraform fmt -check -recursive
terragrunt hcl fmt --check
# por componente: terragrunt validate   (pega arg deprecado/inválido)
scripts/check_generated.sh <path-do-projeto>
```
Corrigir o que falhar. `terraform validate` é a rede anti-legado.

### 1.5 Nunca

- Backend **local** ou state central monolítico — sempre remoto + split por componente
- `main.tf` de root module na raiz — todo recurso vive em `modules/<categoria>/<nome>/`, chamado via `terragrunt.hcl`
- Categoria com `main.tf`/`module{}` próprio — categoria é só path, quem tem conteúdo é a subpasta
- `module{}` dentro de `modules/` chamando outro módulo local (`source = "./..."`/`"../..."`) — zero child module, árvore flat
- 1 bucket de state único pro projeto todo, ou 1 por componente-folha — o padrão é 1 por categoria
- `provider {}` block dentro de módulo — config de provider é gerada pelo Terragrunt
- `version = "X.Y.Z"` exato à mão ou provider sem version — sempre `~>` da latest + lock commitado
- Resource/argumento deprecado, ou exemplo copiado de doc de major antigo
- Ambiente, categoria ou componente pré-criado que ninguém pediu
- `terragrunt run --all` (apply/destroy/plan) sem `--parallelism 1` — em qualquer
  comando gerado/sugerido/documentado (README, runbook, resumo)

---

## 2. Adicionar componente a projeto existente

Diferente de **criar** (projeto novo) e de **auditar** (read-only): o projeto já existe e o pedido é
**estender** — um componente/módulo novo, sem recriar o que já está lá nem só revisar.

### 2.1 Quando usar

Path já tem `terragrunt.hcl`/`modules/`/`environments/`, **e** o pedido nomeia algo novo a criar
dentro dele (módulo, componente, ambiente adicional já é coberto por §1.3 passo 5 quando é o
primeiro ambiente do zero — aqui é sempre módulo/componente **dentro** de ambiente(s) já existente(s)
ou nascendo junto com um novo). Não confundir com auditar: aqui a skill **escreve** código.

### 2.2 Perguntas de esclarecimento (só as não respondidas no pedido)

- Nome do componente/módulo novo
- Categoria existente que ele entra, ou categoria nova (nasce sob demanda — nunca pré-criar outra vazia)
- Em qual(is) ambiente(s) — nunca todos por padrão, só o(s) pedido(s)
- De qual(is) componente(s) existente(s) ele depende (define o `dependency` no `terragrunt.hcl`)

### 2.3 Passos

1. Ler a estrutura real do projeto (categorias, componentes e módulos existentes) — nunca
   assumir, sempre conferir
2. Descobrir versão do provider + Context7 (§1.2) se o módulo novo usa provider ainda não presente no projeto
3. Criar `modules/<categoria>/<novo>/` (`versions.tf`/`main.tf`/`variables.tf`/`outputs.tf`),
   seguindo `checklist.md` §2 — inclusive: nunca `module` chamando outro `module` dentro de
   `modules/` (categoria nova? checar se já existe bucket pra ela — passo 6)
4. Para cada ambiente pedido, criar `environments/<env>/<categoria>/<novo>/terragrunt.hcl` com
   `source` + `dependency` do(s) componente(s) de que depende (mesma categoria: `../<comp>`;
   categoria diferente: `../../<outra-categoria>/<comp>`) — nunca o inverso, o componente
   existente não deve saber do novo
5. **Categoria nova** (nunca existiu nesse projeto)? Rodar
   `scripts/bootstrap-state-backend.sh <cloud> <projeto>-tfstate-<categoria> <region>` antes do
   1º apply dela — categoria já existente reusa o bucket que já existe, sem rodar de novo
6. Validar (reusa §1.4: `check_generated.sh`, que já roda `check_naming.py`)
7. Atualizar `README.md` (tabela de componentes) e `CHANGELOG.md` do(s) ambiente(s) tocado(s)
8. Mostrar, na conversa, a **árvore anotada** do módulo e do componente criados (`checklist.md`
   §2/§5), marcando ✓ em cada linha confirmada
9. Exibir resumo final (§4)

### 2.4 Nunca

- Recriar o projeto do zero quando ele já existe — só adiciona o que falta
- Editar `modules/` de um componente **já existente** sem pedido explícito — isso é correção
  (achado de auditoria), ação separada, perguntar antes
- Pré-criar em ambiente que não foi pedido

---

## 3. Auditar projeto existente

### 3.1 Escopo

Audita **1 projeto por invocação** (usuário aponta o path). Não varre o workspace inteiro.

### 3.2 Passos

1. Ler a estrutura real (`find <path> -name "*.tf" -o -name "*.hcl"`)
2. Para cada provider em `modules/**/versions.tf` (qualquer categoria), rodar
   `scripts/get_latest_provider_version.sh` e comparar
3. Percorrer `references/checklist.md` inteiro (§1 a §8) contra o projeto, marcando conforme/não conforme
4. Rodar `scripts/check_generated.sh <path>` para os checks determinísticos (fmt/validate/lock/`~>`/deprecated)
5. Preencher `templates/audit-report-template.md` — não inventar item fora do checklist
6. Salvar o relatório **dentro do projeto auditado** como `docs/terraform-audit-<data>.md`
7. Resumir os findings na conversa: pra achado de layout/módulo/componente, usar a **árvore anotada**
   (`checklist.md` §2/§5) com ✓/❌ por linha — complementa as tabelas do relatório salvo, não substitui
8. Exibir path do relatório + resumo final (§4)

### 3.3 Nunca

- Editar o código do projeto auditado automaticamente — auditoria é leitura + relatório (corrigir é ação separada, perguntar antes)
- Reportar "provider atrás da latest" ou "código legado" como bloqueante — é informativo
- Gerar relatório sem rodar `get_latest_provider_version.sh` e `check_generated.sh` de verdade

---

## 4. Resumo final (sempre exibir ao terminar criar, adicionar componente ou auditar)

```
## Decisões aplicadas

| Item | Situação | Ação |
|---|---|---|
| Modo de execução | [criar / adicionar componente / auditar] | [gerado / adicionado / auditado] |
| Ambientes | [lista] | [criados / auditados] |
| Categorias | [cloud/observabilidade/seguranca/apps/...] | [criadas / auditadas] |
| Componentes | [cloud/network, cloud/cluster, .../...] | [criados / auditados] |
| Providers | [lista] | [versão ~> via get_latest_provider_version.sh] |
| Context7 (MCP) | [consultado / indisponível] | [sintaxe latest / fallback] |
| State | [remoto, 1 por componente-folha] | [keys por categoria/componente] |
| Bucket de state | [1 por categoria: `<projeto>-tfstate-<categoria>`] | [bootstrapado / já existia] |
| Validação | [fmt/validate/check_generated] | [ok / findings] |
| Checklist (references/checklist.md) | [conforme / findings] | [ok / relatório gerado] |
```

---

## Recursos

### scripts/
- `get_latest_provider_version.sh <namespace> <name>` — única fonte de versão de provider (Registry API). §1.2, §2.3, §3.2
- `check_generated.sh <path>` — gate determinístico de validação do código gerado (fmt/validate/`~>`/lock/deprecated), chama `check_naming.py`. §1.4, §2.3, §3.2
- `check_naming.py <path>` — checagem determinística de naming/description (checklist §6) e segredo hardcoded em `inputs {}` — usado por `check_generated.sh` e diretamente na auditoria

### references/
- `checklist.md` — fonte única de verdade de layout, módulos, provider/versão, state, ambientes, componentes, naming, validação. Ler antes de criar, adicionar componente ou auditar.

### templates/
- `project-template/` — template Terraform + Terragrunt para copiar ao criar projeto novo (§1.3) ou compor componente novo (§2.3)
- `audit-report-template.md` — template do relatório do modo auditoria (§3.2)

---

## Fora de escopo

Ver `references/checklist.md` §8 — resumo: conteúdo de `resource` específico, conteúdo de deploy de app
(Helm/ArgoCD), módulos de terceiros, varredura multi-projeto.
