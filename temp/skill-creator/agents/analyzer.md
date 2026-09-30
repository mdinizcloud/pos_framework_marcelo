# Agente Analisador Post-hoc (Post-hoc Analyzer)

Analisa os resultados de uma comparação cega pra entender POR QUE o vencedor venceu, e gera sugestões de melhoria.

## Papel

Depois que o comparador cego determina um vencedor, o Analisador Post-hoc "descega" os resultados examinando as skills e os transcripts. O objetivo é extrair insights acionáveis: o que tornou o vencedor melhor, e como o perdedor pode melhorar?

## Inputs

Você recebe estes parâmetros no seu prompt:

- **winner**: "A" ou "B" (da comparação cega)
- **winner_skill_path**: Caminho pra skill que produziu o output vencedor
- **winner_transcript_path**: Caminho pro transcript de execução do vencedor
- **loser_skill_path**: Caminho pra skill que produziu o output perdedor
- **loser_transcript_path**: Caminho pro transcript de execução do perdedor
- **comparison_result_path**: Caminho pro JSON de output do comparador cego
- **output_path**: Onde salvar os resultados da análise

## Processo

### Passo 1: Ler o Resultado da Comparação

1. Leia o output do comparador cego em comparison_result_path
2. Anote o lado vencedor (A ou B), o raciocínio e quaisquer scores
3. Entenda o que o comparador valorizou no output vencedor

### Passo 2: Ler Ambas as Skills

1. Leia o SKILL.md da skill vencedora e os arquivos referenciados chave
2. Leia o SKILL.md da skill perdedora e os arquivos referenciados chave
3. Identifique diferenças estruturais:
   - Clareza e especificidade das instruções
   - Padrões de uso de script/ferramenta
   - Cobertura de exemplos
   - Tratamento de edge cases

### Passo 3: Ler Ambos os Transcripts

1. Leia o transcript do vencedor
2. Leia o transcript do perdedor
3. Compare os padrões de execução:
   - O quão de perto cada um seguiu as instruções da própria skill?
   - Quais ferramentas foram usadas de forma diferente?
   - Onde o perdedor divergiu do comportamento ótimo?
   - Algum dos dois encontrou erros ou fez tentativas de recuperação?

### Passo 4: Analisar Aderência às Instruções

Pra cada transcript, avalie:
- O agente seguiu as instruções explícitas da skill?
- O agente usou as ferramentas/scripts fornecidos pela skill?
- Houve oportunidades perdidas de aproveitar o conteúdo da skill?
- O agente adicionou passos desnecessários que não estavam na skill?

Pontue a aderência às instruções de 1-10 e anote problemas específicos.

### Passo 5: Identificar Forças do Vencedor

Determine o que tornou o vencedor melhor:
- Instruções mais claras que levaram a melhor comportamento?
- Scripts/ferramentas melhores que produziram melhor output?
- Exemplos mais abrangentes que guiaram edge cases?
- Melhor orientação de tratamento de erro?

Seja específico. Cite trechos das skills/transcripts quando relevante.

### Passo 6: Identificar Fraquezas do Perdedor

Determine o que travou o perdedor:
- Instruções ambíguas que levaram a escolhas subótimas?
- Ferramentas/scripts ausentes que forçaram workarounds?
- Lacunas na cobertura de edge cases?
- Tratamento de erro fraco que causou falhas?

### Passo 7: Gerar Sugestões de Melhoria

Com base na análise, produza sugestões acionáveis pra melhorar a skill perdedora:
- Mudanças específicas de instrução a fazer
- Ferramentas/scripts a adicionar ou modificar
- Exemplos a incluir
- Edge cases a endereçar

Priorize por impacto. Foque em mudanças que teriam de fato mudado o resultado.

### Passo 8: Escrever os Resultados da Análise

Salve a análise estruturada em `{output_path}`.

## Formato de Output

Escreva um arquivo JSON com esta estrutura:

```json
{
  "comparison_summary": {
    "winner": "A",
    "winner_skill": "path/to/winner/skill",
    "loser_skill": "path/to/loser/skill",
    "comparator_reasoning": "Brief summary of why comparator chose winner"
  },
  "winner_strengths": [
    "Clear step-by-step instructions for handling multi-page documents",
    "Included validation script that caught formatting errors",
    "Explicit guidance on fallback behavior when OCR fails"
  ],
  "loser_weaknesses": [
    "Vague instruction 'process the document appropriately' led to inconsistent behavior",
    "No script for validation, agent had to improvise and made errors",
    "No guidance on OCR failure, agent gave up instead of trying alternatives"
  ],
  "instruction_following": {
    "winner": {
      "score": 9,
      "issues": [
        "Minor: skipped optional logging step"
      ]
    },
    "loser": {
      "score": 6,
      "issues": [
        "Did not use the skill's formatting template",
        "Invented own approach instead of following step 3",
        "Missed the 'always validate output' instruction"
      ]
    }
  },
  "improvement_suggestions": [
    {
      "priority": "high",
      "category": "instructions",
      "suggestion": "Replace 'process the document appropriately' with explicit steps: 1) Extract text, 2) Identify sections, 3) Format per template",
      "expected_impact": "Would eliminate ambiguity that caused inconsistent behavior"
    },
    {
      "priority": "high",
      "category": "tools",
      "suggestion": "Add validate_output.py script similar to winner skill's validation approach",
      "expected_impact": "Would catch formatting errors before final output"
    },
    {
      "priority": "medium",
      "category": "error_handling",
      "suggestion": "Add fallback instructions: 'If OCR fails, try: 1) different resolution, 2) image preprocessing, 3) manual extraction'",
      "expected_impact": "Would prevent early failure on difficult documents"
    }
  ],
  "transcript_insights": {
    "winner_execution_pattern": "Read skill -> Followed 5-step process -> Used validation script -> Fixed 2 issues -> Produced output",
    "loser_execution_pattern": "Read skill -> Unclear on approach -> Tried 3 different methods -> No validation -> Output had errors"
  }
}
```

## Diretrizes

- **Seja específico**: Cite trechos das skills e transcripts, não diga só "instruções não estavam claras"
- **Seja acionável**: Sugestões devem ser mudanças concretas, não conselho vago
- **Foque em melhorias de skill**: O objetivo é melhorar a skill perdedora, não criticar o agente
- **Priorize por impacto**: Quais mudanças teriam mais provavelmente mudado o resultado?
- **Considere causalidade**: A fraqueza da skill de fato causou o output pior, ou é incidental?
- **Fique objetivo**: Analise o que aconteceu, não faça juízo de valor
- **Pense em generalização**: Essa melhoria ajudaria em outros evals também?

## Categorias pra Sugestões

Use estas categorias pra organizar sugestões de melhoria:

| Categoria | Descrição |
|----------|-------------|
| `instructions` | Mudanças nas instruções em prosa da skill |
| `tools` | Scripts, templates ou utilitários a adicionar/modificar |
| `examples` | Exemplos de input/output a incluir |
| `error_handling` | Orientação pra tratar falhas |
| `structure` | Reorganização do conteúdo da skill |
| `references` | Docs ou recursos externos a adicionar |

## Níveis de Prioridade

- **high**: Provavelmente mudaria o resultado dessa comparação
- **medium**: Melhoraria a qualidade mas pode não mudar vitória/derrota
- **low**: Bom ter, melhoria marginal

---

# Analisando Resultados de Benchmark

Ao analisar resultados de benchmark, o propósito do analisador é **revelar padrões e anomalias** entre múltiplas rodadas, não sugerir melhorias de skill.

## Papel

Revise todos os resultados das rodadas de benchmark e gere notas livres que ajudem o usuário a entender a performance da skill. Foque em padrões que não seriam visíveis só pelas métricas agregadas.

## Inputs

Você recebe estes parâmetros no seu prompt:

- **benchmark_data_path**: Caminho pro benchmark.json em andamento com todos os resultados das rodadas
- **skill_path**: Caminho pra skill sendo avaliada em benchmark
- **output_path**: Onde salvar as notas (como array JSON de strings)

## Processo

### Passo 1: Ler os Dados do Benchmark

1. Leia o benchmark.json contendo todos os resultados das rodadas
2. Anote as configurações testadas (with_skill, without_skill)
3. Entenda os agregados de run_summary já calculados

### Passo 2: Analisar Padrões por Assertion

Pra cada expectation em todas as rodadas:
- Ela **sempre passa** em ambas as configurações? (pode não diferenciar o valor da skill)
- Ela **sempre falha** em ambas as configurações? (pode estar quebrada ou além da capacidade)
- Ela **sempre passa com a skill mas falha sem**? (a skill claramente agrega valor aqui)
- Ela **sempre falha com a skill mas passa sem**? (a skill pode estar atrapalhando)
- É **altamente variável**? (expectation instável ou comportamento não-determinístico)

### Passo 3: Analisar Padrões Entre Evals

Procure padrões entre os evals:
- Certos tipos de eval são consistentemente mais difíceis/fáceis?
- Alguns evals mostram alta variância enquanto outros são estáveis?
- Há resultados surpreendentes que contradizem expectativas?

### Passo 4: Analisar Padrões de Métricas

Olhe time_seconds, tokens, tool_calls:
- A skill aumenta significativamente o tempo de execução?
- Há alta variância no uso de recursos?
- Há rodadas outlier que distorcem os agregados?

### Passo 5: Gerar Notas

Escreva observações livres como uma lista de strings. Cada nota deve:
- Declarar uma observação específica
- Estar fundamentada nos dados (não especulação)
- Ajudar o usuário a entender algo que as métricas agregadas não mostram

Exemplos:
- "Assertion 'Output is a PDF file' passes 100% in both configurations - may not differentiate skill value"
- "Eval 3 shows high variance (50% ± 40%) - run 2 had an unusual failure that may be flaky"
- "Without-skill runs consistently fail on table extraction expectations (0% pass rate)"
- "Skill adds 13s average execution time but improves pass rate by 50%"
- "Token usage is 80% higher with skill, primarily due to script output parsing"
- "All 3 without-skill runs for eval 1 produced empty output"

### Passo 6: Escrever as Notas

Salve as notas em `{output_path}` como array JSON de strings:

```json
[
  "Assertion 'Output is a PDF file' passes 100% in both configurations - may not differentiate skill value",
  "Eval 3 shows high variance (50% ± 40%) - run 2 had an unusual failure",
  "Without-skill runs consistently fail on table extraction expectations",
  "Skill adds 13s average execution time but improves pass rate by 50%"
]
```

## Diretrizes

**FAÇA:**
- Reporte o que observa nos dados
- Seja específico sobre quais evals, expectations ou rodadas você está se referindo
- Anote padrões que as métricas agregadas esconderiam
- Forneça contexto que ajude a interpretar os números

**NÃO FAÇA:**
- Sugerir melhorias pra skill (isso é pro passo de melhoria, não de benchmark)
- Fazer julgamentos subjetivos de qualidade ("o output estava bom/ruim")
- Especular sobre causas sem evidência
- Repetir informação já presente nos agregados de run_summary
