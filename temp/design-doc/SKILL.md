---
name: design-doc
description: >
  Cria e edita design docs generalistas para projetos de cloud e pipelines de CI/CD,
  conduzindo o usuário por uma entrevista estruturada de 5 seções fixas — CONTEXTO,
  PROBLEMA, SOLUÇÃO PROPOSTA, ALTERNATIVAS e RISCOS — uma pergunta por vez, com
  follow-ups condicionais quando a resposta for rasa. Detecta automaticamente o
  domínio (cloud, ci-cd ou híbrido) a partir das primeiras respostas e ajusta os
  exemplos das perguntas para serem objetivos ao contexto. Provoca ativamente nas
  seções ALTERNATIVAS e RISCOS, recusando "nenhuma/nenhum" e oferecendo alternativas
  plausíveis para reação. Gera o documento em `docs/{slug}.md` com frontmatter
  contendo `title`, `slug`, `status`, `domain` e `created_at`. Suporta modo edição
  para revisar seções pontuais de docs existentes.
  Use sempre que o usuário quiser criar ou editar um design doc, RFC técnica,
  documento de design, doc de arquitetura, ou maturar formalmente um projeto de
  cloud ou pipeline antes de implementar. Também quando mencionar "design doc",
  "documento de design", "RFC", "doc de arquitetura", "documentar a decisão",
  "registrar a proposta", "escrever o desenho", "formalizar a arquitetura",
  "documentar antes de codar", "preciso documentar essa mudança de infra",
  "preciso documentar esse pipeline" — mesmo que não use o termo "design doc"
  explicitamente.
---

# Design Doc

Gera e edita design docs estruturados para projetos de **cloud** e **CI/CD**
através de uma entrevista conduzida — uma pergunta por vez — até preencher 5
seções fixas que protegem decisões de arquitetura contra esquecimento, retrabalho
e perguntas óbvias em revisão.

A skill **não escreve nada no disco** antes da validação explícita do rascunho
consolidado. Não lê o repositório, não amarra com PRDs ou planos técnicos, não
chama outras skills — é um instrumento independente de maturação.

## Por que essa estrutura

As 5 seções não são decorativas. Cada uma protege contra uma falha específica
que aparece em revisão ou 6 meses depois:

| Seção | Função | Protege contra |
|---|---|---|
| CONTEXTO | Por que essa mudança aparece agora | "Por que estamos fazendo isso?" daqui a 6 meses |
| PROBLEMA | O que está errado especificamente | "Estamos resolvendo o problema certo?" |
| SOLUÇÃO PROPOSTA | O que vamos fazer (alto nível + deltas) | Solução sem desenho — "agente improvisa em cima" |
| ALTERNATIVAS | O que foi considerado e descartado | "Vocês consideraram X?" em revisão |
| RISCOS | O que pode dar errado + sinais pós-deploy | Surpresa em produção |

Toda condução da entrevista existe para extrair material denso o suficiente para
cumprir essa função. Resposta vaga = doc inútil. O valor da skill está em
**forçar articulação**, não em escrever markdown bonito.

## Entrada

O usuário fornece um tema livre (ex.: "migrar o RDS pra Aurora", "pipeline de
deploy do kube-news pra produção", "introduzir um cache Redis na API"). A skill
parte daí e conduz tudo por perguntas.

## Fluxo de Execução

### 1. Identificação do modo

Verificar se o usuário quer **criar** um doc novo ou **editar** um existente.

- Se o tema/pedido fizer referência a um doc já existente em `docs/`, ou se
  o slug derivado bater com um arquivo presente, perguntar:
  - "Encontrei `docs/{slug}.md`. Quer **editar uma seção** dele, **criar novo
    com slug diferente**, ou **cancelar**?"
- Caso contrário, seguir para o modo criação.

### 2. Modo criação

#### 2.1 Proposta de slug

A partir do tema fornecido, propor um slug em kebab-case, curto e descritivo:

- Tema: "migrar o RDS pra Aurora" → slug sugerido: `migracao-rds-aurora`
- Tema: "pipeline de deploy do kube-news" → slug sugerido: `pipeline-deploy-kube-news`

Apresentar o slug e pedir confirmação ou ajuste. Não numerar.

#### 2.2 Verificação de existência

Antes de iniciar a entrevista, checar `docs/{slug}.md`. Se já existir,
voltar ao passo 1 e perguntar editar/novo/cancelar.

#### 2.3 Detecção leve de domínio

Após a primeira resposta substancial (tipicamente do CONTEXTO), classificar o
domínio do doc:

- **cloud** — infraestrutura, recursos de provedor (RDS, EKS, GKE, S3, VPC,
  IAM, redes, bancos gerenciados, filas, observabilidade)
- **ci-cd** — pipelines, etapas de build/test/deploy, estratégias de release,
  gates, ambientes, automação de entrega
- **híbrido** — quando o doc cobre genuinamente os dois (ex.: provisionar infra
  *e* pipeline que entrega nela)

Anunciar a classificação ao usuário em uma linha: "Identifiquei como domínio
**{domain}** — vou ajustar os exemplos das próximas perguntas." Usuário pode
corrigir.

A classificação tem **um único efeito**: tornar os exemplos das perguntas
seguintes mais objetivos. Não muda a estrutura do doc.

#### 2.4 Entrevista sequencial

Conduzir a entrevista **uma pergunta por vez**, na ordem fixa:

1. CONTEXTO
2. PROBLEMA
3. SOLUÇÃO PROPOSTA
4. ALTERNATIVAS
5. RISCOS

Cada seção tem uma **pergunta-base** e **follow-ups condicionais**. Disparar
follow-up apenas quando a resposta for rasa, genérica, ou deixar lacuna óbvia.
Não interrogar exaustivamente — o objetivo é material denso, não tortura.

Ver `Roteiro de perguntas por seção` abaixo.

#### 2.5 Consolidação do rascunho

Após a última seção, montar o rascunho completo **no chat** (sem gravar) com:

- Frontmatter YAML
- 5 seções preenchidas
- Seção "Decisões em aberto" no final, se houver pendências não resolvidas
  durante a entrevista

Mostrar o rascunho integral e pedir validação: "Quer que eu salve assim em
`docs/{slug}.md`, ou prefere ajustar alguma seção antes?"

#### 2.6 Iteração de ajustes

Se o usuário pedir mudanças, aplicar no rascunho do chat e mostrar novamente.
**Não gravar** até a aprovação explícita.

#### 2.7 Persistência

Após "pode salvar" / "tá bom" / equivalente, gravar `docs/{slug}.md` com
`status: rascunho`. Confirmar ao usuário o caminho do arquivo.

### 3. Modo edição

Quando o doc já existe:

1. Ler `docs/{slug}.md`
2. Listar as 5 seções e perguntar: "Qual seção quer revisar?"
3. Mostrar o conteúdo atual da seção escolhida
4. Conduzir entrevista pontual apenas daquela seção, com mesmas regras de
   pergunta-por-vez e provocação
5. Apresentar a seção reescrita no chat para validação
6. Após aprovação, atualizar **somente** aquela seção do arquivo, preservando
   o resto

Permitir revisar múltiplas seções em sequência sem sair da skill. Atualizar
`status` se o usuário pedir explicitamente (ex.: "marca como aprovado").

## Roteiro de perguntas por seção

As perguntas-base abaixo são pontos de partida. Adapte os exemplos ao domínio
detectado. Os follow-ups são gatilhos — use só quando a resposta original for
insuficiente.

### CONTEXTO

**Pergunta-base:** "Por que essa mudança aparece agora? Me conta a situação
atual e o que disparou essa discussão."

Exemplos a citar conforme domínio:
- cloud: "Ex.: o cluster está chegando no limite de IPs", "o banco atual virou
  gargalo", "o custo da conta subiu 40% nos últimos 3 meses"
- ci-cd: "Ex.: o deploy hoje é manual e tá causando incidentes", "o pipeline
  atual leva 40min e trava o time"
- híbrido: combinar os dois conforme o tema

**Follow-ups (quando disparar):**
- Resposta não menciona o estado atual → "E como é resolvido hoje?"
- Resposta não menciona gatilho → "O que mudou recentemente que fez isso
  virar prioridade?"
- Resposta puramente técnica sem motivação → "Qual é a dor concreta que isso
  está causando? Pra quem?"

### PROBLEMA

**Pergunta-base:** "Qual o sintoma observável e o impacto mensurável? Qual é
o escopo do problema?"

Provocar concretude. "Está lento" não é problema — "p95 da rota /search subiu
de 200ms pra 1.2s desde a semana passada, afetando ~30% das requisições" é.

**Follow-ups:**
- Sem métrica → "Você consegue colocar um número nisso? Latência, custo,
  frequência, tempo perdido por dev, qualquer coisa quantificável?"
- Sem escopo → "Isso afeta tudo ou só uma parte? Qual?"
- Sintoma e causa misturados → "Você está descrevendo o sintoma ou a causa?
  Quero o sintoma primeiro."

### SOLUÇÃO PROPOSTA

**Pergunta-base:** "Em alto nível, o que vamos fazer? Quais são as mudanças
concretas (os deltas) e o que é impactado?"

Pedir o desenho da solução — não código, não YAML detalhado, mas o **shape**
da mudança: que componentes entram, que componentes mudam, que componentes
saem.

**Follow-ups:**
- Sem deltas claros → "O que especificamente vai ser criado, alterado ou
  removido?"
- Sem mapa de impacto → "Que outras partes do sistema vão ser tocadas? Quem
  consome isso hoje?"
- Solução vaga ("vamos usar X") → "Como X se conecta com o que já existe?
  Qual é o ponto de entrada?"

### ALTERNATIVAS

**Pergunta-base:** "Que outras 2-3 opções você considerou e descartou? Por
quê?"

**Provocação ativa — não aceitar "nenhuma":**

Se o usuário responder "não considerei outras", "não tem alternativa", "essa
é a única opção", **não aceitar**. Oferecer 2-3 alternativas plausíveis para
o tema e domínio, e pedir reação:

- Exemplo cloud (migração de banco): "E migrar pra um Postgres gerenciado
  diferente? E manter o atual e otimizar queries? E sharding manual?"
- Exemplo ci-cd (pipeline novo): "E usar GitHub Actions direto? E ArgoCD com
  GitOps? E manter o Jenkins e só refatorar?"

A reação do usuário a essas opções *é* o conteúdo da seção ALTERNATIVAS.
Registrar quais foram consideradas e por que descartadas.

**Follow-ups:**
- Descarte sem razão → "Por que essa não serve?"
- Razão genérica ("é pior") → "Pior em quê? Custo, complexidade, prazo?"

### RISCOS

**Pergunta-base:** "O que pode dar errado? Quais são os riscos técnicos e as
mitigações? Que sinais você olharia pós-deploy pra saber se algo quebrou?"

**Provocação ativa — não aceitar "nenhum":**

Risco zero é sinal de análise rasa, não de solução perfeita. Se o usuário
disser que não vê riscos, oferecer hipóteses concretas para o tema:

- cloud: "E se a migração demorar mais que a janela? E se o custo subir além
  do esperado? E se a nova engine tiver incompatibilidade de query?"
- ci-cd: "E se o pipeline novo deixar passar um bug que o antigo pegaria? E
  se travar e bloquear todos os deploys?"

**Puxar sinais observáveis pós-deploy** — esse é o ponto mais importante e o
mais esquecido:

- "1h depois do deploy, o que você olharia no Grafana/Datadog pra saber se
  quebrou?"
- "Qual métrica ou log indicaria que precisamos dar rollback?"
- "Qual é o critério de sucesso nas primeiras 24h?"

**Follow-ups:**
- Risco sem mitigação → "Como você mitiga isso?"
- Mitigação genérica ("vamos monitorar") → "Monitorar o quê especificamente?
  Qual dashboard, qual alerta?"

## Estrutura do documento gerado

```markdown
---
title: {Título descritivo do doc}
slug: {slug-em-kebab-case}
status: rascunho
domain: {cloud | ci-cd | híbrido}
created_at: {YYYY-MM-DD}
---

# {Título descritivo do doc}

## Contexto

{Por que essa mudança aparece agora. Situação atual, o que disparou a discussão.}

## Problema

{Sintoma observável, impacto mensurável, escopo.}

## Solução proposta

{Abordagem técnica em alto nível, mudanças concretas (deltas), mapa de impacto.}

## Alternativas

{2-3 alternativas viáveis consideradas + por que descartadas.}

## Riscos

{Riscos técnicos, mitigações, sinais de alerta pós-deploy.}

## Decisões em aberto

{Opcional — pontos que ficaram sem resposta durante a maturação.}
```

### Campos do frontmatter

- `title` — frase descritiva legível (não é o slug)
- `slug` — kebab-case, mesmo nome do arquivo sem `.md`
- `status` — `rascunho` | `em-revisão` | `aprovado` | `implementado` | `arquivado`
  - Sempre nasce como `rascunho`
  - Transições são pedidas pelo usuário explicitamente em modo edição
- `domain` — `cloud` | `ci-cd` | `híbrido`
- `created_at` — data ISO `YYYY-MM-DD` da criação

## Princípios

- **Uma pergunta por vez.** Nunca empilhar perguntas — força profundidade na
  resposta.
- **Provocar, não aceitar vazio.** ALTERNATIVAS e RISCOS são onde docs morrem
  de raso. Oferecer hipóteses concretas pra reação, não aceitar "nenhuma".
- **Concretude em PROBLEMA e RISCOS.** Puxar números, sintomas observáveis,
  sinais pós-deploy específicos. "Vai ficar lento" e "vamos monitorar" não
  servem.
- **Adaptar exemplos ao domínio.** Após a detecção, todas as perguntas
  seguintes devem citar exemplos do domínio identificado — não exemplos
  genéricos.
- **Não gravar antes da validação.** O rascunho mora no chat até o usuário
  aprovar. Isso evita arquivos parciais e permite ajustes baratos.
- **Não inventar conteúdo.** Tudo que vai pro doc vem da conversa. Se faltar
  informação, perguntar — nunca preencher por inferência.
- **Não ler o repo, não amarrar com PRD/PLAN.** Skill é independente por
  desenho. O usuário traz o contexto.

## Saídas

- Modo criação: arquivo novo em `docs/{slug}.md` com `status: rascunho`
- Modo edição: arquivo atualizado preservando seções não tocadas

Confirmar ao usuário o caminho final do arquivo em ambos os casos.
