---
name: skills
description: Cria novas skills, edita e melhora skills existentes, e mede performance de skill via evals/benchmark. Use quando o usuário quiser criar uma skill do zero, editar ou otimizar uma skill existente, rodar evals pra testar uma skill, comparar performance com análise de variância, ou otimizar a description de uma skill pra melhorar a taxa de acerto do trigger. Dispare também quando o usuário disser "cria uma skill pra X", "transforma isso numa skill", "essa skill não tá disparando direito", "empacota essa skill", ou "quero testar se essa skill funciona".
---

# Skills-C

Skill pra criar novas skills e melhorá-las iterativamente. Combina o melhor de duas gerações anteriores desse toolchain: scaffolding rápido (`init_skill.py`) + o loop completo de teste/benchmark/otimização de description.

Em linhas gerais, o processo de criar uma skill é:

- Decidir o que a skill deve fazer e mais ou menos como
- Escrever um rascunho
- Criar alguns prompts de teste e rodar claude-com-acesso-à-skill neles
- Ajudar o usuário a avaliar os resultados, qualitativa e quantitativamente
- Reescrever a skill com base no feedback
- Repetir até ficar satisfeito
- Expandir o conjunto de testes e tentar de novo em maior escala

Seu trabalho ao usar essa skill é descobrir em que ponto desse processo o usuário está e ajudá-lo a avançar. Se o usuário já tem um rascunho, vá direto pra parte de eval/iteração. Se disser "não precisa rodar avaliação, só vamos no feeling", faça isso também — flexibilidade importa mais que seguir o processo à risca.

Depois que a skill estiver pronta, rode o otimizador de description (script dedicado) pra melhorar o trigger.

## Comunicando com o usuário

Skills-c é usada por gente com níveis bem diferentes de familiaridade com jargão técnico. Preste atenção nas pistas de contexto pra calibrar sua comunicação:

- "avaliação" e "benchmark" são meio-termo, mas OK usar direto
- pra "JSON" e "assertion", espere sinais claros de que o usuário conhece o termo antes de usar sem explicar

Tá tudo bem explicar termos rapidamente se tiver dúvida.

---

## Criando uma skill

### Etapa 0: Scaffold (se for skill nova do zero)

Pule se a skill já existe (edição/iteração). Pra criar do zero, rode primeiro:

```bash
python scripts/init_skill.py <nome-da-skill> --path <diretório-de-saída>
```

Isso cria a estrutura completa (`SKILL.md` com placeholders TODO + `scripts/`, `references/`, `assets/` de exemplo). Customize ou apague os arquivos de exemplo gerados antes de seguir pra entrevista.

### Capturar Intenção

Entenda a intenção do usuário primeiro. A conversa atual pode já conter um workflow que o usuário quer capturar (ex: "transforma isso numa skill"). Se sim, extraia respostas do histórico primeiro — ferramentas usadas, sequência de passos, correções que o usuário fez, formatos de input/output observados. O usuário pode precisar preencher lacunas, e deve confirmar antes do próximo passo.

1. O que essa skill deve permitir o Claude fazer?
2. Quando essa skill deve disparar? (que frases/contextos do usuário)
3. Qual o formato de output esperado?
4. Vale a pena criar test cases pra verificar que a skill funciona? Skills com output objetivamente verificável (transformação de arquivo, extração de dado, geração de código, passos de workflow fixos) se beneficiam de test cases. Skills com output subjetivo (estilo de escrita, arte) geralmente não precisam. Sugira o default apropriado pro tipo de skill, mas deixe o usuário decidir.

### Entrevista e Pesquisa

Pergunte proativamente sobre edge cases, formatos de input/output, arquivos de exemplo, critérios de sucesso e dependências. Espere fechar essa parte antes de escrever prompts de teste.

Cheque MCPs disponíveis — se úteis pra pesquisa (buscar docs, achar skills parecidas, checar boas práticas), pesquise em paralelo via subagents se disponível, senão inline.

### Escrever o SKILL.md

Com base na entrevista, preencha:

- **name**: identificador da skill, kebab-case, batendo com o nome da pasta
- **description**: quando disparar, o que faz. Esse é o mecanismo primário de trigger — inclua tanto o que a skill faz QUANTO os contextos específicos de quando usar. Toda info de "quando usar" vai aqui, não no corpo. Nota: Claude tende a "sub-disparar" skills — não usá-las quando seriam úteis. Pra combater isso, torne a description um pouco "insistente". Em vez de "Como montar um dashboard simples pra exibir dados internos.", escreva algo como "Como montar um dashboard simples pra exibir dados internos. Use essa skill sempre que o usuário mencionar dashboards, visualização de dados, métricas internas, ou quiser exibir qualquer tipo de dado da empresa, mesmo que não peça um 'dashboard' explicitamente."
- **compatibility**: ferramentas/dependências necessárias (opcional, raramente necessário)
- **o resto da skill :)**

### Guia de Escrita da Skill

#### Anatomia de uma Skill

```
nome-da-skill/
├── SKILL.md (obrigatório)
│   ├── Frontmatter YAML (name, description obrigatórios)
│   └── Instruções em Markdown
└── Recursos Empacotados (opcional)
    ├── scripts/    - Código executável pra tarefas determinísticas/repetitivas
    ├── references/ - Docs carregadas no contexto sob demanda
    └── assets/     - Arquivos usados no output (templates, ícones, fontes)
```

#### Divulgação Progressiva

Skills usam um sistema de carregamento em três níveis:
1. **Metadados** (name + description) — sempre no contexto (~100 palavras)
2. **Corpo do SKILL.md** — no contexto quando a skill dispara (<500 linhas idealmente)
3. **Recursos empacotados** — sob demanda (ilimitado, scripts podem rodar sem carregar no contexto)

**Padrões-chave:**
- Mantenha SKILL.md abaixo de 500 linhas; se estiver chegando perto do limite, adicione mais uma camada de hierarquia com ponteiros claros de onde continuar.
- Referencie arquivos claramente a partir do SKILL.md, com orientação de quando lê-los.
- Pra arquivos de referência grandes (>300 linhas), inclua um índice.

**Organização por domínio**: quando uma skill suporta múltiplos domínios/frameworks, organize por variante:
```
cloud-deploy/
├── SKILL.md (workflow + seleção)
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```
Claude lê só o arquivo de referência relevante.

#### Princípio da Não-Surpresa

Skills não devem conter malware, exploit code, ou qualquer conteúdo que comprometa segurança do sistema. O conteúdo de uma skill não deve surpreender o usuário quanto à sua intenção declarada. Não crie skills enganosas ou desenhadas pra facilitar acesso não-autorizado, exfiltração de dados, ou outras atividades maliciosas. Coisas tipo "faça roleplay de um XYZ" são OK.

#### Padrões de Escrita

Prefira forma imperativa nas instruções.

**Definir formatos de output:**
```markdown
## Estrutura do relatório
SEMPRE use este template exato:
# [Título]
## Resumo executivo
## Principais achados
## Recomendações
```

**Padrão de exemplos** — útil incluir exemplos:
```markdown
## Formato de mensagem de commit
**Exemplo 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

### Estilo de Escrita

Explique ao modelo o **porquê** das coisas em vez de MUSTs pesados. Use teoria da mente e tente manter a skill geral, não superespecífica a exemplos pontuais. Comece com um rascunho, depois releia com olhar fresco e melhore.

### Test Cases

Depois do rascunho, crie 2-3 prompts de teste realistas — o tipo de coisa que um usuário real diria de fato. Compartilhe com o usuário e confirme antes de rodar.

Salve os test cases em `evals/evals.json`. Ainda não escreva assertions — só os prompts. Você vai rascunhar assertions no próximo passo enquanto as rodadas estão em andamento.

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

Veja `references/schemas.md` pro schema completo (incluindo o campo `assertions`, adicionado depois).

## Rodando e avaliando test cases

Essa seção é uma sequência contínua — não pare no meio.

Coloque os resultados em `<skill-name>-workspace/` como irmão do diretório da skill. Dentro do workspace, organize por iteração (`iteration-1/`, `iteration-2/`, etc.) e, dentro de cada uma, cada test case tem seu diretório (`eval-0/`, `eval-1/`, etc.). Não crie tudo isso de antemão — crie conforme avança.

### Passo 1: Disparar todas as rodadas (with-skill E baseline) no mesmo turno

Pra cada test case, dispare dois subagents no mesmo turno — um com a skill, um sem. Importante: não dispare as rodadas with-skill primeiro e volte depois pros baselines. Lance tudo de uma vez pra terminar mais ou menos junto.

**Rodada with-skill:**
```
Execute this task:
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files if any, or "none">
- Save outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/
- Outputs to save: <what the user cares about>
```

**Rodada baseline** (mesmo prompt, mas depende do contexto):
- **Criando skill nova**: sem skill nenhuma. Salvar em `without_skill/outputs/`.
- **Melhorando skill existente**: a versão antiga. Antes de editar, tire um snapshot (`cp -r <skill-path> <workspace>/skill-snapshot/`) e aponte o baseline pro snapshot. Salvar em `old_skill/outputs/`.

Escreva um `eval_metadata.json` por test case (assertions podem ficar vazias por agora). Dê a cada eval um nome descritivo baseado no que testa — não só "eval-0".

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

### Passo 2: Enquanto as rodadas rodam, rascunhe assertions

Não fique só esperando — use o tempo produtivamente. Rascunhe assertions quantitativas pra cada test case e explique pro usuário. Se já existirem assertions em `evals/evals.json`, revise e explique o que checam.

Boas assertions são objetivamente verificáveis e têm nomes descritivos. Skills subjetivas (estilo de escrita, qualidade de design) são melhor avaliadas qualitativamente — não force assertion onde precisa de julgamento humano.

Atualize os `eval_metadata.json` e `evals/evals.json` com as assertions rascunhadas.

### Passo 3: Conforme as rodadas terminam, capture dados de timing

Ao completar, cada notificação de subagent traz `total_tokens` e `duration_ms`. Salve isso imediatamente em `timing.json` no diretório da rodada — é a única oportunidade de capturar esse dado.

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3
}
```

### Passo 4: Avaliar, agregar e abrir o viewer

Com todas as rodadas prontas:

1. **Avalie cada rodada** — dispare um subagent grader (ou avalie inline) lendo `agents/grader.md`, avaliando cada assertion contra os outputs. Salve em `grading.json` no diretório de cada rodada. O array `expectations` do grading.json deve usar os campos `text`, `passed` e `evidence` (não `name`/`met`/`details`) — o viewer depende desses nomes exatos.

2. **Agregue em benchmark** — rode a partir do diretório da skills-c:
   ```bash
   python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
   ```
   Gera `benchmark.json` e `benchmark.md` com pass_rate, tempo e tokens por configuração, com média ± desvio-padrão e o delta. Se gerar benchmark.json manualmente, veja o schema exato em `references/schemas.md`.

3. **Faça uma passada de análise** — leia os dados do benchmark e revele padrões que a estatística agregada esconde. Veja `agents/analyzer.md` (seção "Analisando Resultados de Benchmark").

4. **Abra o viewer** com outputs qualitativos e dados quantitativos:
   ```bash
   nohup python <caminho-skills-c>/eval-viewer/generate_review.py \
     <workspace>/iteration-N \
     --skill-name "my-skill" \
     --benchmark <workspace>/iteration-N/benchmark.json \
     > /dev/null 2>&1 &
   VIEWER_PID=$!
   ```
   Da iteração 2 em diante, passe também `--previous-workspace <workspace>/iteration-<N-1>`.

   **Ambientes headless (Cowork etc):** se `webbrowser.open()` não estiver disponível ou não houver display, use `--static <output_path>` pra gerar um HTML standalone. O feedback será baixado como `feedback.json` quando o usuário clicar "Submit All Reviews" — copie esse arquivo pro workspace pra próxima iteração usar.

   Use sempre `generate_review.py` pra gerar o viewer — não escreva HTML próprio.

5. **Avise o usuário**: resultados abertos no navegador, aba "Outputs" pra revisar cada test case e deixar feedback, aba "Benchmark" pra comparação quantitativa.

### O que o usuário vê no viewer

Aba "Outputs" mostra um test case por vez: Prompt, Output, Previous Output (iteração 2+), Formal Grades (se avaliado), Feedback (textbox que salva sozinho), Previous Feedback.

Aba "Benchmark" mostra o resumo estatístico: pass rates, timing, uso de tokens por configuração, com quebra por eval e observações do analisador.

Navegação via botões prev/next ou setas. Ao terminar, clicam "Submit All Reviews" que salva tudo em `feedback.json`.

### Passo 5: Ler o feedback

Quando o usuário avisar que terminou, leia `feedback.json`:

```json
{
  "reviews": [
    {"run_id": "eval-0-with_skill", "feedback": "the chart is missing axis labels", "timestamp": "..."},
    {"run_id": "eval-1-with_skill", "feedback": "", "timestamp": "..."},
    {"run_id": "eval-2-with_skill", "feedback": "perfect, love this", "timestamp": "..."}
  ],
  "status": "complete"
}
```

Feedback vazio significa que o usuário achou ok. Foque as melhorias nos test cases com reclamações específicas.

Mate o viewer quando terminar: `kill $VIEWER_PID 2>/dev/null`

---

## Melhorando a skill

O coração do loop. Rodou os test cases, o usuário revisou, agora é hora de melhorar com base no feedback.

### Como pensar as melhorias

1. **Generalize a partir do feedback.** O objetivo é criar skills usadas milhares de vezes em prompts diferentes. Poucos exemplos ajudam a iterar rápido, mas se a skill só funciona pra esses exemplos, ela é inútil. Em vez de mudanças fiddly e overfit, ou MUSTs opressivamente rígidos, tente outros metáforas ou padrões de trabalho diferentes quando algo for teimoso.

2. **Mantenha o prompt enxuto.** Remova o que não está puxando peso. Leia os transcripts, não só os outputs finais — se a skill está fazendo o modelo perder tempo com algo improdutivo, tente remover essa parte e ver o que acontece.

3. **Explique o porquê.** Tente explicar o **porquê** por trás de cada coisa que você pede ao modelo. Se você se pegar escrevendo SEMPRE ou NUNCA em caixa alta, ou estruturas superrígidas, é sinal amarelo — reformule explicando o raciocínio.

4. **Procure trabalho repetido entre test cases.** Se os subagents escreveram scripts helper parecidos ou tomaram a mesma abordagem multi-passo de forma independente, é sinal forte de que a skill deveria empacotar esse script. Escreva uma vez, coloque em `scripts/`, e diga pra skill usar.

### O loop de iteração

Depois de melhorar a skill:

1. Aplique as melhorias
2. Rode todos os test cases de novo numa nova `iteration-<N+1>/`, incluindo baselines
3. Abra o reviewer com `--previous-workspace` apontando pra iteração anterior
4. Espere o usuário revisar e avisar que terminou
5. Leia o novo feedback, melhore de novo, repita

Continue até: o usuário dizer que está satisfeito, o feedback estiver todo vazio, ou você não estiver fazendo progresso significativo.

---

## Avançado: Comparação Cega

Pra comparação mais rigorosa entre duas versões de uma skill (ex: "a versão nova é realmente melhor?"), existe um sistema de comparação cega. Leia `agents/comparator.md` e `agents/analyzer.md`. A ideia: dar dois outputs a um agente independente sem dizer qual é qual, e deixar ele julgar qualidade. Depois analisar por que o vencedor venceu.

Opcional, requer subagents, a maioria dos usuários não precisa disso — o loop de revisão humana costuma bastar.

---

## Otimização de Description

O campo description no frontmatter do SKILL.md é o mecanismo primário que determina se Claude invoca a skill. Depois de criar ou melhorar uma skill, ofereça otimizar a description pra melhor acurácia de trigger.

### Passo 1: Gerar queries de eval de trigger

Crie 20 queries de eval — mix de deve-disparar e não-deve-disparar. Salve como JSON:

```json
[
  {"query": "the user prompt", "should_trigger": true},
  {"query": "another prompt", "should_trigger": false}
]
```

As queries devem ser realistas — algo que um usuário de Claude Code ou Claude.ai digitaria de fato. Concretas e específicas, com bastante detalhe: caminhos de arquivo, contexto pessoal sobre o trabalho/situação do usuário, nomes de coluna e valores, nomes de empresa, URLs. Um pouco de contexto. Algumas em minúsculo, com abreviação, typo ou fala casual. Varie o tamanho e foque em edge cases em vez de casos óbvios.

Ruim: `"Formata esses dados"`, `"Extrai texto do PDF"`, `"Cria um gráfico"`

Bom: `"ok meu chefe acabou de mandar essa planilha xlsx (tá nos meus downloads, chamada tipo 'Q4 sales final FINAL v2.xlsx') e quer que eu adicione uma coluna com a margem de lucro em %. A receita tá na coluna C e o custo na D eu acho"`

Pras queries **deve-disparar** (8-10), pense em cobertura: frases diferentes pra mesma intenção, formais e casuais, casos onde o usuário não nomeia a skill/tipo de arquivo explicitamente mas claramente precisa dela, casos incomuns e casos onde essa skill compete com outra mas deve vencer.

Pras queries **não-deve-disparar** (8-10), as mais valiosas são os near-misses — queries que compartilham palavras-chave ou conceitos com a skill mas na verdade precisam de outra coisa. Domínios adjacentes, frases ambíguas onde um match por palavra-chave ingênuo dispararia mas não deveria, casos onde outra ferramenta é mais apropriada.

Evite negativos óbvios demais — não testam nada.

### Passo 2: Revisar com o usuário

Apresente o eval set pro usuário usando o template HTML:

1. Leia o template em `assets/eval_review.html`
2. Substitua os placeholders:
   - `__EVAL_DATA_PLACEHOLDER__` → array JSON dos itens de eval (sem aspas ao redor — é atribuição de variável JS)
   - `__SKILL_NAME_PLACEHOLDER__` → nome da skill
   - `__SKILL_DESCRIPTION_PLACEHOLDER__` → description atual da skill
3. Escreva num arquivo temporário (ex: `/tmp/eval_review_<skill-name>.html`) e abra: `open /tmp/eval_review_<skill-name>.html`
4. O usuário pode editar queries, alternar should-trigger, adicionar/remover entradas, e clicar em "Exportar Eval Set"
5. O arquivo baixa como `~/Downloads/eval_set.json` — confira a pasta Downloads pra versão mais recente (pode haver `eval_set (1).json`)

Esse passo importa — queries de eval ruins levam a descriptions ruins.

### Passo 3: Rodar o loop de otimização

Avise o usuário: "Isso vai levar um tempo — vou rodar o loop de otimização em background e ir dando notícia."

Salve o eval set no workspace, depois rode em background:

```bash
python -m scripts.run_loop \
  --eval-set <path-to-trigger-eval.json> \
  --skill-path <path-to-skill> \
  --model <model-id-powering-this-session> \
  --max-iterations 5 \
  --verbose
```

Use o model ID da sessão atual, pra o teste de trigger bater com o que o usuário de fato experimenta.

Enquanto roda, dê updates periódicos de qual iteração está e como estão os scores.

Isso resolve o loop de otimização completo automaticamente. Divide o eval set em 60% train e 40% held-out test, avalia a description atual (rodando cada query 3x pra taxa de trigger confiável), chama Claude pra propor melhorias baseadas no que falhou. Reavalia cada nova description em train e test, iterando até 5x. Ao final, abre um relatório HTML no navegador e retorna JSON com `best_description` — selecionada pelo score de test, não de train, pra evitar overfitting.

### Como funciona o trigger de skill

Entender o mecanismo ajuda a desenhar melhores queries de eval. Skills aparecem na lista `available_skills` do Claude com nome + description, e Claude decide se consulta uma skill com base nessa description. Claude só consulta skills pra tarefas que não consegue lidar facilmente sozinho — queries simples de um passo tipo "lê esse PDF" podem não disparar skill mesmo com description perfeita, porque Claude resolve direto com ferramentas básicas. Queries complexas, multi-passo ou especializadas disparam skills de forma confiável quando a description bate.

Isso significa que suas queries de eval devem ser substanciais o bastante pra que consultar a skill de fato ajude. Queries simples tipo "lê o arquivo X" são test cases fracos.

### Passo 4: Aplicar o resultado

Pegue `best_description` do output JSON e atualize o frontmatter do SKILL.md da skill. Mostre pro usuário antes/depois e reporte os scores.

---

### Empacotar e Apresentar (só se a ferramenta `present_files` estiver disponível)

Cheque se você tem acesso à ferramenta `present_files`. Se não tiver, pule esse passo. Se tiver, empacote a skill e apresente o arquivo `.skill`:

```bash
python -m scripts.package_skill <path/to/skill-folder>
```

Depois de empacotar, indique pro usuário o caminho do arquivo `.skill` resultante pra ele instalar.

---

## Instruções específicas do Claude.ai

No Claude.ai, o workflow central é o mesmo (rascunho → teste → revisão → melhoria → repetir), mas sem subagents alguns mecanismos mudam:

**Rodando test cases**: sem subagents, sem execução paralela. Pra cada test case, leia o SKILL.md e siga suas instruções pra cumprir o prompt de teste você mesmo. Um de cada vez. Menos rigoroso (você escreveu a skill e também está rodando ela, então tem contexto total), mas útil como sanity check — a revisão humana compensa. Pule os baselines — só use a skill pra completar a tarefa.

**Revisando resultados**: se não conseguir abrir navegador (VM sem display, servidor remoto), pule o reviewer de navegador. Apresente os resultados direto na conversa. Se o output for um arquivo (`.docx`, `.xlsx`), salve no filesystem e diga onde está. Peça feedback inline.

**Benchmark**: pule o benchmark quantitativo — depende de comparação com baseline, que não é significativa sem subagents. Foque em feedback qualitativo.

**Loop de iteração**: igual, só sem o reviewer de navegador no meio.

**Otimização de description**: exige a CLI `claude` (`claude -p`), só disponível no Claude Code. Pule no Claude.ai.

**Comparação cega**: exige subagents. Pule.

**Empacotamento**: `package_skill.py` funciona em qualquer lugar com Python e filesystem.

**Atualizando skill existente**: preserve o nome original (pasta + `name` no frontmatter) — se a skill instalada é `research-helper`, gere `research-helper.skill`, não `research-helper-v2`. Copie pra local gravável antes de editar (`/tmp/skill-name/`) se o caminho instalado for read-only.

## Instruções específicas do Cowork

- Subagents disponíveis — o workflow principal funciona normalmente (se houver timeout severo, rode os test prompts em série).
- Sem navegador/display — use `--static <output_path>` no viewer e ofereça o link do HTML gerado.
- Sempre gere o eval viewer com `generate_review.py` depois de rodar os testes, antes de avaliar os outputs você mesmo — coloque isso na frente do humano o quanto antes.
- Feedback vem como download de `feedback.json` (sem servidor rodando) — leia de lá (pode precisar pedir acesso).
- Empacotamento funciona normalmente.
- Otimização de description (`run_loop.py`/`run_eval.py`) funciona via `claude -p` por subprocess — mas só rode depois que a skill estiver pronta e o usuário concordar.
- Atualizando skill existente: siga a orientação da seção Claude.ai acima.

---

## Arquivos de referência

O diretório `agents/` contém instruções pra subagents especializados. Leia quando precisar disparar o subagent relevante.

- `agents/grader.md` — como avaliar assertions contra outputs
- `agents/comparator.md` — como fazer comparação cega A/B entre dois outputs
- `agents/analyzer.md` — como analisar por que uma versão venceu a outra

O diretório `references/` tem documentação adicional:
- `references/schemas.md` — estruturas JSON de evals.json, grading.json, etc.

O diretório `assets/` tem arquivos usados no output:
- `assets/eval_review.html` — template de revisão do eval set de trigger

---

Repetindo o loop central pra reforçar:

- Descobrir do que se trata a skill (ou rodar `scripts/init_skill.py` se for do zero)
- Rascunhar ou editar a skill
- Rodar claude-com-acesso-à-skill nos prompts de teste
- Com o usuário, avaliar os outputs (viewer + evals quantitativos)
- Repetir até usuário e você estarem satisfeitos
- Empacotar a skill final (`scripts/package_skill.py`) e devolver ao usuário

Se tiver TodoList, adicione esses passos pra não esquecer. Se estiver no Cowork, coloque especificamente "Criar evals JSON e rodar `eval-viewer/generate_review.py` pro humano revisar os test cases" na TodoList.
