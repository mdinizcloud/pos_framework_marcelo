# Arquitetura

## Modelo

Terraform + Terragrunt. State remoto **dividido por componente** (não um state central).
Cada componente é um root Terraform próprio, com state e lock isolados no bucket.

## Categorias e componentes (ordem de dependência)

```
cloud/network  →  cloud/cluster  →  cloud/workloads
```

- **network** — rede base (VPC/VNet, subnets). Sem dependência.
- **cluster** — cluster gerenciado (EKS/AKS/GKE). Depende de `network`.
- **workloads** — deploy in-cluster (namespaces, Helm, manifests). Depende de `cluster`;
  usa providers `kubernetes`/`helm` configurados com credenciais que saem do `cluster`.

`cloud` é a categoria — só um nível de path em `modules/`/`environments/<env>/`, nunca um
módulo em si (sem `main.tf`/`module{}` próprio). Categorias novas (`observabilidade`,
`seguranca`, `apps`, ...) nascem sob demanda, mesma regra. Nenhum módulo chama outro módulo
local (`source = "./..."`) dentro de `modules/` — árvore sempre flat, 1 nível.

Componentes opcionais (só quando o projeto pedir), cada um na categoria que fizer sentido:
`data`, `dns`, `identity`, `observabilidade/*`, `seguranca/*`, `apps/<nome-do-app>`.

## State

`<bucket-da-categoria>/<projeto>/environments/<env>/<categoria>/<componente>/terraform.tfstate`

Um state por componente-folha por ambiente (nunca por categoria) → blast radius pequeno, lock e
permissão por componente. Um **bucket por categoria** (`<projeto>-tfstate-<categoria>`) — meio
termo entre 1 bucket único (sem isolamento) e 1 bucket por componente-folha (multiplica sem
parar). A dependência entre componentes é explícita via `dependency` do Terragrunt (substitui
`terraform_remote_state`).

## Decisões (ADR resumido)

- **State split por componente** (não monolito): menor blast radius, plan/apply rápido.
- **Terragrunt**: `run --all` aplica na ordem por grafo; backend/provider gerados 1x. Sempre com
  `--parallelism 1` — nunca rodar `run --all` sem essa flag.
- **Backend remoto** (não local): lock + backup + acesso multi-operador/CI.
- **Ambiente = diretório** (não workspace): sem seleção implícita, sem aplicar no env errado.
- **Provider `~>` + `.terraform.lock.hcl` commitado**: sempre última versão, reprodutível, sem legado.

<!-- TODO: incluir diagrama e ADRs específicos do projeto. -->
