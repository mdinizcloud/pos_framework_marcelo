# pr-worktrees

## 🎯 Propósito & Escopo
Abre um pull request por git worktree no repositório GitHub correto, descobrindo em runtime o repo interno e o repo-raiz real (monorepo/superprojeto) em vez de confiar no `origin` — que num repo copiado ou vindo de baseline aponta pro lugar errado.

## 🌟 Para que ela é útil?
O cenário típico é ter criado 2+ worktrees do mesmo app, cada um numa branch de feature, simulando devs ou agents diferentes trabalhando em paralelo — e agora querer transformar cada um deles num PR separado. O trabalho chato não é rodar `gh pr create`, é descobrir *onde* o PR deve ir: um repo vendorizado dentro de um monorepo carrega o `.git/config` original dele, então o `origin` local aponta pro template/fork de origem, não pro repo onde o usuário trabalha hoje. Com esta skill ativa, o modelo nunca reaproveita owner/repo visto numa sessão anterior nem confia cegamente no `origin`: sobe a árvore de diretórios procurando um toplevel git diferente, procura precedente de como mudanças desse caminho já entraram no repo-raiz (padrão de gitlink bump vs. diff completo), e para pra perguntar quando há ambiguidade — porque push e abertura de PR em repo real não são reversíveis de graça.

## 🛠️ Como usar?
- Rodar a partir do diretório do repo que contém os worktrees (ou apontar o caminho explicitamente).
- Frases naturais que disparam: "cria os PR dos worktree", "abre um PR pra cada worktree", "faz o pull request dessas branches paralelas", "simula devs diferentes nesses worktrees".
- Também dispara ao mencionar ter criado 2+ worktrees de um app e querer um PR por feature.

## ⏳ Quando usar?
Quando existem worktrees prontos e revisados que precisam virar PRs independentes, especialmente se o repo dos worktrees está aninhado dentro de outro repositório git.
- Vários worktrees de features paralelas prontos para review, um PR cada.
- Repo copiado dentro de um monorepo (ex.: `store/<app>/`), onde o destino real dos PRs é o repo-raiz e não o `origin` do repo interno.
- Repetição de um fluxo de "trazer" mudanças pro repo-raiz que já tem precedente no histórico e deve ser replicado igual.

## ✅ O que fazer?
- Descobrir o repo interno com `git rev-parse --show-toplevel` e listar candidatos com `git worktree list`, descartando o worktree que está na branch base.
- Confirmar com o usuário o subconjunto de worktrees quando ele não pediu explicitamente "todos".
- Subir diretório por diretório a partir do pai do toplevel procurando um toplevel git diferente; se achar, esse repo-raiz é o destino dos PRs e o `origin` do repo interno passa a ser ignorado por completo.
- Se não achar repo-raiz diferente, confirmar com o usuário antes de qualquer push — standalone também pode significar "ainda não vinculado a lugar nenhum".
- Procurar precedente no repo-raiz (`git log` no caminho do worktree, `gh pr list`) e replicar exatamente o padrão encontrado: formato de branch, estilo de mensagem de commit, formato do corpo do PR.
- Para cada worktree: branch nova a partir da base atualizada, staged apenas do caminho em questão (gitlink via `git update-index --add --cacheinfo 160000,<sha>,<caminho>` quando esse for o padrão), conferência com `git status --short <caminho>`, commit, push e `gh pr create --repo <owner/repo-do-repo-raiz>`.

## 🚫 O que NÃO fazer?
- Nunca hardcodar ou reaproveitar nome de repo, owner ou remote de sessão anterior — cada execução redescobre tudo, porque o destino muda conforme onde o usuário está.
- Nunca `git add -A` / `git add .` no repo-raiz — ele costuma ter outros apps copiados e worktrees em andamento, sem relação com a tarefa; um add amplo arrasta mudanças de outra pessoa pro PR.
- Nunca fazer push ou abrir PR contra o `origin` do repo interno depois de identificar um repo-raiz diferente — o PR iria pro repositório errado.
- Nunca escolher entre PR de gitlink/ponteiro e PR com diff completo por conta própria quando não há precedente — são fluxos bem diferentes e a decisão é do usuário.
- Nunca inventar checklist de teste no corpo do PR nem linkar "PR companheiro" que não existe — link morto quebra a review.
- Não tocar em mudanças não relacionadas já presentes no repo-raiz (`git status` sujo antes de começar) — são de outra tarefa.

## ⚡ Gatilhos de Execução (Triggers)
- "cria os PR dos worktree" / "abre um PR pra cada worktree".
- "faz o pull request dessas branches paralelas" / "simula devs diferentes nesses worktrees".
- Menção a ter criado 2+ worktrees de um app e querer um PR por feature.

## 🚫 Condições de Não-Ativação
- Abertura de um único PR da branch atual, sem worktrees envolvidos.
- Criação ou gestão dos worktrees em si (a skill assume worktrees já existentes).
- Geração/auditoria de workflow do GitHub Actions — isso é `gerador-git-workflow`.

## 📥 Parâmetros de Entrada (Inputs)
- Diretório atual (ou caminho informado) de onde parte a descoberta do repo interno.
- Opcional: subconjunto de worktrees que devem virar PR.
- Opcional: decisão entre PR de gitlink/ponteiro e PR com diff completo, quando não há precedente no repo-raiz.

## 📤 Estrutura de Saída (Outputs)
- Uma branch nova por worktree no repo-raiz, com um único caminho staged.
- Um pull request por worktree, no `owner/repo` do repo-raiz, contra a branch base dele.
- Corpo de PR no formato do precedente encontrado (ex.: Summary + Test plan), refletindo só o que foi de fato verificado.

## 🔧 Dependências & Ferramentas
- `git` (subcomandos `worktree`, `rev-parse`, `update-index`, `symbolic-ref`).
- `gh` CLI autenticada, com permissão de push no repo-raiz (`gh repo view`, `gh pr list`, `gh pr create`).

## 🔄 Fluxo Operacional
1. Descobrir o repo interno e listar os worktrees; descartar o da branch base.
2. Subir a árvore de diretórios procurando um toplevel git diferente — o repo-raiz real, destino dos PRs.
3. Derivar owner/repo a partir do remote do repo-raiz; em ambiguidade ou ausência, parar e perguntar.
4. Procurar precedente no repo-raiz para mudanças naquele caminho e replicar o padrão; sem precedente, perguntar gitlink vs. diff completo.
5. Por worktree: branch a partir da base atualizada → staged só do caminho → conferir `git status --short` → commit → push → `gh pr create`.

## 💡 Casos de Uso Reais
- Prompt: "cria os PR dos worktree" a partir de um app copiado em `store/<app>/` → Resposta: identifica o monorepo acima como repo-raiz, ignora o `origin` do app, replica o gitlink bump do precedente e abre um PR por worktree.
- Prompt: "abre um PR pra cada worktree" num repo standalone → Resposta: não acha repo-raiz diferente, confirma com o usuário que o destino é o próprio `origin` antes de qualquer push.
- Prompt: "faz o pull request dessas branches paralelas" sem precedente no repo-raiz → Resposta: pergunta se o objetivo é PR de ponteiro/gitlink ou PR com diff completo antes de criar qualquer branch.

## ⚠️ Tratamento de Erros
- Múltiplos candidatos a repo-raiz, remote ambíguo ou sem acesso via `gh` → parar e perguntar, nunca adivinhar.
- Nenhum repo-raiz diferente encontrado → confirmar com o usuário antes do push, em vez de assumir o `origin` do repo interno.
- `git status` sujo no repo-raiz antes de começar → não commitar nem tocar nessas mudanças; isolar apenas o caminho do worktree.
- `git status --short <caminho>` mostrando mais do que o caminho esperado → abortar o commit, o staging vazou para arquivos de outra tarefa.
- Nenhum precedente de "trazer mudanças" no repo-raiz → não escolher formato por conta própria; perguntar gitlink vs. diff completo.
