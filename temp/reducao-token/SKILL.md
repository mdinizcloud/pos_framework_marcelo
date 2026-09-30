---
name: reducao-token
description: >-
  Reduz o tamanho (tokens) de uma skill (SKILL.md), agent (definição/system prompt) ou
  prompt de IA sem perder nenhuma regra, exemplo ou comportamento — comprime só a prosa
  (redundância, conectivos, frases longas), mantendo cada checklist, exemplo e seção
  intocável (Template, schema, bloco de código) byte a byte. Exige validação funcional:
  roda um baseline com o alvo ORIGINAL, roda o mesmo teste com o alvo REDUZIDO e prova
  numa tabela markdown que a saída se mantém idêntica com menos tokens. Usar sempre que o
  usuário pedir pra "reduzir token", "compactar", "deixar mais enxuto/conciso" uma
  skill/agent/prompt, ou disser "gera o mesmo resultado só que menor" — mesmo sem a
  palavra "token". NÃO usar pra documentos de negócio/arquitetura (ADR, TDR, PDR, RFC,
  especificação, relatório) — escopo é só artefato de IA (skill, agent, prompt).
---

# Reducao Token (v3)

## Overview

Comprime skills, agents e prompts de IA pra caber em menos tokens, preservando 100% do comportamento e conteúdo — regra central: "menos palavra, zero perda de sentido". Diferente de resumir (que descarta informação), aqui toda regra, todo item de checklist e todo exemplo do original tem que sobreviver na versão reduzida, só com menos palavras pra dizer a mesma coisa.

**Escopo é só artefato de IA** — SKILL.md, definição/system prompt de agent, prompt reusável. Não é ferramenta de edição de documento.

**O passo mais crítico é a validação funcional (passos 3, 6 e 7):** não basta conferir que o conteúdo ainda está presente — é preciso provar que o alvo reduzido *gera a mesma saída* que o original. A tabela de prova (passo 9) é o entregável que justifica a skill.

## Quando NÃO usar

- Pedido de "resumir", "simplificar o conteúdo" ou "cortar partes menos importantes" — é resumo com perda intencional, não é esta skill. Aqui a perda de conteúdo ou de comportamento é sempre erro, nunca objetivo.
- Alvo é documento de negócio/arquitetura — **ADR, TDR, PDR, RFC, especificação técnica, relatório, ata, contrato**. Essa skill nunca edita esse tipo de artefato, mesmo que o pedido use as palavras "reduzir" ou "compactar". Escopo é exclusivo pra skill, agent e prompt de IA.

## Workflow

### 1. Leia o alvo inteiro

Não compacte por trecho lido parcialmente — seção cortada da leitura é regra perdida na saída. Vale pra SKILL.md, definição de agent ou prompt reusável.

### 2. Identifique seções intocáveis

Confirme com o usuário (ou releia o pedido) se alguma seção deve ficar **byte a byte igual** — comum em prompts com bloco `## Template`, schemas, exemplos de código ou blocos de saída fixa. Copie essas seções sem tocar em espaço, quebra de linha ou palavra.

Se o usuário não especificou nada, proteja por padrão: blocos de código (` ``` `), templates literais e exemplos concretos ("faça assim / não faça assado") — são comportamento, não prosa.

### 3. Baseline funcional (teste ANTES de comprimir) — CRÍTICO

Antes de alterar qualquer palavra, execute o alvo original e guarde o resultado — o "Baseline de Qualidade". Para tornar a comparação válida:

- **Fixe o(s) input(s) de teste.** Escolha 2–3 casos, incluindo pelo menos um caso de borda ou que exercite uma regra rara do alvo. 1 caso só não prova nada. Monte um `casos.json`: `[{"name": "...", "input": "..."}, ...]`.
- **Execução determinística.** Rode com `effort: low` e o **mesmo input** dos dois lados. Não passe `temperature` — os modelos atuais (opus-4-8, sonnet-5, fable-5) a rejeitam com 400; reprodutibilidade vem do input fixo + effort baixo. Divergência = falha a investigar, nunca "provável ok".
- Se o alvo tem variáveis/placeholders, preencha com valores concretos e **reutilize exatamente os mesmos** no passo 6.

Prefira o harness `scripts/token_validate.py` (executa o alvo via API externa e conta **tokens reais**, não estimativa) a simular a execução no próprio contexto. Simulação serve só quando não há acesso à API — e aí é sinal, não prova. Guarde a saída literal de cada caso.

### 4. Inventário de regras (critério de aceite)

Monte o inventário do original — é o checklist do passo 7:
- cada item de checklist/lista numerada (**conte quantos são**)
- cada regra ou restrição declarada ("nunca", "sempre", "não faça X")
- cada exemplo concreto (anti-padrão vs correto, input/output)
- cada campo obrigatório citado (frontmatter, colunas de tabela, nomes de seção)

### 5. Comprima a prosa, não o conteúdo

Técnicas que cortam token sem cortar sentido:
- remover conectivo redundante ("que", "de forma que", "no sentido de") quando a frase fica clara sem ele
- fundir 2 frases que dizem a mesma coisa em ângulos diferentes
- trocar explicação longa por termo direto, mantendo o mesmo nível de precisão
- manter listas como listas (não vire lista em parágrafo — lista já é a forma mais densa)
- manter cada regra em sua própria linha/bullet — não esconda regra dentro de frase corrida

Linguagem da versão reduzida — o mais fácil de interpretar, no menor número de tokens:
- preferir palavra curta e comum a palavra longa ou rebuscada, quando dizem o mesmo ("usar" > "utilizar", "antes" > "previamente")
- voz ativa e ordem direta (sujeito-verbo-objeto); cortar nominalização ("valide X" > "faça a validação de X")
- uma ideia por frase; frase curta lê mais rápido e tokeniza em menos tokens
- termo técnico exato fica intocado — clareza aqui é precisão, não simplificação (não trocar `idempotente` por "que pode repetir")
- meta: menos token E mais legível são o mesmo objetivo aqui, não um trade-off — texto denso e direto ganha nos dois

O que NUNCA fazer pra economizar token:
- apagar item de checklist, exemplo ou regra pra "resumir"
- generalizar 2 regras específicas numa regra vaga que perde a precisão original
- remover o "porquê" de uma regra quando esse porquê muda como o leitor aplica a regra em caso de dúvida
- tocar em seção marcada como intocável (passo 2)
- comprimir a ponto de virar telegrafês ambíguo (abreviação obscura, frase sem conectivo essencial que muda o sentido) — menos token não vale perda de clareza
- adicionar meta-comentário sobre a própria compressão dentro do arquivo reduzido (changelog vai no git/PR, não no corpo) — skill de reduzir token que se infla é autocontraditória

### 6. Teste da versão comprimida

Execute exatamente os mesmos casos de teste do passo 3 — **mesmos inputs, mesma `temperature=0`** — agora com o alvo reduzido. Guarde cada saída.

### 7. Validação e comparação — CRÍTICO

Confira duas coisas:

**a) Contra o inventário (passo 4):** item a item — cada regra/exemplo/campo ainda está lá? Se algo sumiu ou ficou vago demais pra ser aplicado como antes, é falha.

**b) Baseline × reduzido (passos 3 e 6):** as saídas batem em comportamento e precisão? A versão reduzida deve seguir todas as regras igual ao original.

Se houver perda de qualidade, de regra ou divergência de saída, **desfaça os excessos da compressão** (recue no corte que causou a perda) e volte ao passo 6. Não entregue "quase igual".

> Ressalva de método: o teste é uma **simulação** (o modelo roda o próprio alvo). É sinal forte, não prova determinística — por isso `temperature=0` e múltiplos casos são obrigatórios, e divergência sempre conta como falha a investigar, nunca como "provável ok".

### 8. Salve como arquivo novo

Não sobrescreva o original salvo pedido explícito — grave com sufixo de versão (`_v2`, `_v3`, ...) ou no caminho indicado. Preserve a formatação markdown (headings, listas, blocos de código).

### 9. Reporte com a tabela de prova (entregável principal)

Se rodou o harness, a tabela sai pronta de:

```bash
scripts/token_validate.py validate ORIGINAL.md REDUZIDO.md --cases casos.json
```

Ele conta **tokens reais** (API `count_tokens` — nunca `tiktoken`, que subestima tokens de Claude), executa os dois lados com o mesmo input e sai com código ≠ 0 se qualquer caso divergir. Formato:

| Métrica | Original | Reduzido | Δ |
| :--- | :--- | :--- | :--- |
| **Tokens (API)** | `X` | `Y` | `-Z%` |
| **Caracteres** | `A` | `B` | `-C%` |
| **Caso 1 — saída** | `[saída original]` | `[saída reduzida]` | igual? |
| **Caso de borda — saída** | `[saída original]` | `[saída reduzida]` | igual? |
| **Inventário de regras** | N itens | N itens | todas preservadas? Sim/Não |

Sem acesso à API, preencha a tabela pela simulação do passo 3/6 — mas marque que é estimativa, não prova externa. Feche com 1–2 frases: quanto reduziu (em tokens), o que ficou intocado (ex.: "seção Template byte a byte"), e a confirmação de que baseline e reduzido geraram a mesma saída em todos os casos. Essa tabela é a **prova** de que a skill cumpriu o objetivo: menos tokens, mesmo resultado.

## Exemplo de compressão (referência de calibração)

Original (regra de tool-use dentro de uma skill):
```
Antes de executar qualquer comando que apague arquivo ou reescreva histórico do
git, você deve obrigatoriamente parar e perguntar ao usuário se ele confirma a
ação, explicando de forma clara qual é o risco envolvido na operação que está
prestes a ser realizada. Não prossiga sem essa confirmação explícita.
```

Reduzido (mesma regra, mesmo gatilho, mesma obrigação — só menos palavra):
```
Antes de comando que apaga arquivo ou reescreve histórico git, pare e pergunte
confirmação ao usuário, explicando o risco da operação. Não prossiga sem
confirmação explícita.
```

Nada foi perdido: mesmo gatilho (delete/rewrite git), mesma obrigação de parar e explicar risco, mesma proibição de prosseguir sem confirmação.
