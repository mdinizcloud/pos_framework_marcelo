export interface CategoryTreeNode {
  name: string;
  path: string;
  children: CategoryTreeNode[];
  items: { id: string; name: string }[];
}

interface PromptLike {
  id: string;
  data: { name: string; category: string[] };
}

interface MutableNode {
  name: string;
  path: string;
  children: Map<string, MutableNode>;
  items: { id: string; name: string }[];
}

// Agrupa prompts pelos segmentos de pasta em `category` (domínio + tema, ver
// content.config.ts) numa árvore navegável: cada nível de pasta vira um nó,
// prompts ficam nas folhas. Construção 100% via Map (mutação em profundidade é
// sempre segura); a conversão pra array ordenado acontece só no final, numa
// única passada recursiva.
export function buildCategoryTree(prompts: PromptLike[]): CategoryTreeNode[] {
  const root = new Map<string, MutableNode>();

  for (const p of prompts) {
    let level = root;
    let node: MutableNode | undefined;
    let pathAcc: string[] = [];

    for (const segment of p.data.category) {
      pathAcc = [...pathAcc, segment];
      node = level.get(segment);
      if (!node) {
        node = { name: segment, path: pathAcc.join('/'), children: new Map(), items: [] };
        level.set(segment, node);
      }
      level = node.children;
    }

    node?.items.push({ id: p.id, name: p.data.name });
  }

  return freeze(root);
}

// Percorre a árvore seguindo os segmentos de `category` e devolve o nó de
// cada nível (domínio -> ... -> pasta do prompt). Usado pelo breadcrumb pra
// saber, em cada segmento clicado, quais são as pastas/itens logo abaixo dele.
export function findAncestorNodes(tree: CategoryTreeNode[], category: string[]): CategoryTreeNode[] {
  const result: CategoryTreeNode[] = [];
  let level = tree;
  for (const segment of category) {
    const node = level.find((n) => n.name === segment);
    if (!node) break;
    result.push(node);
    level = node.children;
  }
  return result;
}

function freeze(level: Map<string, MutableNode>): CategoryTreeNode[] {
  return Array.from(level.values())
    .map((n) => ({
      name: n.name,
      path: n.path,
      children: freeze(n.children),
      items: [...n.items].sort((a, b) => a.name.localeCompare(b.name)),
    }))
    .sort((a, b) => a.name.localeCompare(b.name));
}
