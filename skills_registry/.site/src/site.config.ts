// Branding + taxonomia centralizados. Ponto único de reskin: troque os valores
// abaixo (e a logo em `public/logo.svg`) para transformar este boilerplate no
// SEU marketplace. Nada mais no site precisa mudar.

// Slug do repositório (owner/repo), usado para montar os comandos `npx skills add`.
// TROQUE para o seu repositório no GitHub, ex.: 'suaorg/seu-marketplace'.
const repoSlug = 'mdinizcloud/skills_registry';

// Caminho local (checkout deste repo na máquina) usado nos comandos de instalação
// "direto do repositório" (--plugin-dir, plugin marketplace add) — alternativa ao
// npx que não depende de clonar do GitHub. TROQUE se o checkout local ficar noutro caminho.
const localRepoPath = '/github/skills_registry';

export const site = {
  name: 'Skill Registry',
  tagline: 'Marketplace de plugins e skills para o Claude Code',
  // Logo servida de site/public/ (URL na raiz). Troque o arquivo para reskin — sem mudar código.
  logo: '/logo.svg',
  description:
    'Vitrine navegável dos plugins e skills deste marketplace — derivada direto dos arquivos do repositório.',
  repo: {
    slug: repoSlug,
    localPath: localRepoPath,
    // Instala todas as skills do repo (cada uma no caminho listado em .claude/marketplace.json) — precisa de --full-depth.
    installAll: `npx skills add ${repoSlug} --full-depth`,
  },
  author: {
    name: 'Marcelo Diniz',
    email: 'voce@exemplo.com',
    github: 'mdinizcloud',
  },
} as const;

export type SiteConfig = typeof site;

// Branding da seção /prompts — mesmo processo Astro, conteúdo lido ao vivo do
// repo irmão `prompt_registry` (ver promptsRepoRootFrom em content.config.ts).
// Espelha prompt_registry/.site/src/site.config.ts.
export const promptSite = {
  name: 'Prompt Registry',
  tagline: 'Vitrine navegável dos prompts deste registro pessoal',
  // Fundo rosa claro pra diferenciar visualmente da seção /skills (fundo roxo).
  logo: '/logo-prompts.svg',
  description:
    'Vitrine navegável dos prompts do registro — derivada direto dos arquivos markdown do repositório prompt_registry (ver /catalogar em CLAUDE.md).',
  author: {
    name: 'Marcelo Diniz',
    email: 'voce@exemplo.com',
    github: 'mdinizcloud',
  },
} as const;

export type PromptSiteConfig = typeof promptSite;
