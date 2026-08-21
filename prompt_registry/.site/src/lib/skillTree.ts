export interface SkillCategoryTreeNode {
  name: string;
  path: string;
  children: SkillCategoryTreeNode[];
  skills: { id: string; name: string; hasDoc: boolean }[];
}

interface SkillLike {
  id: string;
  data: { name: string; hasDoc: boolean; category: string[] };
}

interface MutableNode {
  name: string;
  path: string;
  children: Map<string, MutableNode>;
  skills: { id: string; name: string; hasDoc: boolean }[];
}

// Porta de skills_registry/.site/src/lib/tree.ts — agrupa skills pelos segmentos
// de pasta em `category` numa árvore navegável (cada nível de pasta vira um nó,
// skills ficam nas folhas). Renomeado pra `skillTree.ts`/prefixo `Skill*` porque
// este mesmo app já tem um `tree.ts` equivalente pra prompts (campo `items` em
// vez de `skills`) — mantidos como módulos irmãos, sem tentar unificar os dois
// shapes.
export function buildSkillTree(skills: SkillLike[]): SkillCategoryTreeNode[] {
  const root = new Map<string, MutableNode>();

  for (const s of skills) {
    let level = root;
    let node: MutableNode | undefined;
    let pathAcc: string[] = [];

    for (const segment of s.data.category) {
      pathAcc = [...pathAcc, segment];
      node = level.get(segment);
      if (!node) {
        node = { name: segment, path: pathAcc.join('/'), children: new Map(), skills: [] };
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
export function findSkillCategoryNode(
  tree: SkillCategoryTreeNode[],
  path: string[],
): SkillCategoryTreeNode | undefined {
  let nodes = tree;
  let node: SkillCategoryTreeNode | undefined;
  for (const segment of path) {
    node = nodes.find((n) => n.name === segment);
    if (!node) return undefined;
    nodes = node.children;
  }
  return node;
}

function freeze(level: Map<string, MutableNode>): SkillCategoryTreeNode[] {
  return Array.from(level.values())
    .map((n) => ({
      name: n.name,
      path: n.path,
      children: freeze(n.children),
      skills: [...n.skills].sort((a, b) => a.name.localeCompare(b.name)),
    }))
    .sort((a, b) => a.name.localeCompare(b.name));
}
