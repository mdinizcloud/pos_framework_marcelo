# mxGraph / .drawio gotchas — descobertos na prática, não na doc oficial

Achados investigando por que um `.drawio` gerado à mão (ícones reais em base64,
fundo escuro) abria com ícones quebrados e fundo branco tanto no VS Code
(`hediet.vscode-drawio`) quanto no app.diagrams.net web — apesar do XML "parecer"
correto e validar como XML bem-formado. As três causas raiz só apareceram lendo o
`app.min.js` real (via a cópia offline embutida na extensão VS Code) e testando
hipóteses com `render_check.py` (engine real, headless) — tentativa e erro cego
levou a pelo menos três "correções" erradas antes disso. Ver seção final.

## Gotcha 1 — style string do mxGraph é `split(";")` cru

O parser de estilo do mxGraph (confirmado lendo `app.min.js`: `a=a.split(";")`)
não tem noção nenhuma de URL, data URI ou aspas — ele corta QUALQUER `;` literal
dentro do valor de uma propriedade. Isso quebra o padrão óbvio de embutir imagem:

```
style="shape=image;image=data:image/svg+xml;base64,AAAA...;imageAspect=1;"
```

O `;` entre `image/svg+xml` e `base64` termina o valor de `image=` ali mesmo — o
resto vira lixo, a imagem não carrega (ícone genérico quebrado).

**Fix**: nada de base64. Faça percent-encoding total do SVG (`urllib.parse.quote(raw,
safe="")`) e monte a URI sem o marcador `;base64,`:

```
data:image/svg+xml,%3Csvg%20xmlns%3D...
```

Isso não tem NENHUM `;` sobrando (todo `;`/`=` do SVG original vira `%3B`/`%3D`),
então o `split(";")` do mxGraph nunca corta no meio. E o navegador entende
`data:image/svg+xml,<texto percent-encoded>` normalmente — não precisa de base64
pra dado textual.

Cuidado com a meia-solução óbvia: `%3Bbase64` (só escapar o `;` mantendo `base64`)
**não funciona** — o parser de `data:` URI do Chromium procura o literal `;base64,`
pra decidir que o resto é base64; `%3Bbase64` não bate com esse padrão e ele trata
o payload como texto puro (quebra igual). Testei os dois lado a lado isolado no
Chromium antes de decidir — ver `render_check.py`.

## Gotcha 2 — PNG/raster não aceita a mesma solução

O truque do Gotcha 1 funciona liso pra SVG (é texto). Pra PNG **não funciona** —
confirmado até com um PNG de 78 bytes: `shape=image` com
`image=data:image/png,<percent-encoded>` (sem base64) simplesmente não carrega,
mesmo a URI sendo 100% válida (a mesma string funciona perfeita numa tag `<img>`
comum fora do mxGraph). O shape de imagem do mxGraph exige base64 pra raster.

**Fix**: embrulhar o PNG num SVG mínimo com a imagem embutida em base64 DENTRO
dele, e aplicar o Gotcha 1 (percent-encoding total) no SVG wrapper, não no PNG cru:

```python
b64 = base64.b64encode(png_bytes).decode()
svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}">' \
      f'<image width="{w}" height="{h}" href="data:image/png;base64,{b64}"/></svg>'
uri = "data:image/svg+xml," + urllib.parse.quote(svg, safe="")
```

O `;base64,` interno agora está DENTRO do blob percent-encoded (não é mais um `;`
literal no nível do style string do mxGraph) — o navegador decodifica o SVG
externo, encontra uma tag `<image>` com data URI base64 padrão, e isso É permitido
nesse contexto (não passa pelo parser de style, é conteúdo normal de documento
SVG). Ver `scripts/drawio_builder.py::data_uri()` — já implementado.

## Gotcha 3 — fundo escuro precisa de DOIS atributos, não um

`background="#0d1117"` sozinho no `<mxGraphModel>` não é suficiente e o sintoma é
enganoso: o fundo volta pra branco/cinza claro mesmo com o atributo presente e o
XML validando OK. Ícones (imagens embutidas) sempre renderizam certo — só cores de
preenchimento/fonte customizadas (`fillColor`, `fontColor` de retângulos, textos)
voltam pro claro.

Causa: o draw.io tem uma feature **Adaptive Colors** (ligada por padrão) que
reescreve fill/font de formas pra manter contraste automático em modo claro/escuro
— ela ignora silenciosamente cores customizadas que não reconhece como parte da
paleta adaptativa. Como imagens embutidas (`shape=image`) não passam por esse
pipeline de cor, elas sempre pareciam "ok", mascarando o problema real e fazendo
parecer que era só o background que estava quebrado.

**Fix**: desligar a feature explicitamente, junto com o background:

```xml
<mxGraphModel ... background="#0d1117" adaptiveColors="none" ...>
```

Sem `adaptiveColors="none"`, qualquer `fillColor`/`fontColor` custom em formas
normais (não-imagem) do diagrama tem grande chance de ser revertido.

### Detalhes que NÃO importaram (testados e descartados)

- `page="0"` vs `page="1"` — não é a causa. `page="1"` é o padrão de diagrama novo,
  mantenha assim; mexer nisso não resolve fundo branco.
- Preferência de tema do app (sol/lua no app.diagrams.net, setting
  `hediet.vscode-drawio.appearance` no VS Code) — real e existe, mas não era a
  causa aqui (diagrama novo em branco já ficava escuro corretamente, provando que
  o tema do app já estava certo; só arquivo aberto com conteúdo customizado
  quebrava). Só investigar isso se um diagrama NOVO/vazio também abrir claro.

## Como eu deveria ter feito desde o início

Antes de mandar qualquer correção pro usuário testar manualmente, rodar
`scripts/render_check.py` no arquivo — ele usa o engine real (`viewer.min.js` da
extensão VS Code do draw.io, offline, sem precisar da internet nem do app aberto)
pra renderizar de verdade e tirar print. Cada rodada de "tenta de novo, ainda tá
quebrado" que apareceu nessa investigação teria sido resolvida em segundos com
isso em vez de ping-pong com o usuário. Só peça pro usuário confirmar DEPOIS de já
ter verificado localmente que renderiza certo.

Quando um fix "óbvio" não resolve e não há mensagem de erro nenhuma (caso clássico
de style string do mxGraph silenciosamente descartando conteúdo), não adivinhe uma
segunda vez — vá direto pro código-fonte real. A extensão VS Code
`hediet.vscode-drawio` embute o `app.min.js`/`viewer.min.js` completo (não
minificado a ponto de ficar ilegível) em
`~/.vscode/extensions/hediet.vscode-drawio-*/drawio/src/main/webapp/js/`. `grep`
por nome de atributo (`getAttribute("background")`, `split(";")` etc.) ali resolve
em minutos o que tentativa-e-erro não resolve em horas.
