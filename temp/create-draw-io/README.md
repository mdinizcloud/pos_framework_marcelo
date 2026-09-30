# create-draw-io

## 🎯 Propósito & Escopo
Gera arquivos `.drawio` (mxGraph XML) autorais do zero via script Python, com ícones oficiais reais de cada tecnologia (Azure, CNCF, Kubernetes, brand kit de cada projeto) embutidos como data URI e tema escuro que sobrevive à abertura no editor real — sem depender de baixar o app draw.io nem editar manualmente na UI.

## 🌟 Para que ela é útil?
Existe porque três coisas que "deveriam simplesmente funcionar" no mxGraph (embutir ícone SVG, embutir ícone PNG, fundo escuro) quebram silenciosamente — sem mensagem de erro, só um ícone genérico quebrado ou um fundo branco teimoso — e cada uma tem um fix específico descoberto lendo o `app.min.js` real. A skill encapsula os três fixes num módulo reutilizável (`drawio_builder.py`) e um verificador de renderização real (`render_check.py`), evitando reproduzir a mesma investigação por tentativa e erro a cada diagrama novo.

## 🛠️ Como usar?
- Pedir um diagrama de arquitetura em formato .drawio/diagrams.net, ícones "oficiais" de alguma tecnologia embutidos, ou fundo escuro/dark mode num .drawio
- Reportar que um .drawio gerado abre com ícones quebrados ou fundo errado
- Usar o módulo diretamente: `import drawio_builder as db` (após `sys.path.insert(0, "<path>/scripts")`), chamando `db.rect_bg()`, `db.group()`, `db.icon()`, `db.dot()`, `db.edge()`, `db.text()`, `db.render_mxfile()`
- Verificar antes de entregar: `python3 scripts/render_check.py caminho/diagrama.drawio -o preview.png`

## ⏳ Quando usar?
- O formato pedido é especificamente `.drawio`/diagrams.net (não SVG estático — para isso, usar a skill `criar-arquitetura`)
- O usuário quer ícones oficiais embutidos, não um placeholder genérico
- Um `.drawio` já entregue está com problema visual (ícone quebrado, fundo errado) e precisa de correção

## ✅ O que fazer?
- Escopar o diagrama antes de codar: componentes, agrupamento em containers lógicos, convenção de cor de seta (verde=ordem de deploy, azul=dependência, laranja=associação lógica)
- Buscar o SVG oficial de cada tecnologia via `references/icon-sourcing.md` antes de desenhar qualquer ícone; salvar em `assets/icons/` com um `SOURCES.md` de proveniência
- Onde não existir ícone oficial rastreável em 2-3 tentativas, usar uma forma genérica (círculo colorido via `db.dot()`) e documentar isso explicitamente
- Montar o XML exclusivamente via `drawio_builder.py` (nunca escrever mxGraph XML à mão)
- Rodar `render_check.py` e ler o PNG resultante antes de entregar ao usuário — os três gotchas falham silenciosamente, "o XML valida" não prova nada
- Se algo ainda estiver errado após a entrega, reler `references/mxgraph-gotchas.md` antes de tentar uma segunda correção às cegas

## 🚫 O que NÃO fazer?
- Não escrever XML mxGraph manualmente — usar sempre `drawio_builder.py`
- Não recriar um logo/ícone à mão nem usar substituto não-oficial
- Não usar base64 puro para embutir ícone SVG (quebra o parser de estilo do mxGraph, que faz `split(";")` cru — Gotcha 1) nem embutir PNG cru sem o wrapper SVG (Gotcha 2)
- Não confiar em `background=` sozinho para fundo escuro — sem `adaptiveColors="none"` junto, fill/fontColor customizados voltam ao claro (Gotcha 3)
- Não entregar ao usuário sem rodar `render_check.py` antes — exceto se a extensão VS Code não for encontrada localmente, caso em que é preciso avisar explicitamente que não foi possível verificar, nunca fingir que verificou
- Não gerar SVG estático nesta skill — isso é escopo de `criar-arquitetura`

## 📥 Parâmetros de Entrada (Inputs)
- `drawio_builder.py` — funções recebem coordenadas, cores, paths de ícone e labels (ex.: `icon(path, cx, cy, size, label1=None, label2=None, ...)`, `edge(x1, y1, x2, y2, color, label=None, control=None, bg=...)`); `render_mxfile(page_width=1500, page_height=1200, background="#0d1117", diagram_name="Diagram")` monta o XML final
- `render_check.py drawio_file -o output.png [--width] [--height] [--viewer-js] [--bg]` — path do `.drawio` (obrigatório), demais opcionais

## 📤 Estrutura de Saída (Outputs)
- String XML `.drawio` retornada por `render_mxfile()`, escrita pelo usuário do módulo via `open(...).write(xml)` — a skill não fixa um caminho de saída
- PNG de verificação (`preview.png` por padrão) gerado por `render_check.py`, screenshot real via Chromium headless renderizando com o `viewer.min.js` da extensão VS Code `hediet.vscode-drawio`

## 🔧 Dependências & Ferramentas
- Extensão VS Code `hediet.vscode-drawio` instalada localmente — fornece `viewer.min.js`/`app.min.js` offline (engine real de renderização, sem internet nem app aberto)
- Binário `chromium`/`chromium-browser`/`google-chrome`/`google-chrome-stable` no PATH, para o screenshot headless
- Sem API externa para geração do XML; busca de ícones oficiais usa `curl`/API do GitHub (documentado em `references/icon-sourcing.md`) e é read-only

## 💡 Casos de Uso Reais
Não há exemplo concreto de prompt/resposta no SKILL.md — o arquivo descreve o workflow em 5 passos genéricos (escopar, buscar ícones, montar XML, verificar, corrigir) sem transcrição de uma interação real.

## ⚠️ Tratamento de Erros
- `render_check.py` não encontra `viewer.min.js`: imprime erro em stderr e sai com código 1, pedindo para instalar a extensão ou passar `--viewer-js`
- Nenhum binário chromium encontrado no PATH: erro em stderr, saída com código 1
- Extensão de ícone não suportada (`data_uri()` em `drawio_builder.py`): levanta `ValueError(f"unsupported icon type: {path}")`
- Chromium rodando como snap não enxerga `/tmp` do sistema — sintoma documentado é um screenshot "plausível" (retângulo escuro da própria página de erro do Chromium) em vez de falha explícita; `render_check.py` já contorna isso preparando o HTML temporário sob `~/render_check_tmp` em vez de `/tmp`
- Se a extensão VS Code não for encontrada, o SKILL.md instrui explicitamente a pular a verificação e avisar o usuário — não fingir que verificou
