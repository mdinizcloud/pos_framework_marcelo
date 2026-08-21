# Site — vitrine do marketplace

Vitrine local (Astro) do marketplace. É uma **projeção pura** dos arquivos do repo:
lê `../.claude/marketplace.json` e, pra cada entrada em `plugins` (`{name, source, description}`),
o `SKILL.md` direto em `../<source>/SKILL.md`. **Nenhum conteúdo é duplicado aqui** — adicionar
uma entrada no `marketplace.json` (ou editar a skill referenciada) atualiza o site no próximo
build. Não existe pasta `plugins/` própria nem `docs/*.md` separado — hoje 1 entrada do
marketplace = 1 skill, e o "doc" da skill é o próprio corpo do `SKILL.md` (texto após o
frontmatter).

## Rodar local

Requer Node ≥18.20.8 (Astro 5) — o Node do sistema pode ser mais velho; use `nvm use` (lê o
`.nvmrc` deste diretório, pinado em 22).

```bash
cd .site
nvm use          # ou garanta Node >=18.20.8 por outro meio
npm install
npm run dev        # http://localhost:8010
npm run build      # gera dist/ + índice Pagefind
npm run preview    # serve dist/ (com busca funcionando)
```

## Reskin (ponto único)

Todo o branding vive em `src/site.config.ts` (nome, tagline, descrição, `repoSlug`, autor) e os
tokens de tema em `src/styles/theme.css`. Troque a logo em `public/logo.svg`. Nenhuma outra parte
do site precisa mudar para virar o SEU marketplace.

## Arquitetura

- **Skill é a protagonista** da vitrine (grid no índice); **plugin** é filtro + página própria.
- **Unidade de instalação é o plugin**.
- **Conteúdo do card** = 1º parágrafo do `docs/<skill>.md`. **Detalhe** = o doc inteiro renderizado.
- **Skill sem doc** aparece marcada como *sem documentação* (o site é também um painel de completude).
- **Busca**: Pagefind (client-side, indexado no build). Em `dev` o box degrada com aviso.

## Regra de higiene do loader (importante)

`src/content.config.ts` lê os arquivos em **profundidade fixa** com `fs`, nunca com glob
recursivo. A única fonte de verdade é `../.claude/marketplace.json` — cada entrada vira 1
plugin + 1 skill, lida direto de `<source>/SKILL.md` (SKILL.md tem que estar direto na pasta
apontada por `source`; qualquer coisa mais funda — `.venv`, `skill-snapshot/`, `outputs/docs/`
de evals — nunca é varrida, porque não há scan de diretório nenhum, só os caminhos listados no
`marketplace.json`).
