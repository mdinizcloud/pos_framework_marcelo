import { defineCollection, reference, z } from 'astro:content';
import type { Loader } from 'astro/loaders';
import { readFile, readdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import matter from 'gray-matter';
import { site } from './site.config';

// ---------------------------------------------------------------------------
// Regra de higiene (ver plano): NUNCA globar recursivamente. Os arquivos reais
// vivem em profundidade fixa; qualquer coisa mais funda é lixo (.venv, snapshots,
// outputs de eval). Por isso lemos diretórios em níveis exatos com fs, não glob.
//   marketplace: <repo>/.claude/marketplace.json — cada entrada em "plugins" tem
//     {name, source, description}; "source" é o caminho da skill relativo ao repo
//     (ex.: "./skill-meta/catalogacao/catalogar-skill"). Sem pasta plugins/ própria:
//     1 entrada do marketplace = 1 skill, lida direto de <repo>/<source>/SKILL.md.
//   "doc" da skill = o próprio corpo do SKILL.md (sem frontmatter) — não existe
//   arquivo de doc separado.
//   README.md (opcional) — se existir direto em <source>/README.md, é lido e
//   exposto como resumo adicional (hasReadme/readmeHtml), renderizado à parte
//   do corpo do SKILL.md — não substitui o "doc" acima.
// ---------------------------------------------------------------------------

function repoRootFrom(configRoot: URL): string {
  // configRoot aponta para .../site/ ; o repo é o pai.
  return fileURLToPath(new URL('../', configRoot));
}

// Repo irmão prompt_registry (fora deste repo, em /data/ssd_main/github/prompt_registry
// no disco deste usuário) — servido pela seção /prompts do mesmo processo Astro.
// Nenhum conteúdo é copiado pra cá: lido ao vivo via fs, igual ao skillsLoader abaixo.
function promptsRepoRootFrom(configRoot: URL): string {
  return path.resolve(repoRootFrom(configRoot), '..', 'prompt_registry');
}

// Extrai um resumo curto do doc: o texto entre o H1 e o primeiro H2.
// Fallback: primeiro parágrafo não-vazio que não seja heading.
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
      if (collected.length > 0) break; // fim do primeiro parágrafo
      continue;
    }
    if (line.startsWith('#')) continue;
    collected.push(line);
  }
  return collected.join(' ').trim();
}

// Extrai a frase de propósito do README.md (seção "## 🎯 Propósito & Escopo",
// gerada por catalogar-skill/skill-creator para toda skill) — é a fonte mais
// direta e confiável de "objetivo principal em poucas palavras" que temos,
// bem mais estável que tentar adivinhar a partir da estrutura do SKILL.md.
function extractPurpose(markdown: string): string {
  const body = matter(markdown).content;
  const marker = body.match(/^##\s*(?:🎯\s*)?Propósito\s*&\s*Escopo\s*$/m);
  if (!marker || marker.index === undefined) return '';
  const after = body.slice(marker.index + marker[0].length);
  const nextHeading = after.search(/\n##\s/);
  const section = nextHeading === -1 ? after : after.slice(0, nextHeading);
  return section
    .replace(/\*\*(.+?)\*\*/g, '$1') // desfaz negrito markdown
    .replace(/\*(.+?)\*/g, '$1') // desfaz itálico markdown
    .replace(/`([^`]+)`/g, '$1') // desfaz crase de código
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

// Pastas que nunca são, nem contêm, uma skill própria — usadas tanto pra parar
// a busca recursiva por SKILL.md aninhado (plugin composto) quanto pra evitar
// descer dentro de uma skill já encontrada (scripts/references/assets).
const NON_SKILL_DIRS = new Set([
  '.git', '.claude-plugin', '.agents', 'docs', 'node_modules', '.venv',
  'scripts', 'references', 'assets',
]);

// Busca recursiva por diretórios que contêm SKILL.md direto, usada quando o
// `source` de uma entrada do marketplace não tem SKILL.md na raiz — nesse caso
// é um "plugin composto" (ex.: sre-stack) que agrupa N skills em subpastas.
// Para de descer assim que acha um SKILL.md (não entra em scripts/ etc. dela).
async function findSkillDirs(dir: string): Promise<string[]> {
  if (existsSync(path.join(dir, 'SKILL.md'))) return [dir];
  const found: string[] = [];
  const entries = await readdir(dir, { withFileTypes: true });
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    if (entry.name.startsWith('.') && entry.name !== '.') continue;
    if (NON_SKILL_DIRS.has(entry.name)) continue;
    found.push(...(await findSkillDirs(path.join(dir, entry.name))));
  }
  return found;
}

// Arquivos .md na raiz do plugin que já têm tratamento próprio ou são meta
// (instruções pro agente, não doc pro usuário) — nunca entram na lista de
// "outros .md" da página do plugin.
const EXTRA_DOC_SKIP_FILENAMES = new Set(['README.md', 'SKILL.md', 'CLAUDE.md', 'AGENTS.md']);

// Lê e renderiza todo .md solto na raiz do plugin (exceto os da lista acima)
// mais todo .md dentro de docs/, se existir — usado na página do plugin pra
// mostrar CHANGELOG/INSTALL/COMO-USAR/docs de referência, sempre depois do
// README e do grid de skills.
async function readExtraDocs(
  skillDir: string,
  sourceRel: string,
  config: { root: URL },
  renderMarkdown: (md: string, opts: { fileURL: URL }) => Promise<{ html: string }>,
): Promise<{ filename: string; html: string }[]> {
  const docs: { filename: string; html: string }[] = [];

  const rootEntries = await readdir(skillDir, { withFileTypes: true });
  for (const entry of rootEntries) {
    if (!entry.isFile() || !entry.name.endsWith('.md')) continue;
    if (EXTRA_DOC_SKIP_FILENAMES.has(entry.name)) continue;
    const raw = await readFile(path.join(skillDir, entry.name), 'utf8');
    const rendered = await renderMarkdown(raw, { fileURL: new URL(`${sourceRel}/${entry.name}`, config.root) });
    docs.push({ filename: entry.name, html: rendered.html });
  }

  const docsDir = path.join(skillDir, 'docs');
  if (existsSync(docsDir)) {
    const docsEntries = await readdir(docsDir, { withFileTypes: true });
    for (const entry of docsEntries) {
      if (!entry.isFile() || !entry.name.endsWith('.md')) continue;
      const raw = await readFile(path.join(docsDir, entry.name), 'utf8');
      const rendered = await renderMarkdown(raw, { fileURL: new URL(`${sourceRel}/docs/${entry.name}`, config.root) });
      docs.push({ filename: `docs/${entry.name}`, html: rendered.html });
    }
  }

  // CHANGELOG.md sempre por último — histórico de mudanças é o menos relevante
  // pra quem tá conhecendo o plugin, deixa pro final da lista de leitura.
  docs.sort((a, b) => {
    const aLast = path.basename(a.filename) === 'CHANGELOG.md';
    const bLast = path.basename(b.filename) === 'CHANGELOG.md';
    return aLast === bLast ? 0 : aLast ? 1 : -1;
  });

  return docs;
}

// --- Loader: plugins (grupos) -------------------------------------------------
function pluginsLoader(): Loader {
  return {
    name: 'marketplace-plugins',
    async load({ store, parseData, renderMarkdown, config }) {
      const repo = repoRootFrom(config.root);

      async function sync() {
        const plugins = await readMarketplace(repo);
        store.clear();
        for (const p of plugins) {
          const sourceRel = p.source.replace(/^\.\//, '');
          const skillDir = path.join(repo, sourceRel);
          // Plugin composto = source sem SKILL.md direto, agrupando N skills
          // em subpastas (ex.: sre-stack). Só esses ganham link na árvore lateral.
          const compound = !existsSync(path.join(skillDir, 'SKILL.md'));

          // Manifest próprio de plugin Claude Code (.claude-plugin/) — só quando
          // presente é que existem os comandos "direto do repositório"
          // (--plugin-dir / plugin marketplace add), que exigem checkout local
          // e não fazem sentido pra uma entrada que é só uma skill solta.
          const claudePluginJsonPath = path.join(skillDir, '.claude-plugin', 'plugin.json');
          const claudeMarketplaceJsonPath = path.join(skillDir, '.claude-plugin', 'marketplace.json');
          const hasClaudePlugin = existsSync(claudePluginJsonPath) && existsSync(claudeMarketplaceJsonPath);
          let claudePluginRef = '';
          if (hasClaudePlugin) {
            const pluginName = JSON.parse(await readFile(claudePluginJsonPath, 'utf8')).name ?? p.name;
            const marketplaceName = JSON.parse(await readFile(claudeMarketplaceJsonPath, 'utf8')).name ?? p.name;
            claudePluginRef = `${pluginName}@${marketplaceName}`;
          }
          const localPath = `${site.repo.localPath}/${sourceRel}`;

          const readmePath = path.join(skillDir, 'README.md');
          const hasReadme = existsSync(readmePath);
          let readmeHtml = '';
          if (hasReadme) {
            const readmeRaw = await readFile(readmePath, 'utf8');
            const readmeRendered = await renderMarkdown(readmeRaw, {
              fileURL: new URL(`${sourceRel}/README.md`, config.root),
            });
            readmeHtml = readmeRendered.html;
          }

          const extraDocs = existsSync(skillDir) ? await readExtraDocs(skillDir, sourceRel, config, renderMarkdown) : [];

          const data = await parseData({
            id: p.name,
            data: {
              name: p.name,
              description: p.description,
              version: '',
              installCommand: `npx skills add ${site.repo.slug}/${sourceRel}`,
              compound,
              sourcePath: sourceRel,
              hasReadme,
              readmeHtml,
              extraDocs,
              hasClaudePlugin,
              claudePluginRef,
              localPath,
            },
          });
          store.set({ id: p.name, data });
        }
      }

      await sync();
    },
  };
}

// --- Loader: skills (itens, protagonistas) -----------------------------------
function skillsLoader(): Loader {
  return {
    name: 'marketplace-skills',
    async load({ store, parseData, renderMarkdown, config }) {
      const repo = repoRootFrom(config.root);

      async function sync() {
        const plugins = await readMarketplace(repo);
        store.clear();
        const seen = new Set<string>();

        for (const p of plugins) {
          const pluginSourceRel = p.source.replace(/^\.\//, '');
          const pluginDir = path.join(repo, pluginSourceRel);
          if (!existsSync(pluginDir)) continue; // entrada órfã do marketplace (pasta removida/renomeada)

          // Source com SKILL.md direto = 1 skill; sem SKILL.md direto = plugin
          // composto (ex.: sre-stack), busca recursiva por todas as skills aninhadas.
          const skillDirs = existsSync(path.join(pluginDir, 'SKILL.md'))
            ? [pluginDir]
            : await findSkillDirs(pluginDir);

          for (const skillDir of skillDirs) {
            const skillMd = path.join(skillDir, 'SKILL.md');
            const sourceRel = path.relative(repo, skillDir);
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
              ? await renderMarkdown(fm.content, { fileURL: new URL(`${sourceRel}/SKILL.md`, config.root) })
              : undefined;

            const category = sourceRel.split('/').slice(0, -1); // segmentos de pasta até a skill

            const readmePath = path.join(skillDir, 'README.md');
            const hasReadme = existsSync(readmePath);
            let readmeHtml = '';
            let readmeRaw = '';
            if (hasReadme) {
              readmeRaw = await readFile(readmePath, 'utf8');
              const readmeRendered = await renderMarkdown(readmeRaw, {
                fileURL: new URL(`${sourceRel}/README.md`, config.root),
              });
              readmeHtml = readmeRendered.html;
            }

            // Card blurb: prioriza a frase de propósito do README (curta, direta,
            // sempre presente); cai pro trecho extraído do SKILL.md; nunca fica em
            // branco — pior caso, usa a description do frontmatter truncada.
            const purpose = hasReadme ? extractPurpose(readmeRaw) : '';
            const skillBlurb = hasDoc ? extractBlurb(raw) : '';
            const blurb = purpose || skillBlurb || (description.length > 180 ? `${description.slice(0, 177)}…` : description);

            const data = await parseData({
              id: skillId,
              data: { name, plugin: p.name, description, blurb, hasDoc, category, hasReadme, readmeHtml },
            });
            store.set({ id: skillId, data, rendered });
          }
        }
      }

      await sync();
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
    compound: z.boolean(),
    sourcePath: z.string(),
    hasReadme: z.boolean(),
    readmeHtml: z.string(),
    extraDocs: z.array(z.object({ filename: z.string(), html: z.string() })),
    hasClaudePlugin: z.boolean(),
    claudePluginRef: z.string(),
    localPath: z.string(),
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

// ---------------------------------------------------------------------------
// Prompts (seção /prompts) — porta de prompt_registry/.site/src/content.config.ts,
// lendo do repo irmão via promptsRepoRootFrom em vez do próprio repo.
// ---------------------------------------------------------------------------

const PROMPT_SKIP_DIRS = new Set([
  '.claude', '.obsidian', '.trash', '.git', '.site', 'node_modules', '.venv',
  'golden', 'inputs', 'judge-prompts', 'result', 'outputs',
]);
const PROMPT_SKIP_FILENAMES = new Set(['README.md', 'MAP.md', 'EVAL.md', 'RUN.md', 'CLAUDE.md', 'DIR.md', 'AGENTS.md']);

async function listPromptDomains(repo: string): Promise<string[]> {
  const entries = await readdir(repo, { withFileTypes: true });
  return entries
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .filter((name) => !name.startsWith('.') && !PROMPT_SKIP_DIRS.has(name) && name !== 'assets' && name !== 'tools');
}

interface FoundPrompt {
  absPath: string;
  relPath: string;
}

async function walkForPrompts(repo: string, dir: string, acc: FoundPrompt[]): Promise<void> {
  const entries = await readdir(dir, { withFileTypes: true });
  for (const entry of entries) {
    if (entry.name.startsWith('.')) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (PROMPT_SKIP_DIRS.has(entry.name)) continue;
      await walkForPrompts(repo, full, acc);
    } else if (entry.isFile() && entry.name.endsWith('.md') && !PROMPT_SKIP_FILENAMES.has(entry.name)) {
      acc.push({ absPath: full, relPath: path.relative(repo, full).replace(/\.md$/, '') });
    }
  }
}

function promptsLoader(): Loader {
  return {
    name: 'registry-prompts',
    async load({ store, parseData, renderMarkdown, config }) {
      const repo = promptsRepoRootFrom(config.root);

      async function sync() {
        const domains = await listPromptDomains(repo);

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
              console.warn(`[registry-prompts] frontmatter YAML inválido em ${relPath}.md, pulando: ${(err as Error).message}`);
              continue;
            }
            const nome = fm.data.nome as string | undefined;
            if (!nome) continue;

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
            const category = segments.slice(0, -1);
            const filename = path.basename(absPath);

            const rendered = await renderMarkdown(fm.content, {
              fileURL: new URL(`file://${absPath}`),
            });

            const readmePath = path.join(path.dirname(absPath), 'README.md');
            const hasReadme = existsSync(readmePath);
            let readmeHtml = '';
            if (hasReadme) {
              const readmeRaw = await readFile(readmePath, 'utf8');
              const readmeRendered = await renderMarkdown(readmeRaw, {
                fileURL: new URL(`file://${readmePath}`),
              });
              readmeHtml = readmeRendered.html;
            }

            const id = relPath;

            const data = await parseData({
              id,
              data: { name: nome, descricao, versao, tags, inputs, domain: domainName, category, filename, relPath, hasReadme, readmeHtml, raw: fm.content.trim() },
            });
            store.set({ id, data, rendered });
          }
        }
      }

      await sync();
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

export const collections = { plugins, skills, prompts };
