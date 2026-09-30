# Prompt: Gerar ADR 

Engenheiro registrando UMA decisão arquitetural já tomada por mim. Fonte de verdade: decisão e racional do brainstorm — não releia repositório pra "descobrir" decisão. Papel: FORMALIZAR, não decidir.

## Tarefa

Gerar ADR de UMA decisão em `./docs/adr/<NNN>.<M>-ADR-<slug>.md`, `<slug>` kebab-case, objetivo, máx. 35 caracteres (`SKILL.md` — "`<slug>` — máximo 35 caracteres").

**Antes de escrever**: numeração hierárquica por escopo (`SKILL.md` — "Organização de pastas"). Identifique a qual PRD esta decisão pertence (pelo `prd_origem` já sabido, pelo contexto da conversa, ou pergunte se não for óbvio) e use o `<NNN>` desse PRD; `<M>` é o próximo sufixo livre naquele escopo — liste `docs/tdr/<NNN>.*.md` + `docs/adr/<NNN>.*.md` das duas pastas juntas, pegue o maior `.M` + 1 (nenhum ainda → `.1`; contador compartilhado com TDR do mesmo escopo, não é exclusivo de ADR). Sem PRD relacionado (decisão avulsa), este ADR inaugura seu próprio escopo: liste `docs/prd/*-PRD-*.md` + `docs/tdr/*-TDR-*.md` + `docs/adr/*-ADR-*.md` (só os sem sufixo `.M`) e pegue o próximo `<NNN>` inteiro livre, sem sufixo. Nunca reutilize, adivinhe ou renumere um ADR já existente — confirme contra arquivos reais.

## Contexto da decisão (do brainstorm)

- Decisão: `<escolha fechada>`.
- Decisor(es): `<eu, ou eu + participantes>`.
- Drivers: `<critérios que pesaram — cada um vira 1 item de Decision Drivers, não só prosa>`.
- Alternativas debatidas: `<opções reais na mesa + por que aceita/descartada. Se NENHUMA foi debatida, diga isso explicitamente — não force comparação inexistente>`.
- PRD/seed de origem (se houver): `<id>` — define o escopo/`NNN` deste ADR (ver Tarefa).

## Regra central

ADR registra UMA decisão, imutável após `aceito`. Status inicial = `aceito`. Não recomende, não reabra decisão, não infle com alternativas não debatidas. NÃO inclua parâmetros de implementação (porta, número, config) — isso é TDR, não ADR.

## Densidade mínima (evitar ADR raso)

- **Decision Drivers**: lista própria extraída do brainstorm, nunca frase do Contexto reciclada. 1 driver real = 1 item só, não infle.
- **Cada alternativa**: Prós **e** Contras em bullets separados (mín. 1 cada) — nunca 1 linha combinando com "mas"/"porém". Se brainstorm só deu 1 frase pra alternativa, é sinal de debate raso — marque como premissa em vez de inventar.

  **Anti-padrão (não faça — visto em ADR real da suíte):**
  ```
  - **Azure Web App (App Service)** — PaaS gerenciado, menos operação manual,
    mas menos controle; descartada porque...
  ```
  **Correto:**
  ```
  - **Azure Web App (App Service)**
    - Prós: PaaS gerenciado, sem operação manual de patch/upgrade/ingress.
    - Contras: menos controle sobre ambiente de execução.
  ```

- Nenhuma alternativa debatida → não invente pra preencher; escreva `*(nenhuma alternativa debatida — decisão direta, confirme ou corrija)*` como premissa.
- **Consequências**: nada genérico o bastante pra servir qualquer decisão do tipo (ex.: "aumenta complexidade operacional" sem dizer qual, pra quem, desde quando). Se não é falsificável/observável, reescreva até virar.

## Supersessão (se aplicável)

- Preencha `supersedes: "<NNN.M antigo>"` neste ADR.
- No ADR antigo: `status: superseded` + `superseded_by: "<NNN.M novo>"`. Vínculo sempre bidirecional. Supersessão troca de escopo é permitida (o novo ADR pode pertencer a um PRD diferente do antigo) — não force os dois a compartilhar `NNN`.

## Atualização do índice no TDR

Após gerar o ADR (salvo em `docs/adr/`), adicione linha na tabela "Decisões Globais (ADRs)" do TDR do serviço, em `docs/tdr/` (`| # | Título | Data | Status | Link |`), substituindo `*(nenhum ADR registrado)*` se for o primeiro. Sem saber qual TDR, pergunte antes de editar.

## Draft-first (anti-invenção)

Preencha só o que se sustenta no que dei. Qualquer Contexto, Decision Driver, Alternativa (ou Pró/Contra), Consequência ou Critério de Validação INFERIDO além do dito, marque `*(premissa — confirme ou corrija)*` — não apague por conta própria. Após eu confirmar/corrigir na revisão, remova a marca e grave valor final.

## Checklist de autoverificação (antes de apresentar)

Execute item a item e **imprima resultado no output** (✅/❌) — checar mentalmente não basta: um ADR real desta suíte pulou 2 seções obrigatórias e usou o anti-padrão de Pró/Contra combinado mesmo com esta checklist já escrita no prompt anterior.

- [ ] `<NNN>.<M>` segue a numeração hierárquica por escopo (`SKILL.md`) — `NNN` do PRD de origem (ou raiz nova, se avulso), `M` é o próximo sufixo livre do escopo, não reinicia por tipo.
- [ ] `<slug>` tem no máximo 35 caracteres e é objetivo (sem artigo/preposição/palavra redundante).
- [ ] **Todas as 6 seções do template presentes, ordem exata** (Contexto, Decision Drivers, Alternativas Consideradas, Decisão, Consequências, Critério de Validação) — nenhuma pulada.
- [ ] **Todo campo do frontmatter presente** (`adr_number`, `status`, `created`, `deciders`, `supersedes`, `superseded_by`, `prd_origem`), mesmo vazio (`""`).
- [ ] Toda alternativa listada foi de fato mencionada no brainstorm — nenhuma inventada sem marca de premissa.
- [ ] Cada alternativa com Prós e Contras em bullets próprios, nenhuma combinada.
- [ ] Decision Drivers em lista própria, não repetidos do Contexto.
- [ ] Critério de Validação observável/falsificável, não genérico.
- [ ] Nenhum parâmetro de implementação vazou pro documento.
- [ ] Supersessão (se houver): ADR antigo identificado, atualização pendente de confirmação — não edite sem eu confirmar.
- [ ] Toda premissa inferida está marcada.

Item ❌ → corrija antes de prosseguir (ou marque explicitamente por que não se aplica).

## Template
```
---
adr_number: "<NNN.M>"
status: aceito
created: <YYYY-MM-DD>
deciders: "<quem decidiu>"
supersedes: ""
superseded_by: ""
prd_origem: ""
---
# ADR <NNN.M>: [Título no formato "X em vez de Y" ou "Use X para Y" — nomeia a escolha E o que foi preterido]

## Contexto
[Problema, restrições e forças em jogo que exigem a decisão. Por que decidir isso
agora? O que está em tensão?]

## Decision Drivers
- [Critério que pesou na escolha, extraído do brainstorm — não repita o Contexto]
- [Outro critério, se houver]

## Alternativas Consideradas
- **[Alternativa A]**
  - Prós: [o que ela resolveria bem]
  - Contras: [por que não foi essa]
- **[Alternativa B]**
  - Prós: [...]
  - Contras: [...]
- **[Alternativa C]** *(se debatida)*
  - Prós: [...]
  - Contras: [...]

## Decisão
[Resumo de 1 frase no formato "no contexto de <X>, decidimos <Y> pra alcançar <Z>,
aceitando <W>" — opcional, útil pra leitura rápida] *(sumário, não substitui a prosa abaixo)*

[O que foi decidido e a razão que pesou mais. Uma escolha clara, não um leque.]

## Consequências
- **Positivas:** [o que melhora com esta decisão — observável, não genérico]
- **Negativas:** [o custo aceito, o que fica pior ou mais restrito — observável, não genérico]
- **Neutras / trade-offs aceitos:** [implicações que não são bônus nem ônus]

## Critério de Validação
[Como saber, no futuro, se esta decisão continua válida ou se está sendo seguida —
um sinal observável, não uma reafirmação da decisão.]
```

## Saída

Ao terminar, mostre:
1. Checklist executada, item a item, ✅/❌.
2. ADR seção por seção pra revisão ANTES de gravar.
3. Lista à parte das premissas pra eu confirmar + ações pendentes em outros documentos (ADR antigo, TDR).
