### Prompt: Gerar PRD (Spec-Driven Development)

A partir de TUDO que amadurecemos no brainstorm acima, escreva o PRD. Use nossa conversa como fonte — não recomece nem me re-entreviste.

## Regra central

O PRD descreve **COMPORTAMENTO** e **REGRA DE NEGÓCIO** (o "o quê"/"porquê"), nunca a implementação. Biblioteca, estrutura de arquivo, conexão com banco, escolha de tecnologia são decisão de ADR/TDR, não deste documento. Não escreva código nem escolha tecnologia.

## Modo de geração

**DRAFT-FIRST**: gere o documento completo de uma vez. O que não ficou definido no brainstorm, infira e marque inline com _(premissa — confirme ou corrija)_.

**GUARDA DE COBERTURA**: se, para preencher uma seção inteira (não um item isolado), você precisar inferir mais da metade do conteúdo porque o brainstorm não cobriu o tema, não force o preenchimento. Em vez disso, escreva na seção: `⚠️ Cobertura insuficiente no brainstorm para esta seção — recomendo retomar a conversa antes de aprovar.` Isso vale por seção, não para o documento inteiro.

## Metadados do documento

Todo PRD deve abrir com front-matter no mesmo padrão deste prompt: `id`, `versao`, `status` (draft/review/approved), `data`, `autor`, `changelog`. Um PRD sem isso quebra a rastreabilidade quando evoluir para v2.

## Estrutura (PRD agêntico)

1. **Contexto** — produto, estado atual, problema de negócio.
2. **Atores** — quem/o que interage (ex.: Kubernetes, o processo da app, o banco).
3. **Predicados verificáveis** — formato Dado/Quando/Então. Cada predicado recebe um ID único sequencial (`P01`, `P02`, ...), objetivamente testável e sem ambiguidade. Os IDs existem para que a spec técnica e os testes possam referenciar cada predicado individualmente — não omita.
4. **Invariantes** — propriedades de **estado** que precisam ser sempre verdadeiras, independente de fluxo ou trigger (ex.: "app não-pronta nunca recebe tráfego"). Também recebem ID (`I01`, `I02`, ...).
5. **Restrições** — limites de **escopo/comportamento aceito** de negócio, não técnicos (ex.: "rollback automático só é permitido dentro de uma janela de 10 minutos após deploy"). Diferença prática para Invariantes: invariante é uma verdade de estado que nunca pode ser violada; restrição é um limite de decisão de negócio que delimita o que o sistema tem permissão de fazer. Se a frase descreve "isto sempre é verdade" → Invariante. Se descreve "isto é permitido até X, não além" → Restrição. Também recebem ID (`R01`, `R02`, ...).
6. **Fora do escopo** — explícito, com o porquê (obrigatório para cada item). Cada item recebe ID único sequencial (`F01`, `F02`, ...).
7. **Critérios de aceite** — como saber que está "pronto", em termos observáveis. Cada critério recebe ID único sequencial (`C01`, `C02`, ...). Sempre que possível, referencie também os IDs dos predicados/invariantes cobertos.
8. **Fases** — ordem de execução por **dependência real** entre predicados, nunca por preferência. Cada fase lista os IDs de predicado (e invariante, se travar a fase) que cobre, e a dependência que a justifica (ex.: "Fase 2 — P03, P04: depende de P01 estar implementado"). Sem dependência real entre os predicados → 1 fase só, não invente sequenciamento artificial pra parecer mais estruturado.

## Qualidade

Critério vago ("deve funcionar bem", "boa performance") não é aceitável — reformule até virar predicado verificável com número, limite ou condição objetiva.

## Auto-checagem antes de salvar (obrigatória)

Antes de gravar o arquivo, releia o documento inteiro e verifique, um a um:

- [ ] Todo predicado em Dado/Quando/Então é testável sem ambiguidade?
- [ ] Nenhuma seção vaza tecnologia, biblioteca ou decisão de implementação?
- [ ] Todo predicado, invariante, restrição, item de "Fora do escopo" e critério de aceite tem ID único e sequencial (`P`, `I`, `R`, `F`, `C`)?
- [ ] Invariantes e Restrições não se sobrepõem (nenhum item duplicado entre as duas seções)?
- [ ] Toda premissa inferida está marcada inline?
- [ ] Toda seção com cobertura insuficiente está sinalizada com o aviso ⚠️?
- [ ] Cada item de "Fora do escopo" tem justificativa?
- [ ] Toda fase referencia IDs de predicado/invariante que existem de fato, e a dependência declarada é real (não é só ordem de preferência)?
- [ ] `<slug>` tem no máximo 35 caracteres e é objetivo (sem artigo/preposição/palavra redundante)?
- [ ] `NNN` é o maior PRD existente + 1 — PRD sempre inaugura um escopo novo (ver `SKILL.md` — "Numeração dos arquivos"), nunca reaproveita o `NNN` de outro escopo?

Se qualquer item falhar, corrija antes de prosseguir — não salve o documento com pendências não sinalizadas.

## Saída

Salve em markdown em `./docs/prd/<NNN>-PRD-<slug>.md`, onde `<slug>` é kebab-case, objetivo, máx. 35 caracteres (regra e exemplo em `SKILL.md` — "`<slug>` — máximo 35 caracteres") e `<NNN>` (3 dígitos zero-padded) é o próximo número da sequência de PRD — liste `docs/prd/*-PRD-*.md` + `docs/tdr/*-TDR-*.md` + `docs/adr/*-ADR-*.md` (só os que têm `NNN` sem sufixo `.M`), pegue o maior `NNN` + 1 (vazio/inexistente em todas → `001`). Contador cruza as 3 pastas porque um TDR/ADR órfão também pode ter inaugurado um escopo sem PRD; nunca renumere um PRD já existente. Ao terminar, me mostre o PRD para revisão.