// Branding centralizado. Ponto único de reskin: troque os valores abaixo (e a
// logo em `public/logo.svg`) sem mexer no resto do código.

export const site = {
  name: 'Prompt Registry',
  tagline: 'Vitrine navegável dos prompts deste registro pessoal',
  // Logo servida de .site/public/ (URL na raiz). Fundo rosa claro pra diferenciar
  // visualmente da seção /skills (fundo roxo, ver public/logo.svg).
  logo: '/logo-prompts.svg',
  description:
    'Vitrine navegável dos prompts deste registro — derivada direto dos arquivos markdown do repositório (ver /catalogar em CLAUDE.md).',
  author: {
    name: 'Marcelo Diniz',
    email: 'voce@exemplo.com',
    github: 'mdinizcloud',
  },
} as const;

export type SiteConfig = typeof site;

// Branding da seção /skills — mesmo processo Astro, conteúdo lido ao vivo do
// repo irmão `skills_registry` (ver skillsRepoRootFrom em content.config.ts).
// Espelha skills_registry/.site/src/site.config.ts.
const skillRepoSlug = 'owner/repo';

export const skillSite = {
  name: 'Skill Registry',
  tagline: 'Marketplace de plugins e skills para o Claude Code',
  logo: '/logo.svg',
  description:
    'Vitrine navegável dos plugins e skills do marketplace — derivada direto dos arquivos do repositório skills_registry.',
  repo: {
    slug: skillRepoSlug,
    installAll: `npx skills add ${skillRepoSlug} --full-depth`,
  },
  author: {
    name: 'Marcelo Diniz',
    email: 'voce@exemplo.com',
    github: 'mdinizcloud',
  },
} as const;

export type SkillSiteConfig = typeof skillSite;
