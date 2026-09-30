# spec-driven-dev

## 🎯 Propósito & Escopo
Fluxo de Spec-Driven Development (PRD → TDR → ADR → propagação ADR→TDR) pra formalizar em documento decisões de produto e arquitetura já maduras — nunca pra decidir do zero. Cobre 4 comandos (`/prd`, `/tdr` [alias `/trd`], `/adr`, `/adr-tdr`), cada um formalizando um tipo de documento com escopo estrito e propósito diferente, salvos sempre dentro do repositório do projeto-alvo, nunca desta skill.

## 🌟 Para que ela é útil?
Resolve o erro mais caro da suíte, que é confundir os três documentos entre si (um PRD que nomeia tecnologia, ou um ADR que vira TDR, quebra a rastreabilidade que o conjunto existe pra dar) — cada comando carrega e executa à risca a referência correspondente em `references/`, que é a fonte de verdade operacional (formato exato, checklists, templates), em vez de depender de memória de execuções anteriores. Todo comando é draft-first com revisão obrigatória: mostra o documento inteiro antes de gravar, e marca premissa inferida inline até o usuário confirmar ou corrigir. Cada tipo tem sua própria pasta (`docs/prd/`, `docs/tdr/`, `docs/adr/`), mas a numeração hierárquica por escopo (`NNN` do PRD, cruzando as 3 pastas + `.M` compartilhado entre TDR/ADR do mesmo escopo, cruzando `docs/tdr/`+`docs/adr/`) garante que qualquer TDR/ADR seja rastreável até o PRD que o originou só pelo nome do arquivo, sem precisar de índice externo.

## 🛠️ Como usar?
- Rodar `/prd` pra gerar um PRD a partir de brainstorm/conversa já madura
- Rodar `/tdr` (ou `/trd`) pra gerar TDR(s) lendo o repositório real (detecta quantos serviços existem e confirma antes de gerar mais de um arquivo)
- Rodar `/adr` pra registrar uma decisão arquitetural já tomada (formaliza, não decide nem reabre)
- Rodar `/adr-tdr` pra propagar ADR(s) `aceito` pro(s) TDR(s) correspondente(s)
- Dizer "gerar PRD", "criar TDR", "documentar baseline técnico", "registrar ADR", "propagar ADR pro TDR", "atualizar TDR com as decisões dos ADRs", ou qualquer pedido de transformar uma decisão de produto/arquitetura já discutida em documento rastreável

## ⏳ Quando usar?
- Quando uma decisão de produto ou arquitetura já foi discutida/madura (em brainstorm ou não) e precisa virar documento rastreável
- Quando o projeto já tem, ou deveria ter, pastas `docs/prd/`, `docs/tdr/`, `docs/adr/` — ou a pasta legada `docs/sdd/` com os três tipos juntos, que a skill migra
- NÃO usar pra decidir do zero — a skill formaliza decisão já tomada, não substitui o brainstorm/discussão que a antecede

## ✅ O que fazer?
- Identificar qual dos 4 comandos se aplica e carregar a referência correspondente em `references/` antes de agir (`1_product_decision_record.md`, `2_technical_decision_record.md`, `3_architecture_decision_record.md`, `4_architecture_to_technical_decision.md`)
- Ao criar PRD: sempre inaugura escopo novo, salva em `docs/prd/` — listar `docs/prd/<NNN>-PRD-*.md` + `docs/tdr/<NNN>-TDR-*.md` + `docs/adr/<NNN>-ADR-*.md` (contador `NNN` cruza as 3 pastas), pegar o maior + 1
- Ao criar TDR/ADR: identificar o escopo/PRD de origem (pelo `prd_origem`, contexto, ou perguntando), salvar em `docs/tdr/` ou `docs/adr/` conforme o tipo — listar `docs/tdr/<NNN>.*.md` + `docs/adr/<NNN>.*.md` das duas pastas juntas e pegar o maior `.M` + 1 (TDR e ADR compartilham o mesmo contador de escopo, mesmo em pastas diferentes)
- Manter o `slug` em kebab-case, máximo 35 caracteres, direto nas palavras-chave da decisão — cortar artigo/preposição/palavra redundante com o tipo do doc
- Mostrar o documento (ou seções alteradas) inteiro antes de gravar em disco — nunca salvar direto
- Marcar premissa inferida além do que a conversa/repositório sustentam com `*(premissa — confirme ou corrija)*`, removendo só depois da confirmação do usuário
- Separar em 2 ADRs quando o brainstorm cobrir decisões de camadas diferentes (ex.: orquestrador vs. topologia de HA do banco) — perguntar ao usuário quando não for óbvio se é 1 decisão ou 2
- Vigiar os 3 sintomas de ADR raso: Decision Drivers que só reciclam o Contexto, Pró/Contra combinados numa linha só, Consequências genéricas o bastante pra qualquer decisão do mesmo tipo
- Antes de fechar ADR de infraestrutura (cloud, orquestração, rede), carregar e conferir contra a skill de limites de ambiente do projeto-alvo, se ela existir
- Quando um problema real aparecer num documento gerado, corrigir a referência correspondente em `references/`, não só o documento daquela vez — é assim que a skill "aprende"

## 🚫 O que NÃO fazer?
- Nunca colocar tecnologia/biblioteca/parâmetro de implementação num PRD
- Nunca colocar recomendação/"deveria ser"/crítica ao estado atual num TDR — TDR é baseline, não wishlist
- Nunca colocar parâmetro de implementação (porta, número, config) num ADR — isso é TDR
- Nunca regenerar um TDR do zero por cima de um TDR que já tem changelog/histórico — só evolui via propagação de ADR (`/adr-tdr`)
- Nunca duplicar linha ao propagar ADR pro TDR — valor novo substitui o antigo, contradição é sinalizada na revisão, fora do documento
- Nunca inventar alternativa não debatida pra preencher a seção de um ADR — se o brainstorm foi direto pra uma escolha, declarar isso explicitamente como premissa
- Nunca reiniciar a numeração `.M` num escopo que já tem TDR/ADR — o contador é do escopo, compartilhado entre os dois tipos
- Não salvar o documento fora do repositório do projeto-alvo — o caminho de salvamento nunca é dentro desta skill

## 📥 Parâmetros de Entrada (Inputs)
- `/prd` — brainstorm/conversa já madura sobre o quê e por quê de um comportamento/regra de negócio
- `/tdr` (ou `/trd`) — repositório real do projeto-alvo (a skill detecta serviços por manifest de dependências + entrypoint próprio)
- `/adr` — uma decisão arquitetural já tomada pelo usuário (não gera decisão nova)
- `/adr-tdr` — ADR(s) já `aceito`(s) a propagar pro(s) TDR(s) correspondente(s)
- Em todos os casos: confirmação/correção do usuário sobre cada premissa marcada inline antes da gravação final

## 📤 Estrutura de Saída (Outputs)
- `docs/prd/<NNN>-PRD-<slug>.md` — 1 por escopo/iniciativa
- `docs/tdr/<NNN>.<M>-TDR-<slug-servico>.md` — 1 por serviço, dentro do escopo do PRD
- `docs/adr/<NNN>.<M>-ADR-<slug>.md` — 1 por decisão, imutável após `aceito` (decisão nova = novo ADR que supersede)
- Documento (ou seções alteradas) exibido inteiro na conversa antes de qualquer gravação, com premissas marcadas inline até confirmação

## 🔧 Dependências & Ferramentas
- `references/1_product_decision_record.md`, `references/2_technical_decision_record.md`, `references/3_architecture_decision_record.md`, `references/4_architecture_to_technical_decision.md` — fonte de verdade operacional de cada comando (formato, checklist, template), atualizados com frequência independente do `SKILL.md`
- Skill de limites de ambiente do projeto-alvo (se existir, ex.: `sandbox-limits-guard`) — consultada antes de fechar ADR de infraestrutura
- `comparativo_metodologias.md` (raiz da skill) — tabela comparando TDD/BDD/SDD (foco, público, vantagens/desvantagens, exemplos de documento por metodologia); presente na pasta mas não referenciado em nenhum passo do `SKILL.md`
- Pastas `behavior_driven_dev/` e `test_driven_dev/` (raiz da skill) — existem vazias, sem conteúdo e sem menção no `SKILL.md`; parecem scaffolds reservados pra suporte futuro a essas metodologias, não fazem parte do fluxo atual

## 💡 Casos de Uso Reais
O SKILL.md traz um exemplo real e completo de numeração hierárquica: `docs/prd/001-PRD-pipeline-cd-k8s.md` → `docs/tdr/001.1-TDR-pipeline-cd-k8s.md` → `docs/adr/001.2-ADR-escolha-github-actions.md`, com a observação de que um segundo ADR do mesmo escopo seria `docs/adr/001.3-ADR-<slug>.md` (não reinicia em `.1`). Também documenta 2 correções reais já aplicadas à referência de ADR (Decision Drivers + Prós/Contras separados numa rodada, Critério de Validação + campo de decisor noutra), cada uma originada de um documento gerado que saiu raso na prática.

## ⚠️ Tratamento de Erros
- ADR raso (Decision Drivers reciclados, Pró/Contra combinados, Consequência genérica) é tratado como o erro mais comum e mais caro — a skill vigia ativamente os 3 sintomas em vez de só confiar no template
- Arquivo em padrão legado (`prd-<slug>-v1.md`, `adr-<NNN>-<slug>.md` sem escopo) é absorvido na próxima vez que for tocado: ganha `<NNN>.<M>` se pertence a escopo identificável, ou vira raiz do próprio escopo senão
- Se não for óbvio se um brainstorm é 1 decisão ou 2 decisões separadas, a skill pergunta ao usuário antes de gerar — nunca assume
- Se uma decisão de infraestrutura esbarrar numa restrição de ambiente real (sandbox/quota/serviço não suportado) via skill de limites do projeto-alvo, isso é tratado como motivo pra invalidar o ADR, mesmo com mérito técnico maduro no brainstorm
