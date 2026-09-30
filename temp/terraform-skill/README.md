# terraform-skill

## 🎯 Propósito & Escopo
Padronizar organização e formatação de projetos Terraform + Terragrunt neste workspace, em três modos: criar projeto novo a partir de template, adicionar componente a projeto existente, ou auditar (read-only) um projeto contra o checklist de padrões. Não cobre conteúdo de `resource` específico de provider nem deploy de aplicação (Helm/ArgoCD) — só estrutura, layout e formatação do projeto.

## 🌟 Para que ela é útil?
Evita que cada projeto Terraform novo (ou componente adicionado) nasça com uma estrutura diferente: fixa um modelo único (módulos/environments segregados por categoria, núcleo `cloud/network` → `cloud/cluster` → `cloud/workloads`, state remoto 1 bucket por categoria, zero child module, provider sempre na versão latest com lock commitado) e valida isso de forma determinística (`terraform fmt`, `terragrunt validate`, `check_generated.sh`) em vez de confiar em revisão manual. O modo auditoria permite checar um projeto já existente contra esse mesmo padrão sem alterar nada.

## 🛠️ Como usar?
- Pedir para criar um projeto Terraform novo do zero ("cria um projeto Terraform pra X", "iniciar projeto terraform")
- Pedir para adicionar um componente/módulo a um projeto Terraform existente
- Pedir para auditar um projeto Terraform existente contra os padrões do workspace ("essa estrutura Terraform tá no padrão?")
- Rodar os scripts diretamente: `scripts/get_latest_provider_version.sh <namespace> <name>`, `scripts/check_generated.sh <path>`, `scripts/check_naming.py <path> [--json]`

## ⏳ Quando usar?
- Path sem `.tf`/`terragrunt.hcl`/`modules/`/`environments/` e o pedido é criar algo novo → modo criar
- Path já com estrutura Terraform e o pedido nomeia um componente/módulo novo a adicionar → modo adicionar componente
- Path já com estrutura Terraform e o pedido é revisão/checagem sem pedir nada novo ("audita", "tá no padrão?") → modo auditar
- Se ambíguo qual dos três modos, a skill pergunta antes de agir

## ✅ O que fazer?
- Descobrir a versão do provider via `scripts/get_latest_provider_version.sh` antes de gerar módulo — nunca inventar número de versão
- Copiar e adaptar `templates/project-template/` ao criar projeto novo, renomeando a categoria de exemplo (`cloud`) se necessário
- Rodar `terraform fmt -check -recursive`, `terragrunt hcl fmt --check`, `terragrunt validate` por componente e `scripts/check_generated.sh <path>` antes de declarar pronto
- Seguir `references/checklist.md` como fonte única de verdade de layout, módulos, provider/versão, state, naming
- No modo auditar, preencher `templates/audit-report-template.md` e salvar o relatório dentro do projeto auditado como `docs/terraform-audit-<data>.md`
- Exibir a árvore anotada (✓ por linha) do módulo/componente criado ou auditado, e o resumo final em tabela (Decisões aplicadas)

## 🚫 O que NÃO fazer?
- Não gerar conteúdo de `resource` block específico de provider nem conteúdo de deploy de aplicação (Helm/ArgoCD) — fora de escopo
- Não usar backend local ou state central monolítico — sempre remoto, 1 bucket por categoria (nunca 1 único pro projeto nem 1 por componente-folha)
- Não criar `module{}` dentro de `modules/` chamando outro módulo local — árvore de módulo é sempre flat, zero child module
- Não pré-criar ambiente, categoria ou componente que ninguém pediu (inclusive nunca pré-criar dev+hml+prd de uma vez)
- Não rodar `terragrunt run --all` (apply/destroy/plan) sem `--parallelism 1`
- No modo auditar, não editar o código do projeto automaticamente — é leitura + relatório; corrigir é ação separada que precisa de pedido explícito
- No modo auditar, não reportar "provider atrás da latest" ou "código legado" como bloqueante — é informativo

## 📥 Parâmetros de Entrada (Inputs)
- `scripts/get_latest_provider_version.sh <namespace> <name>` — namespace e nome do provider (obrigatórios), ex.: `hashicorp aws`
- `scripts/check_generated.sh <path>` — path do projeto gerado/existente (obrigatório)
- `scripts/check_naming.py <path> [--json]` — path do projeto (obrigatório), `--json` para saída estruturada (opcional)
- Modo criar: nome do projeto + path, cloud/provider(s), nome do primeiro ambiente, se os ambientes divergem em estrutura ou só em tamanho/valores, componentes e categorias desejados
- Modo adicionar componente: nome do componente/módulo, categoria (existente ou nova), ambiente(s) alvo, dependências de componentes existentes
- Modo auditar: path do projeto a auditar (audita 1 projeto por invocação, não varre o workspace)

## 📤 Estrutura de Saída (Outputs)
- Modo criar: árvore de projeto Terraform + Terragrunt gerada a partir de `templates/project-template/` (módulos, ambientes, `terragrunt.hcl`, `README.md`/`CHANGELOG.md`), com bucket de state bootstrapado
- Modo adicionar componente: `modules/<categoria>/<novo>/` + `environments/<env>/<categoria>/<novo>/terragrunt.hcl` criados, `README.md`/`CHANGELOG.md` do ambiente atualizados
- Modo auditar: relatório salvo em `docs/terraform-audit-<data>.md` dentro do projeto auditado, a partir de `templates/audit-report-template.md`
- Em todos os modos: árvore anotada (✓ por linha) na conversa + tabela de resumo final ("Decisões aplicadas": modo, ambientes, categorias, componentes, providers, Context7, state, bucket, validação, checklist)

## 🔧 Dependências & Ferramentas
- CLI: `terraform` (fmt, validate), `terragrunt` (hcl fmt, validate, run --all)
- Scripts locais: `scripts/get_latest_provider_version.sh` (consulta a Terraform Registry API), `scripts/check_generated.sh`, `scripts/check_naming.py` (Python)
- Context7 via MCP (opcional) — resolve a library id do provider para consultar sintaxe/exemplos da versão latest; requer `docker mcp secret set context7.api_key=<valor>` configurado uma vez pelo usuário. Se indisponível, a skill segue com a versão da Terraform Registry + `terraform validate` e registra "Context7 não consultado (MCP indisponível)" no resumo
- `templates/project-template/` e `templates/audit-report-template.md` — templates usados nos três modos
- `references/checklist.md` — fonte única de verdade de todas as regras concretas (§1 a §8)

## 💡 Casos de Uso Reais
Não há exemplo concreto de prompt/resposta (input real → output real) documentado no SKILL.md — ele descreve os três modos e seus passos em detalhe, mas sem transcrever uma execução real.

## ⚠️ Tratamento de Erros
- Modo criar: erro de sintaxe/lint é pego por `terraform fmt -check`, `terragrunt hcl fmt --check`, `terragrunt validate` e `scripts/check_generated.sh` antes de declarar pronto — "corrigir o que falhar" é a instrução explícita, sem detalhar como
- Modo auditar: achados de não conformidade (provider defasado, código legado, item de checklist violado) são tratados como informativos, nunca bloqueantes — viram entrada do relatório salvo, não erro fatal
- Se o MCP do Context7 estiver indisponível, a skill não bloqueia: cai no fallback (Registry + `terraform validate`) e registra isso explicitamente no resumo — único fallback documentado no SKILL.md
- Não há tratamento documentado para falha do próprio `get_latest_provider_version.sh` (ex.: provider/namespace inexistente na Registry) ou para erro de rede ao consultá-la
