# Site — vitrine do prompt registry

Vitrine local (Astro) dos prompts deste repositório. É uma **projeção pura** dos arquivos
do repo: varre cada domínio de 1º nível (`engenharia/`, `cloud/`, `meta_prompting/`, etc — 
descoberto dinamicamente, não hardcoded) e trata como "prompt" todo `.md` cujo frontmatter
tenha o campo `nome` (o padrão documentado em `CLAUDE.md`/`/catalogar`). **Nenhum conteúdo
é duplicado aqui** — catalogar um prompt novo com `/catalogar` atualiza o site no próximo
build.

## Rodar local

Requer Node ≥18.20.8 (Astro 5) — use `nvm use` (lê o `.nvmrc` deste diretório).

```bash
cd .site
nvm use
npm install
npm run dev        # http://localhost:8020
npm run build      # gera dist/ + índice Pagefind
npm run preview    # serve dist/ (com busca funcionando)
```

## Reskin (ponto único)

Todo o branding vive em `src/site.config.ts` (nome, tagline, descrição, autor) e os tokens
de tema em `src/styles/theme.css` (fundo roxo escuro por padrão). Troque a logo em
`public/logo.svg`.

## Arquitetura

- **Prompt é o protagonista** da vitrine (grid no índice); cada card mostra domínio (eyebrow),
  nome, descrição (`descricao` do frontmatter — já curta por convenção) e até 2 tags.
- **Domínio/tema** (pasta) vira a árvore de navegação da sidebar — mesma pasta que organiza
  o vault no Obsidian.
- **Detalhe do prompt**: mostra tags, variáveis de `inputs`, caminho do arquivo (com botão
  copiar), e o corpo do prompt renderizado numa caixa colapsável.
- **Busca**: Pagefind (client-side, indexado no build). Em `dev` o box degrada com aviso.

## Regra de higiene do loader (importante)

`src/content.config.ts` varre cada domínio recursivamente, mas **pula** `.claude/`,
`.obsidian/`, `.trash/`, `.git/`, `golden/`, `inputs/`, `judge-prompts/`, `result/`,
`node_modules/`, `.venv/`, `outputs/` e qualquer pasta com prefixo `.` — são scaffolding
de avaliação (promptfoo), não prompts catalogados. Um `.md` só vira item da vitrine se seu
frontmatter tiver `nome:` — isso descarta automaticamente `README.md`, `MAP.md`, `EVAL.md`,
`RUN.md` e arquivos de `golden/` (que não têm esse campo).
