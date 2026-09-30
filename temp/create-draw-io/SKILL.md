---
name: create-draw-io
description: Cria arquivos .drawio (diagrams.net) autorais com ícones oficiais reais (Azure, CNCF, Kubernetes, brand kit de cada projeto) embutidos e tema escuro que sobrevive ao abrir no editor de verdade. Use sempre que o usuário pedir um diagrama de arquitetura em draw.io/diagrams.net, pedir pra usar "ícones oficiais" de alguma tecnologia num diagrama, pedir fundo escuro/dark mode num .drawio, ou reportar que um .drawio gerado abre com ícones quebrados/fundo errado. Não é sobre editar diagramas manualmente na UI do draw.io — é sobre gerar o XML programaticamente. Para SVG (estático ou pra embutir em Markdown), usar a skill criar-arquitetura em vez desta.
---

# Create .drawio (diagrams.net)

## Overview

Gera arquivos `.drawio` (mxGraph XML) do zero, via script Python, com ícones
oficiais reais de cada tecnologia embutidos como data URI e tema escuro — sem
depender de baixar a app draw.io nem de mexer na UI manualmente. Existe porque três
coisas que "deveriam simplesmente funcionar" (embutir SVG, embutir PNG, fundo
escuro) têm cada uma um jeito específico de quebrar silenciosamente no mxGraph, sem
mensagem de erro nenhuma — só um ícone genérico quebrado ou um fundo branco teimoso.
Ver `references/mxgraph-gotchas.md` pro porquê de cada uma antes de reinventar a
roda.

## Workflow

### 1. Escopar o diagrama

Decidir: quais componentes/nós, como agrupam (containers lógicos), que setas
conectam o quê e com que significado (ex: verde=ordem de deploy, azul=dependência,
laranja=associação lógica — convenção útil pra qualquer diagrama de arquitetura
com mais de uma categoria de relação). Se o usuário já tem uma imagem de
referência (screenshot, diagrama existente), replicar layout/paleta dela é mais
confiável do que desenhar do zero.

### 2. Buscar os ícones oficiais

Pra cada nó que representa uma tecnologia real (não um conceito genérico), buscar o
SVG oficial — nunca recriar o ícone à mão nem usar um substituto não-oficial. Ver
`references/icon-sourcing.md` pra fontes verificadas (Azure, projetos CNCF,
recursos Kubernetes, e o processo de busca quando a tecnologia não está nessa
lista). Salvar os arquivos baixados num diretório do repo (ex: `assets/icons/`) com
um `SOURCES.md` documentando origem + licença de cada um — nada de asset sem
proveniência rastreável.

Onde não existir ícone oficial encontrável em 2-3 tentativas de busca, usar uma
forma genérica (círculo colorido) em vez de forçar um logo não-oficial — documentar
isso explicitamente em vez de deixar como se fosse esquecimento.

### 3. Montar o XML com `scripts/drawio_builder.py`

Não escrever mxGraph XML à mão — usar o módulo `drawio_builder.py`, que já
encapsula os três gotchas (encoding de ícone SVG, wrap de PNG, atributos de fundo
escuro). Padrão de uso:

```python
import sys
sys.path.insert(0, "<path-to-this-skill>/scripts")
import drawio_builder as db

db.rect_bg(0, 0, 1500, 1200, "#0d1117")          # fundo, redundância barata
db.group(40, 240, 340, 320, "Infra", fill="#161b22", stroke="#30363d")
db.icon("assets/icons/aks.svg", cx=115, cy=305, size=48, label1="aks", label2="v1.30")
db.dot(105, 725, 18, "#43a047", label="Serviço sem ícone oficial")
db.edge(75, 175, 75, 238, "#3fb950", label="deploy")

xml = db.render_mxfile(page_width=1500, page_height=1200, background="#0d1117",
                        diagram_name="Minha Arquitetura")
open("docs/architecture.drawio", "w").write(xml)
```

Layout: pensar em containers (grupos) primeiro, depois posicionar ícones dentro
deles por coordenada absoluta — mxGraph não tem layout automático tipo flexbox,
então é tentativa visual (renderizar, olhar, ajustar `cx`/`cy`).

Se o pedido também incluir um SVG (estático, pra embutir em Markdown/README já
que GitHub não renderiza `.drawio` nativamente): isso é escopo da skill
`criar-arquitetura`, não desta — gerar o SVG lá com `svg_builder.py`, separado
deste `.drawio`.

### 4. Verificar ANTES de entregar

Nunca mandar pro usuário testar um `.drawio` sem renderizar você mesmo primeiro —
os três gotchas falham de forma silenciosa (sem erro, só resultado visual errado),
então "o XML valida" não prova nada sobre como vai renderizar de verdade.

```bash
python3 <this-skill>/scripts/render_check.py caminho/diagrama.drawio -o preview.png
```

Isso usa o engine real do draw.io (via a extensão VS Code `hediet.vscode-drawio`,
se instalada — offline, sem precisar de internet nem do app aberto) pra tirar um
print de verdade. Ler o PNG resultante (`Read` tool) e conferir: ícones aparecendo
(não ícone genérico quebrado), cores de fundo/preenchimento corretas, texto legível.
Só depois de confirmar visualmente que está certo, entregar pro usuário.

Se `render_check.py` não achar a extensão VS Code localmente (script avisa), é
aceitável pular esse passo e avisar explicitamente que não foi possível
verificar antes de entregar — não fingir que verificou.

### 5. Se algo ainda estiver errado depois de entregue

Antes de tentar uma segunda correção às cegas: reler
`references/mxgraph-gotchas.md` primeiro — é bem provável que o problema já esteja
catalogado ali (foi descoberto exatamente assim, por tentativa e erro repetida
antes de finalmente ler o código-fonte). Se for algo genuinamente novo, o
código-fonte real (não minificado a ponto de ilegível) está em
`~/.vscode/extensions/hediet.vscode-drawio-*/drawio/src/main/webapp/js/app.min.js`
— `grep` por nome de atributo relevante costuma resolver em minutos o que
tentativa-e-erro não resolve em horas.

## Resources

- `scripts/drawio_builder.py` — módulo Python reutilizável (ícones, grupos, setas,
  texto, render final) já com os três gotchas corrigidos.
- `scripts/render_check.py` — renderiza um `.drawio` pra PNG usando o engine real,
  headless, sem precisar abrir o app.
- `references/mxgraph-gotchas.md` — os três jeitos que embutir ícone/fundo escuro
  quebra silenciosamente no mxGraph, e o porquê de cada fix.
- `references/icon-sourcing.md` — onde achar SVG oficial de Azure, CNCF,
  Kubernetes, e outros projetos, com URLs e ressalvas já verificadas.
