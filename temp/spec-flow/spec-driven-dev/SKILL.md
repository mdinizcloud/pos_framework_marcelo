---
name: spec-driven-dev
description: Fluxo de Spec-Driven Development (PRD → TDR → ADR → propagação ADR→TDR) pra formalizar em documento decisões de produto e arquitetura já maduras — nunca pra decidir do zero. Dispara nos comandos /prd, /tdr (alias /trd), /adr e /adr-tdr, e também quando o usuário pedir pra "gerar PRD", "criar TDR", "documentar baseline técnico", "registrar ADR", "criar/gerar ADR", "documentar decisão arquitetural", "propagar ADR pro TDR", "atualizar TDR com as decisões dos ADRs", ou qualquer pedido de transformar uma decisão de produto/arquitetura já discutida (em brainstorm ou não) em documento rastreável. Use também quando o projeto já tiver (ou deveria ter) pastas `docs/prd/`, `docs/tdr/` e `docs/adr/` — ou a pasta legada `docs/sdd/` com os três tipos juntos, que a skill migra pro layout novo.
---

# Spec-Driven Development — PRD, TDR, ADR

Três documentos complementares, cada um com escopo estrito e propósito diferente. Confundir os três é o erro mais caro desta suíte — um PRD que nomeia tecnologia, ou um ADR que vira TDR, quebra a rastreabilidade que o conjunto existe pra dar.

## Os 3 documentos

| | PRD | TDR | ADR |
|---|---|---|---|
| Responde | **O quê** e **por quê** — comportamento e regra de negócio | **Como é hoje** — baseline técnico do repositório | **Por que X e não Y** — uma decisão arquitetural, já tomada |
| Nunca contém | Tecnologia, biblioteca, parâmetro de implementação | Recomendação, "deveria ser", crítica ao estado atual | Parâmetro de implementação (porta, número, config — isso é TDR) |
| Granularidade | Predicados verificáveis (Dado/Quando/Então), invariantes, restrições — tudo com ID | Baixa e estável — regra fina fica em ADR | Alta, mas só da decisão em si — 1 decisão por arquivo |
| Muda quando | Requisito de negócio muda | Código muda, ou um ADR aceito é propagado (`/adr-tdr`) | Nunca — é imutável após `aceito`. Decisão nova = novo ADR que supersede |
| Local | `docs/prd/<NNN>-PRD-<slug>.md` | `docs/tdr/<NNN>.<M>-TDR-<slug-servico>.md` (1 por serviço) | `docs/adr/<NNN>.<M>-ADR-<slug>.md` |

O caminho de salvamento é sempre dentro do **repositório do projeto-alvo**, nunca deste skill — este skill só guarda as referências que geram esses documentos.

## Os 4 comandos

Cada comando carrega e executa, à risca, a referência correspondente em `references/` deste skill. As referências são a fonte de verdade operacional (formato exato, checklists, templates) e são atualizadas com frequência independente deste arquivo — sempre leia o arquivo antes de agir, não confie em memória de execuções anteriores.

- **`/prd`** → `references/1_product_decision_record.md`. Gera o PRD a partir de um brainstorm/conversa já madura. Nunca re-entrevista do zero se o contexto já existe na conversa atual.
- **`/tdr`** (alias `/trd`, mesmo comando) → `references/2_technical_decision_record.md`. Gera o(s) TDR(s) lendo o repositório real — detecta quantos serviços existem (1 manifest de dependências + entrypoint próprio = 1 serviço candidato) e confirma com o usuário antes de gerar mais de um arquivo.
- **`/adr`** → `references/3_architecture_decision_record.md`. Registra UMA decisão já tomada pelo usuário. Formaliza, não decide nem reabre.
- **`/adr-tdr`** → `references/4_architecture_to_technical_decision.md`. Propaga ADR(s) `aceito` pro(s) TDR(s) correspondente(s), respeitando idempotência (não repropaga o que já está no corpo do TDR) e resolvendo conflito por substituição, nunca duplicata.

Todo comando é **draft-first com revisão obrigatória**: mostra o documento (ou as seções alteradas) inteiro antes de gravar em disco, nunca salva direto. Premissa inferida além do que a conversa/repositório sustentam é marcada inline (`*(premissa — confirme ou corrija)*`) e some do documento só depois que o usuário confirma ou corrige.

## Organização de pastas — 3 pastas, numeração hierárquica por escopo

Cada tipo tem sua própria pasta — `docs/prd/`, `docs/tdr/`, `docs/adr/` — mas a numeração continua vinculada entre elas: o nome do arquivo sozinho entrega o escopo/PRD de origem, sem precisar abrir o documento nem consultar índice externo.

`NNN` identifica um **escopo/iniciativa** (3 dígitos, zero-padded). Normalmente só o PRD o inaugura — é o primeiro documento gerado pra um escopo novo — mas um TDR ou ADR órfão (sem PRD, ver "Sem PRD relacionado" abaixo) também pode inaugurar um escopo. Por isso `NNN` é um **contador cruzando as 3 pastas**: antes de atribuir um `NNN` novo, sempre liste `docs/prd/<NNN>-PRD-*.md` + `docs/tdr/<NNN>-TDR-*.md` + `docs/adr/<NNN>-ADR-*.md` (só os que têm `NNN` inteiro, sem sufixo `.M`) juntos, pegue o maior + 1.

TDR e ADR que pertencem ao mesmo escopo (a mesma iniciativa do PRD) não ganham um `NNN` novo: eles herdam o `NNN` do PRD e recebem um sufixo `.M` (`M` = 1, 2, 3... sem zero-padding), um **contador próprio daquele escopo, compartilhado entre TDR e ADR mesmo estando em pastas diferentes** (não é um contador por tipo nem por pasta — o próximo TDR ou ADR do mesmo escopo pega o próximo `M` livre, seja qual for o tipo dele). Pra calcular `M`, liste `docs/tdr/<NNN>.*.md` + `docs/adr/<NNN>.*.md` **das duas pastas juntas**, pegue o maior `.M` + 1.

Exemplo: `docs/prd/001-PRD-pipeline-cd-k8s.md` → `docs/tdr/001.1-TDR-pipeline-cd-k8s.md` → `docs/adr/001.2-ADR-escolha-github-actions.md`. Um segundo ADR do mesmo escopo seria `docs/adr/001.3-ADR-<slug>.md` (olhou `docs/tdr/001.*` + `docs/adr/001.*` juntos, achou o `.2` do TDR/ADR anteriores, não reinicia em `.1`).

**Ao criar um PRD**: sempre um escopo novo. Vai sempre em `docs/prd/`. Calcule `NNN` pelo contador cruzado das 3 pastas acima (vazio/inexistente em todas → `001`).

**Ao criar um TDR ou ADR**: identifique a qual PRD/escopo ele pertence (pelo `prd_origem` já informado, pelo contexto da conversa, ou — se não for óbvio — pergunte ao usuário antes de gerar). Depois:
- Escopo identificado → use o `NNN` desse PRD. Calcule `.M` pelo contador cruzado `docs/tdr/<NNN>.*` + `docs/adr/<NNN>.*` (nenhum ainda → `.1`). Grave em `docs/tdr/` ou `docs/adr/` conforme o tipo.
- Sem PRD relacionado (decisão avulsa, TDR de baseline sem PRD que o motivou) → este documento inaugura seu próprio escopo, como um PRD inauguraria: calcule `NNN` pelo contador cruzado das 3 pastas (sem sufixo — vira ele mesmo a raiz de um escopo nesse caso raro), mas grave em `docs/tdr/` ou `docs/adr/`, não em `docs/prd/` (a pasta segue o tipo do documento, não o papel de "raiz de escopo").

TDRs gerados em lote (monorepo, vários serviços na mesma rodada) recebem `.M` consecutivos na ordem de confirmação dos serviços com o usuário.

**Identidade do ADR não se perde**: `adr_number` no frontmatter e o número no título (`# ADR <NNN.M>: ...`) usam o mesmo `NNN.M` do nome de arquivo — cada ADR continua unicamente citável (`ADR-001.2`), só que agora o número já entrega o escopo/PRD de origem de graça.

**Legado:** projeto com pasta antiga `docs/sdd/` (os 3 tipos juntos) é migrado na próxima vez que qualquer arquivo dela for tocado: mova cada arquivo pra `docs/prd/`, `docs/tdr/` ou `docs/adr/` conforme o tipo no nome (renomeando `TRD`→`TDR` no nome do arquivo se for o caso — variante antiga do acrônimo), preservando o `NNN.M` que já tinha — não recalcule numeração de arquivo que já tem escopo válido. Arquivo em padrão ainda mais antigo, sem escopo (`prd-<slug>-v1.md`, `adr-<NNN>-<slug>.md`) primeiro ganha `<NNN>.<M>` (se pertence a escopo com PRD identificável) ou vira raiz do seu próprio escopo (`<NNN>` sem sufixo, próximo livre calculado pelo contador cruzado) — só depois move pra pasta correspondente ao tipo. Estrutura sem nenhuma numeração reconhecível (ex.: `adrs/`, `prd_saúde/`, `technical_requirements/` soltos, sem `NNN.M` nem vínculo explícito entre os arquivos) não é seguro absorver automaticamente — pergunte ao usuário como agrupar em escopos antes de mover, não adivinhe.

**`<slug>` — máximo 35 caracteres, objetivo:** kebab-case, direto nas palavras-chave da decisão/feature — nunca o título inteiro reduzido a traços. Corte artigo, preposição e palavra redundante com o tipo do doc (não repita "prd"/"tdr"/"adr", nem "sistema"/"aplicação" quando óbvio pelo contexto do repo). Estourou 35 → corte pra o essencial antes de gravar, não trunque no meio de uma palavra. Ex.: título "Escolha da Ferramenta de CI/CD para Pipeline de Deploy em Kubernetes" → slug `pipeline-cd-k8s` (15 caracteres), não `escolha-ferramenta-cicd-pipeline-deploy-kubernetes` (51, estoura).

## Regras que atravessam os 3 documentos

**Um ADR é uma decisão, não um pacote de decisões.** Quando o brainstorm cobre mais de uma decisão de subsistemas diferentes — por exemplo "qual orquestrador usar" e "topologia de HA do banco" saíram da mesma conversa, mas são decisões de camadas diferentes (compute vs dado) — isso vira 2 ADRs separados, não um bundlado. Quando não for óbvio se é 1 decisão ou 2, pergunte ao usuário antes de gerar; não assuma.

**ADR raso é o erro mais comum e mais caro.** Três sintomas a vigiar ativamente, porque é fácil escorregar neles mesmo seguindo o template:
- Decision Drivers que são a mesma frase do Contexto reciclada em bullets — cada driver tem que ser um critério que de fato pesou na escolha, extraído do que foi dito, não inventado pra parecer mais robusto.
- Alternativa com Pró e Contra combinados numa linha só ("X é bom, mas Y") em vez de bullets separados — isso é sinal de comparação rasa, não de decisão bem fundamentada.
- Consequências genéricas o bastante pra servir qualquer decisão do mesmo tipo ("aumenta complexidade operacional", sem dizer qual, pra quem, desde quando) — se não é observável/falsificável, não é consequência, é enchimento.

**Nunca invente alternativa não debatida pra preencher a seção.** Se o brainstorm foi direto pra uma escolha sem comparar opções, o ADR declara isso explicitamente (marcado como premissa) em vez de fabricar um "Alternativa B" que ninguém considerou.

**TDR nasce uma vez como baseline e depois só evolui.** Depois do `versao: 1` gerado a partir do repositório, a única forma de atualizar um TDR é propagando ADR (`/adr-tdr`) — nunca regenerar do zero por cima de um TDR que já tem changelog e histórico; isso apaga rastreabilidade.

**Propagação ADR→TDR tem escopo travado.** `/adr-tdr` só mexe no que o(s) ADR(s) da rodada decidiram. Se um valor do ADR contradiz algo que o TDR já afirma, o valor novo **substitui** o antigo (nunca duplica linha) e a substituição é sinalizada na revisão, fora do documento.

**Decisão de infraestrutura pode ser invalidada pelo ambiente real, não só pelo mérito técnico.** Antes de fechar um ADR de infra (cloud, orquestração, rede), se o projeto-alvo tiver uma skill própria de limites de ambiente (sandbox, quota, serviços não suportados), carregue e confira contra ela — uma decisão madura no brainstorm pode esbarrar numa restrição do ambiente real que o brainstorm sozinho não tinha como prever.

## Melhorando os arquivos de referência

Os arquivos em `references/` são vivos — quando um problema real aparecer num PRD/TDR/ADR gerado (ex.: um ADR saiu raso, uma propagação duplicou uma linha), a correção é editar a referência correspondente, não só o documento gerado daquela vez. É assim que esta skill aprende: a referência de ADR desta suíte já passou por 2 rodadas de correção reais (Decision Drivers + Prós/Contras separados na 1ª, Critério de Validação + campo de decisor na 2ª) — cada uma nasceu de um documento gerado que saiu raso na prática, não de teoria antecipada.
