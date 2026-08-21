import { defineCollection, reference, z } from 'astro:content';
import type { Loader } from 'astro/loaders';
import { readFile, readdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import matter from 'gray-matter';
import { skillSite } from './site.config';

// ---------------------------------------------------------------------------
// Regra de higiene: nunca tratar todo .md como prompt. Este repo (Obsidian
// vault) tem README.md/MAP.md/EVAL.md/RUN.md de índice em toda pasta, e pastas
// de scaffolding de eval (golden/, inputs/, judge-prompts/, result/, .claude/)
// que também guardam .md — nada disso é prompt catalogado.
//   Prompt real = arquivo .md com frontmatter YAML contendo `nome:` (o padrão
//   documentado em CLAUDE.md deste repo, escrito por /catalogar). Se não tem
//   `nome` no frontmatter, não é prompt — é índice ou material de eval.
//   Domínio = pasta de 1º nível na raiz do repo (engenharia/, cloud/, etc) —
//   listado dinamicamente, não hardcoded (novo domínio aparece sem tocar código).
//   Categoria = segmentos de pasta entre o domínio e o arquivo (o "tema").
// ---------------------------------------------------------------------------

const SKIP_DIRS = new Set([
  '.claude', '.obsidian', '.trash', '.git', '.site', 'node_modules', '.venv',
  'golden', 'inputs', 'judge-prompts', 'result', 'outputs',
]);
const SKIP_FILENAMES = new Set(['README.md', 'MAP.md', 'EVAL.md', 'RUN.md', 'CLAUDE.md', 'DIR.md', 'AGENTS.md']);

function repoRootFrom(configRoot: URL): string {
  // configRoot aponta para .../.site/ ; o repo é o pai.
  return fileURLToPath(new URL('../', configRoot));
}

// Repo irmão skills_registry (fora deste repo, em /data/ssd_main/github/skills_registry
// no disco deste usuário) — servido pela seção /skills do mesmo processo Astro.
// Nenhum conteúdo é copiado pra cá: lido ao vivo via fs, igual ao promptsLoader acima.
function skillsRepoRootFrom(configRoot: URL): string {
  return path.resolve(repoRootFrom(configRoot), '..', 'skills_registry');
}

async function listTopDomains(repo: string): Promise<string[]> {
  const entries = await readdir(repo, { withFileTypes: true });
  return entries
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .filter((name) => !name.startsWith('.') && !SKIP_DIRS.has(name) && name !== 'assets' && name !== 'tools');
}

interface FoundPrompt {
  absPath: string;
  relPath: string; // relativo à raiz do repo, sem .md
}

async function walkForPrompts(repo: string, dir: string, acc: FoundPrompt[]): Promise<void> {
  const entries = await readdir(dir, { withFileTypes: true });
  for (const entry of entries) {
    if (entry.name.startsWith('.')) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (SKIP_DIRS.has(entry.name)) continue;
      await walkForPrompts(repo, full, acc);
    } else if (entry.isFile() && entry.name.endsWith('.md') && !SKIP_FILENAMES.has(entry.name)) {
      acc.push({ absPath: full, relPath: path.relative(repo, full).replace(/\.md$/, '') });
    }
  }
}

// --- Loader: prompts (protagonista) -------------------------------------------
function promptsLoader(): Loader {
  return {
    name: 'registry-prompts',
    async load({ store, parseData, renderMarkdown, config }) {
      const repo = repoRootFrom(config.root);
      const domains = await listTopDomains(repo);

      store.clear();

      for (const domain of domains) {
        const found: FoundPrompt[] = [];
        await walkForPrompts(repo, path.join(repo, domain), found);

        for (const { absPath, relPath } of found) {
          const raw = await readFile(absPath, 'utf8');
          let fm: matter.GrayMatterFile<string>;
          try {
            fm = matter(raw);
          } catch (err) {
            // YAML de frontmatter quebrado (ex.: ":" sem escape num valor) não pode
            // derrubar o build inteiro por causa de 1 arquivo — pula e avisa no log.
            console.warn(`[registry-prompts] frontmatter YAML inválido em ${relPath}.md, pulando: ${(err as Error).message}`);
            continue;
          }
          const nome = fm.data.nome as string | undefined;
          if (!nome) continue; // sem frontmatter de prompt catalogado -> não é item

          const descricao = String(fm.data.descricao ?? '').trim();
          const versao = String(fm.data.versao ?? '').trim();
          const tags = Array.isArray(fm.data.tags) ? fm.data.tags.map(String) : [];
          const inputs = Array.isArray(fm.data.inputs)
            ? fm.data.inputs.map((i: any) => ({
                nome: String(i?.nome ?? ''),
                descricao: String(i?.descricao ?? ''),
              }))
            : [];

          const segments = relPath.split('/');
          const domainName = segments[0];
          const category = segments.slice(0, -1); // pasta até o arquivo (domínio + tema)
          const filename = path.basename(absPath);

          const rendered = await renderMarkdown(fm.content, {
            fileURL: new URL(`${relPath}.md`, config.root),
          });

          // README.md (pasta própria do prompt) — opcional, exposto como aba extra na página.
          const readmePath = path.join(path.dirname(absPath), 'README.md');
          const hasReadme = existsSync(readmePath);
          let readmeHtml = '';
          if (hasReadme) {
            const readmeRaw = await readFile(readmePath, 'utf8');
            const readmeRel = path.relative(repo, readmePath);
            const readmeRendered = await renderMarkdown(readmeRaw, {
              fileURL: new URL(readmeRel, config.root),
            });
            readmeHtml = readmeRendered.html;
          }

          const id = relPath; // caminho relativo é único por definição (nomes de arquivo únicos no vault)

          const data = await parseData({
            id,
            data: { name: nome, descricao, versao, tags, inputs, domain: domainName, category, filename, relPath, hasReadme, readmeHtml, raw: fm.content.trim() },
          });
          store.set({ id, data, rendered });
        }
      }
    },
  };
}

const prompts = defineCollection({
  loader: promptsLoader(),
  schema: z.object({
    name: z.string(),
    descricao: z.string(),
    versao: z.string(),
    tags: z.array(z.string()),
    inputs: z.array(z.object({ nome: z.string(), descricao: z.string() })),
    domain: z.string(),
    category: z.array(z.string()),
    filename: z.string(),
    relPath: z.string(),
    hasReadme: z.boolean(),
    readmeHtml: z.string(),
    raw: z.string(),
  }),
});

// ---------------------------------------------------------------------------
// Skills/plugins (seção /skills) — porta de skills_registry/.site/src/content.config.ts,
// lendo do repo irmão via skillsRepoRootFrom em vez do próprio repo.
// ---------------------------------------------------------------------------

function extractBlurb(markdown: string): string {
  const body = matter(markdown).content;
  const lines = body.split(/\r?\n/);
  const collected: string[] = [];
  let seenH1 = false;
  for (const raw of lines) {
    const line = raw.trim();
    if (!seenH1) {
      if (line.startsWith('# ')) seenH1 = true;
      continue;
    }
    if (line.startsWith('## ')) break;
    if (line === '') {
      if (collected.length > 0) break;
      continue;
    }
    if (line.startsWith('#')) continue;
    collected.push(line);
  }
  return collected.join(' ').trim();
}

function extractPurpose(markdown: string): string {
  const body = matter(markdown).content;
  const marker = body.match(/^##\s*(?:🎯\s*)?Propósito\s*&\s*Escopo\s*$/m);
  if (!marker || marker.index === undefined) return '';
  const after = body.slice(marker.index + marker[0].length);
  const nextHeading = after.search(/\n##\s/);
  const section = nextHeading === -1 ? after : after.slice(0, nextHeading);
  return section
    .replace(/\*\*(.+?)\*\*/g, '$1')
    .replace(/\*(.+?)\*/g, '$1')
    .replace(/`([^`]+)`/g, '$1')
    .replace(/\s+/g, ' ')
    .trim();
}

type MarketplaceEntry = { name: string; source: string; description: string };

async function readMarketplace(repo: string): Promise<MarketplaceEntry[]> {
  const marketplacePath = path.join(repo, '.claude', 'marketplace.json');
  const marketplace = JSON.parse(await readFile(marketplacePath, 'utf8')) as {
    plugins: MarketplaceEntry[];
  };
  return marketplace.plugins;
}

function pluginsLoader(): Loader {
  return {
    name: 'marketplace-plugins',
    async load({ store, parseData, config }) {
      const repo = skillsRepoRootFrom(config.root);
      const plugins = await readMarketplace(repo);

      store.clear();
      for (const p of plugins) {
        const sourceRel = p.source.replace(/^\.\//, '');
        const data = await parseData({
          id: p.name,
          data: {
            name: p.name,
            description: p.description,
            version: '',
            installCommand: `npx skills add ${skillSite.repo.slug}/${sourceRel}`,
          },
        });
        store.set({ id: p.name, data });
      }
    },
  };
}

function skillsLoader(): Loader {
  return {
    name: 'marketplace-skills',
    async load({ store, parseData, renderMarkdown, config }) {
      const repo = skillsRepoRootFrom(config.root);
      const plugins = await readMarketplace(repo);

      store.clear();
      const seen = new Set<string>();

      for (const p of plugins) {
        const sourceRel = p.source.replace(/^\.\//, '');
        const skillDir = path.join(repo, sourceRel);
        const skillMd = path.join(skillDir, 'SKILL.md');
        if (!existsSync(skillMd)) continue;

        const skillId = path.basename(sourceRel);
        if (seen.has(skillId)) {
          throw new Error(
            `Nome de skill duplicado entre entradas do marketplace: "${skillId}". Ids/URLs precisam ser únicos.`,
          );
        }
        seen.add(skillId);

        const raw = await readFile(skillMd, 'utf8');
        const fm = matter(raw);
        const name = (fm.data.name as string) ?? skillId;
        const description = String(fm.data.description ?? '').trim();

        const body = fm.content.trim();
        const hasDoc = body.length > 0;
        const rendered = hasDoc
          ? await renderMarkdown(fm.content, { fileURL: new URL(`file://${skillDir}/SKILL.md`) })
          : undefined;

        const category = sourceRel.split('/').slice(0, -1);

        const readmePath = path.join(skillDir, 'README.md');
        const hasReadme = existsSync(readmePath);
        let readmeHtml = '';
        let readmeRaw = '';
        if (hasReadme) {
          readmeRaw = await readFile(readmePath, 'utf8');
          const readmeRendered = await renderMarkdown(readmeRaw, {
            fileURL: new URL(`file://${skillDir}/README.md`),
          });
          readmeHtml = readmeRendered.html;
        }

        const purpose = hasReadme ? extractPurpose(readmeRaw) : '';
        const skillBlurb = hasDoc ? extractBlurb(raw) : '';
        const blurb = purpose || skillBlurb || (description.length > 180 ? `${description.slice(0, 177)}…` : description);

        const data = await parseData({
          id: skillId,
          data: { name, plugin: p.name, description, blurb, hasDoc, category, hasReadme, readmeHtml },
        });
        store.set({ id: skillId, data, rendered });
      }
    },
  };
}

const plugins = defineCollection({
  loader: pluginsLoader(),
  schema: z.object({
    name: z.string(),
    description: z.string(),
    version: z.string(),
    installCommand: z.string(),
  }),
});

const skills = defineCollection({
  loader: skillsLoader(),
  schema: z.object({
    name: z.string(),
    plugin: reference('plugins'),
    description: z.string(),
    blurb: z.string(),
    hasDoc: z.boolean(),
    category: z.array(z.string()),
    hasReadme: z.boolean(),
    readmeHtml: z.string(),
  }),
});

export const collections = { prompts, plugins, skills };
