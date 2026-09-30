# Prompt: Atualizar TDR a partir de ADRs

Engenheiro atualizando TDR a partir de decisões já registradas em ADRs. Fonte de verdade: TDR baseline (ou última versão) + ADRs a propagar — ambos fornecidos. NÃO reanalise repositório pra "redescobrir" sistema; baseline já validado, trabalho é só propagar.

## Tarefa

Propagar decisões dos ADRs pro TDR correspondente, evoluindo do estado atual pro alvo. UM único TDR que evolui por versão — não crie TDR paralelo nem seção "futuro".

**Monorepo** (múltiplos TRDs, 1 por serviço): pra cada ADR, identifique qual(is) TDR(s) afeta. ADR pode afetar >1 serviço — propague em cada TDR afetado, cada um com sua própria entrada de changelog. Impossível determinar TDR(s) pelo conteúdo do ADR → pergunte antes de editar.

## Escopo (trava)

Mexa SÓ no que os ADRs decidiram. O que o baseline já afirma e nenhum ADR toca fica intacto — não reabra decisões nem adicione melhorias que ninguém decidiu.

## Idempotência (evita reprocessamento e duplicação)

Antes de propagar, confira a tabela "Decisões Globais (ADRs)" do TDR atual — é o registro do já propagado.

- ADR já listado **e** já refletido no corpo → não propague de novo, pule.
- ADR não listado → novo, propague e adicione linha na tabela.
- ADR já listado mas editado desde última propagação (ex.: `proposto`→`aceito`, ou conteúdo mudou) → sinalize na revisão, não repropague silenciosamente.

## Filtro de status do ADR

Só propague `status: aceito`. `superseded` NÃO é propagado como decisão vigente — se ainda refletido no TDR de propagação anterior, substitua pelo conteúdo do ADR sucessor (`superseded_by`) e sinalize a troca. `proposto` ou qualquer status ≠ `aceito` é ignorado.

## Como propagar cada ADR

- Traduza a DECISÃO em REQUISITO(S) quantificado(s) na seção certa do TDR — decisão diz "o quê", TDR passa a dizer os valores.
- Vá além da tabela: leve os PRINCIPAIS TÓPICOS do ADR (contexto, consequências, restrições, trade-offs) pra seção do template a que cada um pertence (arquitetura, NFRs, contratos, riscos etc.) — tabela só indexa, corpo é onde o conteúdo vira documento.
- **Conflito ADR × baseline**: ADR contradiz algo que baseline já afirma (ex.: troca banco declarado na Stack) → valor do ADR **substitui** o antigo, nunca mantém os dois nem duplica linha. Sinalize na revisão qual valor foi substituído e por qual ADR.
- Declare como CONTRATO qualquer saída que outra parte do sistema vá consumir.
- Decisão conectada a comportamento já especificado num PRD → amarre os dois no TDR.
- Indexe o ADR na tabela de decisões (`# | Título | Data | Status | Link`) — TDR referencia o racional, não copia.
- **Sem seção correspondente no template** (ex.: política de branching): não force encaixe. Sinalize na revisão como "ADR sem seção correspondente no template atual" pra eu decidir extensão do template ou só indexação na tabela.

## Estrutura e parâmetros

Respeite estrutura e template base do TDR — não crie headings, seções ou colunas novas; conteúdo dos ADRs entra no molde existente. Parâmetros de implementação fora do ADR (por propósito) entram aqui: ADR = decisão, TDR = requisito.

## Versionamento da atualização

Toda propagação incrementa `versao` (front-matter) e adiciona entrada no `changelog` listando cada ADR propagado na rodada + resumo de 1 linha (ex.: `"v3: propaga ADR-001.4 (troca de banco) — Stack e Dependências Externas atualizadas"`). Nunca sobrescreva changelog existente, só adicione entrada nova no topo.

## Draft-first (anti-invenção)

Preencha só o que ADRs e baseline sustentam. Qualquer valor INFERIDO além disso, marque **inline no arquivo** com `*(premissa — confirme ou corrija)*` — mesma convenção do prompt de geração de ADR. Após eu confirmar/corrigir na revisão, remova a marca e grave valor final; marca não permanece no documento aprovado.

## Checklist de consistência cruzada (obrigatória, antes de apresentar)

- [ ] Todo ADR `aceito` e ainda não propagado foi processado.
- [ ] Nenhum ADR `superseded` foi propagado como decisão vigente.
- [ ] Nenhum conflito ADR×baseline virou linha duplicada — sempre substituição.
- [ ] Stack ↔ Dependências Externas coerentes após mudanças (mesmos valores onde se sobrepõem, incl. versão).
- [ ] Arquitetura não contradiz Módulos/camadas após mudanças.
- [ ] Tabela "Decisões Globais (ADRs)" reflete exatamente os ADRs propagados até agora — nada faltando, nada duplicado.
- [ ] `versao` incrementada e `changelog` com entrada nova (não sobrescrita).
- [ ] Toda premissa inferida marcada inline no arquivo.

Item ❌ → corrija antes de prosseguir.

## Saída

Mantenha EXATAMENTE o template do TDR baseline (mesmos headings, ordem, colunas). Ao terminar, mostre seções alteradas seção por seção ANTES de gravar — e liste à parte: cada ADR propagado e onde entrou, cada conflito resolvido por substituição, cada decisão sem seção correspondente, e toda premissa marcada pra eu confirmar.
