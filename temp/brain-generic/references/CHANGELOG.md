# Changelog — brain-generic

- **v1** (2026-09-06): generalização do `brainstorm` (escopo AIOps/SRE) pra qualquer
  domínio de decisão. Mantém o esqueleto que carrega o rigor (gate obrigatório,
  override por risco catastrófico, estrutura A-D, válvula de escape,
  anti-injection, fechamento com ponte pra PRD) e reescreve todo o conteúdo
  específico de infra (7 temas do gate, pilares técnicos, exemplo, escopo) pra
  versão domínio-neutra.

- **v2** (2026-09-06): reforço pra organização de arquivos e refatoração de conteúdo.
  Adiciona 2 temas de gate (referências/dependências quebráveis; duplicidade/
  sobreposição), inventário do estado atual antes de perguntar, override por
  referências quebráveis, pilar de consistência/convenção estrutural, 2º
  exemplo de refatoração de pastas, e linha de ordem de migração no Fechamento.

- **v3-rascunho / SKILLS-v2** (2026-09-06): incorporação da fase divergente
  (ideação criativa), tema de Carga Cognitiva/Arquitetura da Informação, uso
  explícito de tools pra inventário, ordenação dinâmica de temas.
  Avaliação: ganha na fase divergente e no tema de carga cognitiva, mas
  regride em precisão — perdeu limiares quantificados do critério de impacto
  e trocou ordenação determinística por "julgamento dinâmico" sem regra fixa
  (reduz reprodutibilidade entre execuções).

- **v3** (2026-09-06): fusão de v1 + v2 + SKILLS-v2, corrigindo as regressões
  identificadas na avaliação comparativa:
  1. Teto de escopo pra fase divergente (máx. 1-2 alternativas, evita scope creep).
  2. Limiares quantificados de v1 reincorporados no critério de impacto (b).
  3. Ordenação dinâmica substituída por 3 perfis de domínio fixos e pré-definidos
     (Conteúdo/Arquivos, Negócio/Pessoal, Técnico/Infra) — reprodutível.
  4. Regra de precedência explícita pra overrides combináveis (cumulativos).
  5. Regra anti-alucinação: toda afirmação sobre referências/symlinks precisa
     citar o comando/caminho usado na investigação.
  6. Piso de perguntas deixou de ser artificial — pergunta exatamente as
     lacunas reais existentes, sem forçar até 5 quando só há 2-4.
  7. Carga Cognitiva promovida a pilar de peso igual, com prioridade garantida
     no perfil de domínio "Conteúdo/Arquivos".
  8. Higiene de nomenclatura: changelog movido pra este arquivo (carrega só
     sob demanda), corpo do SKILL.md fica enxuto.
  9. Válvula de escape estendida pra cobrir ausência de alternativa divergente
     válida (não forçar ideia fraca só pra cumprir a regra).
  10. Teto geral de tamanho por seção na estrutura Completa (A-D), não só na
      tabela de trade-offs.
