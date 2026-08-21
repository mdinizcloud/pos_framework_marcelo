export interface PromptCategoryTreeNode {
  name: string;
  path: string;
  children: PromptCategoryTreeNode[];
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

// Porta de prompt_registry/.site/src/lib/tree.ts — agrupa prompts pelos segmentos
// de pasta em `category` numa árvore navegável (cada nível de pasta vira um nó,
// prompts ficam nas folhas). Renomeado pra `promptTree.ts`/prefixo `Prompt*` porque
// este mesmo app já tem um `lib/tree.ts` equivalente pra skills (campo `skills` em
// vez de `items`) — mantidos como módulos irmãos, sem tentar unificar os dois shapes.
export function buildPromptTree(prompts: PromptLike[]): PromptCategoryTreeNode[] {
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
// cada nível. Usado pelo breadcrumb pra saber, em cada segmento clicado, quais
// são as pastas/itens logo abaixo dele.
export function findPromptAncestorNodes(tree: PromptCategoryTreeNode[], category: string[]): PromptCategoryTreeNode[] {
  const result: PromptCategoryTreeNode[] = [];
  let level = tree;
  for (const segment of category) {
    const node = level.find((n) => n.name === segment);
    if (!node) break;
    result.push(node);
    level = node.children;
  }
  return result;
}

function freeze(level: Map<string, MutableNode>): PromptCategoryTreeNode[] {
  return Array.from(level.values())
    .map((n) => ({
      name: n.name,
      path: n.path,
      children: freeze(n.children),
      items: [...n.items].sort((a, b) => a.name.localeCompare(b.name)),
    }))
    .sort((a, b) => a.name.localeCompare(b.name));
}
