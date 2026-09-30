# gerador-git-workflow

## 🎯 Propósito & Escopo
Gera ou audita/corrige workflows do GitHub Actions em `.github/workflows/` — resolve o problema de pipelines usando actions não-oficiais, sem pin de versão, ou reinventando script manual que já existe como action mantida.

## 🌟 Para que ela é útil?
Muitos workflows de CI/CD acumulam actions de terceiros desconhecidas, referências mutáveis (`@main`/`@latest`) e scripts inline que reinventam o que já existe como action oficial mantida. Esta skill atua como um gate: para cada step, consulta o context7 MCP pra checar se já existe uma action oficial equivalente (checkout, build/push Docker, login de cloud, deploy k8s), e só aceita script manual quando nada oficial existe — sempre com pin de versão. Reduz risco de supply chain e custo de manutenção sem exigir que o usuário memorize o catálogo de actions de cada fornecedor.

## 🛠️ Como usar?
- Pedir diretamente: "cria workflow", "gera workflow", "audita workflow", "revisa workflow", "corrige workflow", "padroniza workflow".
- Frases de intenção: "criar CI", "criar CD", "criar CI/CD", "pipeline de deploy", "pipeline de build", "automatizar build/deploy".
- A skill decide sozinha entre dois sub-modos, sem o usuário precisar escolher: geração (do zero) ou auditoria (arquivo existente).

## ⏳ Quando usar?
Sempre que a tarefa envolver configurar automação com GitHub Actions.
- Repositório sem nenhum arquivo em `.github/workflows/` e o usuário pede uma pipeline nova.
- Repositório já tem workflows e o usuário quer revisão/correção contra boas práticas (actions não-oficiais, sem pin, script reinventando o que já existe como action).

## ✅ O que fazer?
- Detectar o modo: sem arquivos em `.github/workflows/` → geração; com arquivos → auditoria.
- Para cada step (novo ou existente), consultar o context7 MCP (`mcp__context7__resolve-library-id` + `mcp__context7__query-docs`) antes de aceitar qualquer script manual.
- Aplicar as regras obrigatórias: pin de versão sempre (idealmente exata via context7), só actions de fornecedores oficiais (`actions/`, `docker/`, `aws-actions/`, `google-github-actions/`, `azure/`, `hashicorp/`), `run_number` como versionamento só quando nenhuma outra estratégia já existir.
- Modo geração: escrever o arquivo `.github/workflows/<nome>.yml` diretamente.
- Modo auditoria: exibir o diff completo das mudanças propostas e aguardar confirmação explícita (`sim`, `pode aplicar`) antes de sobrescrever.
- Encerrar sempre com a tabela de resumo (`Step | Decisão | Action utilizada | Motivo`).

## 🚫 O que NÃO fazer?
- Não usar `@main`, `@master` ou `@latest` em nenhuma action — são referências mutáveis, risco de supply chain.
- Não usar actions de usuários individuais desconhecidos — só fornecedores oficiais reconhecidos; sem action oficial, manter script manual documentado.
- Não sobrescrever uma estratégia de versionamento já existente no workflow (tag semver manual, git tag) só porque `run_number` é o padrão default.
- Não sobrescrever arquivo no modo auditoria sem confirmação explícita do usuário.
- Não tocar em `action.yml` de composite actions locais, scripts externos referenciados, ou configuração de ambiente do repositório — fora do escopo (só `.github/workflows/*.yml`).

## 📥 Parâmetros de Entrada (Inputs)
- Diretório `.github/workflows/` do repositório (implícito).
- Confirmação do usuário (obrigatório só no modo auditoria, antes de sobrescrever arquivo existente).

## 📤 Estrutura de Saída (Outputs)
- Modo geração: arquivo `.github/workflows/<nome>.yml` novo.
- Modo auditoria: diff completo das mudanças propostas, aplicado só após confirmação.
- Tabela de resumo: `Step | Decisão | Action utilizada | Motivo`.

## 🔧 Dependências & Ferramentas
`context7` MCP (`mcp__context7__resolve-library-id`, `mcp__context7__query-docs`) — obrigatório consultar antes de qualquer script manual, pra achar action oficial equivalente e sua versão mais recente.

## 💡 Casos de Uso Reais
- Prompt: "audita os workflows desse repo." → Resposta: leitura de todos os `.yml` em `.github/workflows/`, identificação de actions não pinadas ou de terceiros desconhecidos, diff proposto com correção, aguardando "sim"/"pode aplicar" antes de sobrescrever.
- Validação: workflow existente usando `actions/checkout@main` e um script manual de build Docker → a skill sinaliza a versão mutável como violação, sugere a action oficial `docker/build-push-action` pinada via context7, e só aplica após confirmação explícita.

## ⚠️ Tratamento de Erros
- Nenhuma action oficial encontrada via context7 pra um step → manter script manual, registrar o motivo no resumo (não é falha bloqueante).
- Modo auditoria sem confirmação do usuário → não sobrescrever, ficar parado no diff.
