# design-doc

## 🎯 Propósito & Escopo
Cria e edita design docs generalistas para projetos de cloud e CI/CD, conduzindo uma entrevista estruturada de 5 seções fixas (CONTEXTO, PROBLEMA, SOLUÇÃO PROPOSTA, ALTERNATIVAS, RISCOS) — uma pergunta por vez — até produzir um documento validado e gravado em `docs/{slug}.md`.

## 🌟 Para que ela é útil?
Cada uma das 5 seções protege contra uma falha específica que aparece em revisão ou meses depois: CONTEXTO evita "por que estamos fazendo isso?", PROBLEMA evita resolver o problema errado, SOLUÇÃO PROPOSTA evita "agente improvisa em cima" de um design vago, ALTERNATIVAS evita "vocês consideraram X?" em revisão, e RISCOS evita surpresa em produção. O valor está em forçar articulação densa via entrevista conduzida e provocação ativa (recusa "nenhuma alternativa"/"nenhum risco"), não em escrever markdown bonito.

## 🛠️ Como usar?
- Pedir para criar ou editar um design doc, RFC técnica, documento de design, doc de arquitetura, ou maturar formalmente um projeto de cloud/CI-CD antes de implementar
- Fornecer um tema livre em linguagem natural (ex.: "migrar o RDS pra Aurora", "pipeline de deploy do kube-news pra produção")
- Responder a entrevista sequencial uma pergunta por vez; ao final, aprovar ou pedir ajuste no rascunho mostrado no chat antes da gravação

## ⏳ Quando usar?
- Antes de implementar uma mudança de infraestrutura cloud ou um pipeline de CI/CD, quando a decisão de arquitetura merece registro formal
- Quando o usuário menciona "design doc", "RFC", "documentar a decisão", "formalizar a arquitetura", "documentar antes de codar" — mesmo sem usar esses termos exatos
- Para editar uma seção pontual de um design doc já existente em `docs/{slug}.md`

## ✅ O que fazer?
- Identificar primeiro se é modo criação ou edição (checar se já existe `docs/{slug}.md` com o slug derivado do tema)
- Propor um slug kebab-case a partir do tema e pedir confirmação antes de iniciar a entrevista
- Detectar o domínio (cloud, ci-cd ou híbrido) a partir da primeira resposta substancial e anunciar a classificação ao usuário numa linha, ajustando os exemplos das perguntas seguintes
- Conduzir a entrevista uma pergunta por vez, na ordem fixa (CONTEXTO → PROBLEMA → SOLUÇÃO PROPOSTA → ALTERNATIVAS → RISCOS), disparando follow-ups só quando a resposta for rasa
- Provocar ativamente em ALTERNATIVAS e RISCOS — nunca aceitar "nenhuma/nenhum": oferecer 2-3 hipóteses plausíveis para o tema/domínio e pedir reação
- Puxar concretude em PROBLEMA (sintoma + número, não "está lento") e em RISCOS (sinais observáveis pós-deploy: "o que você olharia no Grafana 1h depois?")
- Consolidar o rascunho completo no chat (sem gravar) e pedir validação explícita antes de persistir
- Gravar `docs/{slug}.md` só após aprovação, com `status: rascunho`, e confirmar o caminho final ao usuário

## 🚫 O que NÃO fazer?
- Não gravar nada em disco antes da validação explícita do rascunho consolidado
- Não ler o repositório, não amarrar o doc com PRDs ou planos técnicos existentes, não chamar outras skills — é um instrumento independente de maturação por desenho
- Não empilhar perguntas — sempre uma por vez, força profundidade na resposta
- Não aceitar "nenhuma alternativa" ou "nenhum risco" sem provocar com hipóteses concretas primeiro
- Não inventar conteúdo do doc — tudo vem da conversa; se faltar informação, perguntar, nunca preencher por inferência
- Não sobrescrever um `docs/{slug}.md` já existente sem antes perguntar editar seção / criar com slug diferente / cancelar

## 📥 Parâmetros de Entrada (Inputs)
- Tema livre em linguagem natural (obrigatório) — ponto de partida da entrevista
- Respostas às 5 perguntas-base da entrevista, mais eventuais follow-ups condicionais (obrigatório, uma por vez)
- Em modo edição: escolha de qual das 5 seções revisar (obrigatório)
- Confirmação/ajuste do slug proposto e aprovação explícita do rascunho antes da gravação

## 📤 Estrutura de Saída (Outputs)
- Modo criação: arquivo novo `docs/{slug}.md` com frontmatter (`title`, `slug`, `status: rascunho`, `domain`, `created_at`) + 5 seções (Contexto, Problema, Solução proposta, Alternativas, Riscos) + "Decisões em aberto" opcional
- Modo edição: arquivo atualizado, preservando as seções não tocadas
- Confirmação ao usuário do caminho final do arquivo em ambos os casos

## 🔧 Dependências & Ferramentas
Nenhuma API externa ou script — a skill é puramente conduzida por diálogo (entrevista) e leitura/escrita local em `docs/`, documentada inteiramente dentro do próprio `SKILL.md`.

## 💡 Casos de Uso Reais
Não há transcrição de prompt/resposta real no SKILL.md — o arquivo documenta exemplos de temas de entrada ("migrar o RDS pra Aurora", "pipeline de deploy do kube-news pra produção", "introduzir um cache Redis na API") e exemplos de perguntas/follow-ups por seção e domínio, mas não um diálogo completo do início ao fim.

## ⚠️ Tratamento de Erros
- Slug já existe em `docs/`: pergunta editar seção / criar com slug diferente / cancelar — nunca sobrescreve silenciosamente
- Resposta rasa/genérica/com lacuna óbvia: dispara follow-up condicional específico da seção (documentado por seção no roteiro de perguntas)
- Usuário responde "nenhuma alternativa" ou "nenhum risco": não aceita, oferece hipóteses concretas do domínio e registra a reação como conteúdo da seção
- Nenhum caso de falha técnica irrecuperável é documentado no SKILL.md — apenas fluxos condicionais de conversa
