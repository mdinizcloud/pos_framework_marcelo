# Onde achar ícone oficial de cada tecnologia

Fontes verificadas nessa investigação. Preferir sempre o SVG oficial (não recriar
o ícone à mão, não usar substituto genérico) — onde não existir asset rastreável,
usar forma genérica (círculo colorido) em vez de logo não-oficial.

## Azure

Microsoft não distribui as Azure Architecture Icons como zip individual por ícone
fácil de baixar via `curl` (só um zip gigante com milhares de ícones). Mirror
verbatim (mesmo arquivo, sem modificação) mais prático pra pegar 1-2 ícones
específicos:

```
https://raw.githubusercontent.com/benc-uk/icon-collection/master/azure-icons/<Nome-Do-Recurso>.svg
```

Nome do arquivo bate com o nome do recurso no Portal Azure, kebab/Pascal com
hífen: `Virtual-Networks.svg`, `Kubernetes-Services.svg`, `Key-Vaults.svg`,
`Users.svg`, `Public-IP-Addresses.svg`. Pra achar o nome exato, listar o diretório
via API do GitHub antes de tentar o raw:

```bash
curl -sL "https://api.github.com/repos/benc-uk/icon-collection/contents/azure-icons" \
  | python3 -c "import json,sys; print([i['name'] for i in json.load(sys.stdin)])"
```

Licença: uso permitido em diagrama de arquitetura conforme
[termos da Microsoft](https://learn.microsoft.com/en-us/azure/architecture/icons/)
— não recolorir/distorcer fora do padrão, não usar ícone de produto Azure pra
representar produto próprio.

## Projetos CNCF (Istio, ArgoCD, Prometheus, Jaeger, cert-manager, KEDA, Chaos Mesh,
## OpenTelemetry, Kubernetes)

Todos ficam no mesmo repo, mesma estrutura:

```
https://raw.githubusercontent.com/cncf/artwork/main/projects/<slug>/icon/color/<slug>-icon-color.svg
```

`<slug>` geralmente bate com o nome do projeto, mas nem sempre — checar antes:

```bash
curl -sL "https://api.github.com/repos/cncf/artwork/contents/projects" \
  | python3 -c "import json,sys; print([n['name'] for n in json.load(sys.stdin)])"
```

Exceções encontradas: **Chaos Mesh** fica em `projects/chaosmesh` (sem hífen), não
`chaos-mesh`. **ArgoCD** usa o logo genérico do "Argo Project" em
`projects/argo/icon/color/argo-icon-color.svg` (cobre Argo CD, Argo Workflows etc,
não tem logo específico só de ArgoCD).

## Recursos Kubernetes (Namespace, NetworkPolicy, ResourceQuota, etc.)

Ícone oficial de recurso (não o logo do projeto) fica em:

```
https://raw.githubusercontent.com/kubernetes/community/main/icons/svg/resources/labeled/<abrev>.svg
```

Abreviações curtas: `ns.svg` (Namespace), `netpol.svg` (NetworkPolicy), `quota.svg`
(ResourceQuota), `psp.svg` (PodSecurityPolicy — deprecated mas é o mais próximo de
"admission control" disponível no set, útil como aproximação pra
ValidatingAdmissionPolicy se não existir ícone dedicado ainda). Listar o diretório
antes de assumir o nome do arquivo.

## Projetos sem CNCF/Azure (caso a caso)

Cada um tem seu próprio repo de brand assets — sempre dar uma passada rápida pela
API do GitHub em vez de adivinhar caminho:

| Projeto | Caminho encontrado |
|---|---|
| Grafana | `raw.githubusercontent.com/grafana/grafana/main/public/img/grafana_icon.svg` |
| Loki | só existe `.png` no repo oficial (`grafana/loki/main/docs/sources/logo.png`), sem SVG — ver Gotcha 2 no `mxgraph-gotchas.md` pra embutir PNG |
| Kiali | `raw.githubusercontent.com/kiali/kiali.io/staging/assets/icons/logo.svg` — repare que é a branch `staging`, não `main`/`master` |
| External Secrets | `raw.githubusercontent.com/external-secrets/external-secrets/main/assets/eso-icon.svg` |
| Terraform | HashiCorp Design System (Flight Icons): `raw.githubusercontent.com/hashicorp/design-system/main/packages/flight-icons/svg-original/terraform-color-24.svg` |

## Estratégia de busca quando não sabe o repo

1. `curl -sL "https://api.github.com/search/repositories?q=<projeto>+icon"` ou
   `+brand+assets` pra achar o repo certo.
2. Uma vez achado o repo, listar diretórios via API (`contents/<path>`) em vez de
   tentar caminhos de raw às cegas — economiza rodadas de 404.
3. Confirmar branch padrão antes de montar URLs raw em lote — nem todo repo usa
   `main` (kiali.io usa `staging`; alguns antigos ainda usam `master`).
4. Se não achar nada em ~2-3 tentativas de busca, documentar como "sem ícone
   oficial rastreável" e usar forma genérica — não forçar um substituto.

## Registro de proveniência

Todo ícone baixado deve ser commitado com um `SOURCES.md` ao lado listando, por
arquivo: componente que representa, URL de origem, licença/termo de uso. Exemplo
de formato usado nessa investigação: `docs/assets/icons/SOURCES.md` no repo
quasar-azure — reaproveitar essa estrutura de tabela.
