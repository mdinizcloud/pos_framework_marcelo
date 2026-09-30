---
name: pr-worktrees
description: Use esta skill quando o usuário quiser abrir pull requests a partir de git worktrees existentes, um PR por worktree, como se fossem devs/agents diferentes trabalhando em paralelo. Dispara em pedidos como "cria os PR dos worktree", "abre um PR pra cada worktree", "faz o pull request dessas branches paralelas", "simula devs diferentes nesses worktrees", ou quando o usuário menciona ter criado 2+ worktrees de um app e querer um PR por feature. Nunca assume nome de repositório, owner do GitHub ou remote — sempre descobre dinamicamente o repo local dos worktrees e o repo-raiz real (monorepo/superprojeto) a partir do diretório atual, porque o `origin` de um repo copiado/baseline pode apontar pra um repo errado que não é o destino real dos PRs.
---

# PR a partir de worktrees

Objetivo: dado um conjunto de git worktrees (branches paralelas de um mesmo repo, tipicamente simulando
devs/agents diferentes), abrir **um pull request por worktree** no destino GitHub correto — sem nunca fixar
nomes de repo, owner ou remote no prompt. Tudo é descoberto no momento da execução, a partir de onde o
usuário está.

## Por que a descoberta dinâmica importa

Um repo copiado/vendorizado dentro de um monorepo (ex. baixado de um baseline, de um template, de um fork)
carrega o `origin` original dele no `.git/config` — mas esse `origin` pode não ter nenhuma relação com o
repo GitHub real onde o usuário trabalha hoje. Confiar cegamente nesse `origin` gera PR no repo errado
(ou tentativa de push sem permissão). **Nunca copiar/hardcodar** um nome de repo ou owner visto numa sessão
anterior — cada execução desta skill redescobre tudo do zero.

## Passo 1 — Descobrir o repo interno (onde vivem os worktrees)

A partir do diretório atual (ou do caminho que o usuário apontar):

```bash
git rev-parse --show-toplevel        # raiz do repo interno (pode já ser um worktree)
git worktree list                    # lista todos os worktrees desse repo — path, HEAD, branch
```

Cada linha de `git worktree list` é um worktree candidato a virar 1 PR. Descarte o worktree que está na
branch base (`main`/`master`/`develop` — confirme com `git symbolic-ref refs/remotes/origin/HEAD` ou
`gh repo view --json defaultBranchRef` rodado a partir do repo interno) — esse é o checkout original, não
uma feature.

Se o usuário só quer um subconjunto dos worktrees (ex. só os 2 que ele acabou de criar), confirme a lista
com ele antes de prosseguir, em vez de assumir "todos".

## Passo 2 — Descobrir o repo-raiz real (destino dos PRs)

O `origin` do repo interno **não é confiável por padrão**. Antes de usá-lo, verifique se o repo interno está
aninhado dentro de outro repositório git (um monorepo/superprojeto que o contém, ex. `store/<app>/` dentro
de um repo maior):

```bash
# a partir do pai do toplevel do repo interno, suba diretório por diretório
# procurando outro `git rev-parse --show-toplevel` que dê um resultado DIFERENTE do repo interno
cd "$(dirname "$(git -C <repo-interno> rev-parse --show-toplevel)")"
git rev-parse --show-toplevel 2>/dev/null   # repita subindo até achar um toplevel diferente, ou até a raiz do filesystem
```

Dois cenários:

- **Achou um repo-raiz diferente (monorepo/superprojeto):** esse é o destino real dos PRs. Pegue o remote
  dele (`git -C <repo-raiz> remote get-url origin`) e derive owner/repo do GitHub a partir dessa URL — é
  esse, e só esse, que vale. O `origin` do repo interno é ignorado a partir daqui (não usar pra push, não
  usar pra `gh pr create`, não mencionar no corpo do PR).
- **Não achou repo-raiz diferente** (o repo interno já é standalone, não está copiado dentro de outro repo
  git): o destino dos PRs é o próprio `origin` do repo interno — mas confirme isso com o usuário antes de
  fazer push, porque "standalone" também pode significar "ainda não vinculado a lugar nenhum".

Em caso de dúvida sobre qual é o repo-raiz certo (múltiplos candidatos, remote ambíguo, sem acesso via `gh`),
**pare e pergunte** em vez de adivinhar — esta é uma ação que push/abre PR em repo GitHub real, não é
reversível de graça.

## Passo 3 — Verificar se já existe um padrão estabelecido no repo-raiz

Antes de inventar um formato de PR, olhe se o repo-raiz já tem um precedente para "trazer" mudanças de um
repo copiado aninhado (histórico de commits/PRs tocando o mesmo caminho, ex. `git log --oneline --all --
<caminho-do-worktree-relativo-ao-repo-raiz>` ou `gh pr list` filtrando por título/arquivo). Casos comuns:

- **Padrão de "gitlink bump"** já existe (um commit anterior faz `git update-index --add --cacheinfo 160000,<sha>,<caminho>`
  apontando pro path do worktree na ponta da feature branch, sem registrar `.gitmodules`): replique
  exatamente esse padrão para os novos worktrees — mesmo formato de branch (`feat/<feature>-submodule` ou o
  nome usado no precedente), mesmo estilo de mensagem de commit, mesmo formato de corpo de PR (Summary +
  Test plan). Não inclua links para "PR companheiro" em outro repo a menos que esse outro PR realmente exista
  — link morto quebra a review.
- **Sem precedente:** pergunte ao usuário se o objetivo é (a) um PR de "ponteiro"/gitlink no repo-raiz
  apontando pro commit da feature, ou (b) um PR normal de código, com o diff completo do worktree copiado
  pro repo-raiz. São fluxos bem diferentes — não escolha por conta própria na primeira vez.

## Passo 4 — Criar um PR por worktree

Para cada worktree (exceto o da branch base):

```bash
cd <repo-raiz>
git checkout <branch-base-do-repo-raiz>
git pull
git checkout -b <nome-da-branch-do-pr>          # ex.: feat/<nome-da-feature>-submodule
git update-index --add --cacheinfo 160000,<sha-head-do-worktree>,<caminho-relativo-do-worktree-no-repo-raiz>
git status --short <caminho-relativo-do-worktree>   # confirme que SÓ esse caminho foi staged
git commit -m "..."
git push -u origin <nome-da-branch-do-pr>
gh pr create --repo <owner/repo-do-repo-raiz> --base <branch-base> --head <nome-da-branch-do-pr> --title "..." --body "..."
```

Regras de segurança:

- **Nunca** dar `git add -A`/`git add .` no repo-raiz — ele provavelmente tem outros diretórios/submódulos
  modificados sem relação com essa tarefa (outros apps copiados, outros worktrees em andamento). Staged
  apenas o caminho do gitlink do worktree em questão, e confirme com `git status --short <caminho>` antes de
  commitar.
- **Nunca** push/PR contra o `origin` do repo interno depois de identificar um repo-raiz diferente no Passo 2.
- Corpo do PR reflete só o que foi de fato verificado (testes rodados, comportamento observado) — não inventar
  checklist de teste.
- Se o repo-raiz tiver mudanças não relacionadas em andamento (`git status` sujo antes mesmo de você começar),
  não commitar nem tocar nelas — são de outra tarefa.
