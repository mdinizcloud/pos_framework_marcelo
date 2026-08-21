export interface CategoryTreeNode {
  name: string;
  path: string;
  pluginId?: string;
  children: CategoryTreeNode[];
  skills: { id: string; name: string; hasDoc: boolean }[];
}

interface SkillLike {
  id: string;
  data: { name: string; hasDoc: boolean; category: string[] };
}

interface MutableNode {
  name: string;
  path: string;
  pluginId?: string;
  children: Map<string, MutableNode>;
  skills: { id: string; name: string; hasDoc: boolean }[];
}

// Agrupa skills pelos segmentos de pasta em `category` (ver content.config.ts)
// numa árvore navegável: cada nível de pasta vira um nó, skills ficam nas folhas.
// Construção 100% via Map (mutação em profundidade é sempre segura); a conversão
// pra array ordenado acontece só no final, numa única passada recursiva.
// `pluginPathToId` (opcional) mapeia o `path` de uma pasta pro id de um plugin
// composto (ex.: "observabilidade/sre-stack" -> "sre-stack") — a pasta ganha
// `pluginId`, usado pra linkar o nome dela pra /plugins/[id] na sidebar.
export function buildCategoryTree(skills: SkillLike[], pluginPathToId?: Map<string, string>): CategoryTreeNode[] {
  const root = new Map<string, MutableNode>();

  for (const s of skills) {
    let level = root;
    let node: MutableNode | undefined;
    let pathAcc: string[] = [];

    for (const segment of s.data.category) {
      pathAcc = [...pathAcc, segment];
      node = level.get(segment);
      if (!node) {
        const nodePath = pathAcc.join('/');
        node = { name: segment, path: nodePath, pluginId: pluginPathToId?.get(nodePath), children: new Map(), skills: [] };
        level.set(segment, node);
      }
      level = node.children;
    }

    node?.skills.push({ id: s.id, name: s.data.name, hasDoc: s.data.hasDoc });
  }

  return freeze(root);
}

// Acha o nó da árvore correspondente a um caminho de segmentos (ex.: ['devops', 'iac']).
// Usado pelo breadcrumb pra saber quais subpastas/skills mostrar no menu de cada segmento.
export function findCategoryNode(tree: CategoryTreeNode[], path: string[]): CategoryTreeNode | undefined {
  let nodes = tree;
  let node: CategoryTreeNode | undefined;
  for (const segment of path) {
    node = nodes.find((n) => n.name === segment);
    if (!node) return undefined;
    nodes = node.children;
  }
  return node;
}

function freeze(level: Map<string, MutableNode>): CategoryTreeNode[] {
  return Array.from(level.values())
    .map((n) => ({
      name: n.name,
      path: n.path,
      pluginId: n.pluginId,
      children: freeze(n.children),
      skills: [...n.skills].sort((a, b) => a.name.localeCompare(b.name)),
    }))
    .sort((a, b) => a.name.localeCompare(b.name));
}
