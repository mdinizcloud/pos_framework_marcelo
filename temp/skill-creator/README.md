# skill-creator

## 🎯 Propósito & Escopo
Cria novas skills, edita e melhora skills existentes, e mede performance de skill via evals/benchmark. Combina scaffolding rápido (`init_skill.py`) com o loop completo de teste/benchmark/otimização de description (`run_eval.py`, `run_loop.py`, `improve_description.py`), incluindo empacotamento final (`package_skill.py`) pra distribuição.

## 🌟 Para que ela é útil?
Padroniza o ciclo de vida completo de uma skill de Claude Code — do rascunho inicial até a otimização objetiva do trigger — em vez de deixar cada skill nascer com estrutura, `description` e cobertura de teste diferentes. O ponto central é que "sub-disparo" (Claude não usar a skill quando seria útil) é tratado como a falha mais comum de `description`, e a skill oferece um loop mensurável (evals com baseline vs. com-skill, viewer HTML de comparação, otimização automática via `improve_description.py`) em vez de só "achismo" sobre se a description está boa.

## 🛠️ Como usar?
- Pedir para criar uma skill do zero ("cria uma skill pra X", "transforma isso numa skill")
- Pedir para editar ou otimizar uma skill existente
- Pedir para rodar evals numa skill, testar se o trigger funciona, ou comparar performance com baseline
- Dizer "essa skill não tá disparando direito", "empacota essa skill", "quero testar se essa skill funciona"
- Rodar os scripts diretamente: `python scripts/init_skill.py <nome> --path <dir>`, `python scripts/quick_validate.py <skill-dir>`, `python -m scripts.run_eval --eval-set <json> --skill-path <dir> [opções]`, `python -m scripts.run_loop --eval-set <json> --skill-path <dir> --model <modelo> [opções]`, `python -m scripts.improve_description --eval-results <json> --skill-path <dir> --model <modelo>`, `python scripts/aggregate_benchmark.py <benchmark-dir> [--skill-name][--skill-path][--output]`, `python scripts/generate_report.py <input> [-o][--skill-name]`, `python scripts/package_skill.py <skill-dir> [output-dir]`

## ⏳ Quando usar?
- Sempre que o trabalho for sobre a skill em si (Claude Agent Skills), não sobre o conteúdo/domínio que a skill vai cobrir
- Criação do zero: quando não existe pasta/`SKILL.md` ainda
- Edição/iteração: quando já existe um rascunho e o usuário quer melhorar comportamento ou trigger
- Medição: quando o usuário quer prova objetiva (evals, comparação com/sem skill, otimização de description) em vez de avaliação subjetiva

## ✅ O que fazer?
- Rodar `init_skill.py` primeiro se for skill nova do zero — pula essa etapa se já existir (edição/iteração)
- Capturar a intenção do usuário: o que a skill deve permitir fazer, quando deve disparar, formato de output esperado, se vale criar test cases (skills com output objetivamente verificável se beneficiam mais)
- Entrevistar proativamente sobre edge cases, formatos de input/output, arquivos de exemplo, critérios de sucesso e dependências antes de escrever prompts de teste
- Escrever a `description` como o mecanismo primário de trigger — incluir o que a skill faz E os contextos específicos de quando usar, de forma um pouco "insistente" pra combater sub-disparo
- Manter o corpo do `SKILL.md` abaixo de ~500 linhas, com divulgação progressiva (metadados sempre no contexto → corpo quando dispara → `scripts/`/`references/`/`assets/` sob demanda)
- Disparar as rodadas with-skill e baseline no mesmo turno, avaliar e agregar os resultados, abrir o viewer HTML de comparação, ler o feedback do usuário
- Depois que a skill estiver pronta, rodar o otimizador de description (`run_loop.py`/`improve_description.py`) pra melhorar a taxa de acerto do trigger
- Calibrar o nível de jargão técnico pela familiaridade do usuário (termos como "avaliação"/"benchmark" são OK direto; "JSON"/"assertion" só com sinal claro de que o usuário conhece)

## 🚫 O que NÃO fazer?
- Não seguir o processo completo à risca quando o usuário pede flexibilidade explícita (ex.: "não precisa rodar avaliação, só no feeling") — flexibilidade importa mais que o processo
- Não criar skill com malware, exploit code, ou conteúdo que comprometa segurança do sistema, nem skill enganosa desenhada pra facilitar acesso não-autorizado ou exfiltração de dados (Princípio da Não-Surpresa)
- Não deixar o corpo do `SKILL.md` crescer sem limite — perto de 500 linhas, adicionar mais uma camada de hierarquia com ponteiros claros em vez de inflar o corpo principal
- Não confundir "quando usar" (vai só na `description`) com conteúdo do corpo do `SKILL.md`

## 📥 Parâmetros de Entrada (Inputs)
- `scripts/init_skill.py <skill-name> --path <path>` — nome kebab-case (máx. 40 caracteres, letras minúsculas/dígitos/hífen, igual ao nome da pasta) e path de saída (obrigatórios)
- `scripts/quick_validate.py <skill-dir>` — path da skill (obrigatório)
- `scripts/run_eval.py --eval-set <json> --skill-path <dir> [--description][--num-workers][--timeout][--runs-per-query][--trigger-threshold][--model][--verbose]`
- `scripts/run_loop.py --eval-set <json> --skill-path <dir> --model <modelo> [--description][--num-workers][--timeout][--max-iterations][--runs-per-query][--trigger-threshold][--holdout][--verbose][--report][--results-dir]`
- `scripts/improve_description.py --eval-results <json> --skill-path <dir> --model <modelo> [--history][--verbose]`
- `scripts/aggregate_benchmark.py <benchmark_dir> [--skill-name][--skill-path][--output]`
- `scripts/generate_report.py <input ou "-" para stdin> [-o/--output][--skill-name]`
- `scripts/package_skill.py <skill-dir> [output-dir]`

## 📤 Estrutura de Saída (Outputs)
- Skill nova ou editada: `SKILL.md` + `README.md` + `scripts/`/`references/`/`assets/` conforme necessário
- Resultados de eval (JSON) por rodada with-skill/baseline, agregados em estatísticas de performance (`aggregate_benchmark.py`)
- Relatório HTML de comparação (`generate_report.py`, a partir da saída de `run_loop.py`) — o "viewer" que o usuário lê pra dar feedback
- `description` otimizada (`improve_description.py`), com histórico de tentativas anteriores se `--history` for passado
- Pacote `.zip` validado e pronto pra distribuição (`package_skill.py`, roda `quick_validate.py` antes de empacotar)

## 🔧 Dependências & Ferramentas
- Toolchain Python local em `scripts/`: `init_skill.py`, `quick_validate.py`, `package_skill.py`, `run_eval.py`, `run_loop.py`, `improve_description.py`, `aggregate_benchmark.py`, `generate_report.py`, `utils.py` (parsing compartilhado de `SKILL.md`)
- `agents/analyzer.md`, `agents/comparator.md`, `agents/grader.md` — definições de subagent usadas no loop de avaliação/comparação
- `eval-viewer/generate_review.py` + `eval-viewer/viewer.html` — geração e visualização do review HTML de evals
- `references/schemas.md` — schemas de referência consultados durante a escrita/validação
- `assets/eval_review.html` — asset de template usado na geração do review
- Chamada de modelo (`--model`) pra rodar evals/otimização — requer acesso a um modelo Claude configurado no ambiente

## 💡 Casos de Uso Reais
O SKILL.md traz exemplos concretos de calibração de `description` (o exemplo "Como montar um dashboard simples..." reescrito de forma mais "insistente" pra combater sub-disparo) e um template fixo de estrutura de relatório (`# [Título]` / `## Resumo executivo` / `## Principais achados` / `## Recomendações`) — não é um caso de uso ponta a ponta com prompt/resposta reais, mas os exemplos de escrita são concretos e reaproveitáveis.

## ⚠️ Tratamento de Erros
- Divergência de resultado entre rodada with-skill e baseline é o próprio sinal que a skill usa pra decidir se precisa iterar — não é tratado como erro do harness, é o dado central do processo
- Não há seção dedicada no SKILL.md a erro de execução dos scripts (ex.: eval-set malformado, modelo indisponível) — o comportamento nesses casos fica a cargo das mensagens de erro nativas de cada script Python (ex.: `argparse` reporta argumento obrigatório ausente)
- `package_skill.py` roda `quick_validate.py` antes de empacotar — skill inválida não gera pacote `.zip`
