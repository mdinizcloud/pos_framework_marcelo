# reducao-token

## 🎯 Propósito & Escopo
Reduz o tamanho (tokens) de uma skill (SKILL.md), agent (definição/system prompt) ou prompt de IA sem perder nenhuma regra, exemplo ou comportamento — comprime só a prosa (redundância, conectivos, frases longas), mantendo checklist, exemplo e seção marcada como intocável (template, schema, bloco de código) byte a byte. Escopo é exclusivo pra artefato de IA — nunca documento de negócio/arquitetura (ADR, TDR, PDR, RFC, especificação, relatório, ata, contrato).

## 🌟 Para que ela é útil?
Diferencia explicitamente "reduzir" de "resumir": aqui perda de conteúdo ou de comportamento é sempre erro, nunca objetivo. O valor central é a validação funcional — a skill exige rodar um baseline com o alvo original, rodar o mesmo teste com o alvo reduzido, e provar numa tabela markdown que a saída se mantém idêntica com menos tokens (contados de verdade via API, não estimativa). Isso resolve o risco comum de compressão de prompt/skill "quebrar" um comportamento sutil sem ninguém notar.

## 🛠️ Como usar?
- Pedir para "reduzir token", "compactar", "deixar mais enxuto/conciso" uma skill/agent/prompt, ou "gera o mesmo resultado só que menor" — mesmo sem usar a palavra "token"
- Rodar o harness diretamente: `python scripts/token_validate.py count <original> [reduzido]` (só contagem) ou `python scripts/token_validate.py validate <original> <reduzido> --cases casos.json [--model M] [--role system|user] [--effort low|medium|high|xhigh|max] [--match exact|rules]`

## ⏳ Quando usar?
- Alvo é SKILL.md, definição/system prompt de agent, ou prompt reusável que precisa caber em menos tokens
- NÃO usar para documento de negócio/arquitetura (ADR, TDR, PDR, RFC, especificação técnica, relatório, ata, contrato) — mesmo que o pedido use "reduzir"/"compactar", esse escopo é de outra ferramenta
- NÃO usar quando o pedido é "resumir", "simplificar o conteúdo" ou "cortar partes menos importantes" — isso é resumo com perda intencional, objetivo oposto desta skill

## ✅ O que fazer?
- Ler o alvo inteiro antes de comprimir qualquer trecho — seção não lida é regra que pode se perder na saída
- Identificar seções intocáveis (blocos de código, templates literais, exemplos concretos) e copiá-las byte a byte, sem tocar espaço/quebra de linha/palavra
- Rodar baseline funcional ANTES de comprimir: fixar 2–3 casos de teste (incluindo caso de borda) num `casos.json`, executar o alvo original com `effort: low` (nunca `temperature`, rejeitada com 400 pelos modelos atuais) e guardar a saída literal — de preferência via `scripts/token_validate.py`, que conta tokens reais pela API
- Montar o inventário de regras do original (cada item de checklist, regra/restrição declarada, exemplo concreto, campo obrigatório citado) — é o critério de aceite
- Comprimir só a prosa: remover conectivo redundante, fundir frases repetidas, trocar termo longo por curto equivalente, preferir voz ativa — sem apagar checklist/exemplo/regra nem generalizar regra específica
- Testar a versão comprimida com os mesmos casos/inputs do baseline e comparar: contra o inventário (nada sumiu) e baseline × reduzido (saída bate)
- Se houver perda de qualidade/regra ou divergência de saída, desfazer o excesso da compressão e testar de novo — nunca entregar "quase igual"
- Salvar como arquivo novo (sufixo de versão como `_v2`/`_v3`, ou caminho indicado) — não sobrescrever o original sem pedido explícito
- Reportar com a tabela de prova (tokens/caracteres original vs reduzido, saída por caso, inventário preservado sim/não)

## 🚫 O que NÃO fazer?
- Não apagar item de checklist, exemplo ou regra "pra resumir"
- Não generalizar 2 regras específicas numa regra vaga que perde precisão
- Não remover o "porquê" de uma regra quando isso muda como o leitor a aplica em caso de dúvida
- Não tocar em seção marcada como intocável
- Não comprimir a ponto de virar telegrafês ambíguo (abreviação obscura, corte de conectivo essencial que muda o sentido)
- Não adicionar meta-comentário sobre a própria compressão dentro do arquivo reduzido (changelog vai no git/PR, não no corpo)
- Não trocar termo técnico exato por sinônimo impreciso (ex.: não trocar "idempotente" por "que pode repetir")
- Não usar `tiktoken` para contar tokens — subestima tokens de modelos Claude; usar a API `count_tokens` (é o que `token_validate.py` faz)

## 📥 Parâmetros de Entrada (Inputs)
- Arquivo(s) alvo: SKILL.md, definição de agent ou prompt reusável (path)
- `scripts/token_validate.py count <original> [reduzido]` — original obrigatório, reduzido opcional (calcula delta se os dois forem passados), `--model` opcional
- `scripts/token_validate.py validate <original> <reduzido> --cases <casos.json>` — original e reduzido obrigatórios, `--cases` obrigatório (JSON `[{name, input}, ...]`), `--model`, `--role {system,user}`, `--effort {low,medium,high,xhigh,max}` e `--match {exact,rules}` opcionais
- Seções intocáveis explicitadas pelo usuário (ou inferidas por padrão: blocos de código, templates literais, exemplos concretos)

## 📤 Estrutura de Saída (Outputs)
- Arquivo reduzido salvo como novo arquivo (sufixo de versão ou caminho indicado), preservando formatação markdown
- Tabela de prova em markdown: Tokens (API), Caracteres, saída por caso de teste (original vs reduzido, igual?), inventário de regras preservadas (Sim/Não) — gerada automaticamente por `scripts/token_validate.py validate`, ou preenchida manualmente por simulação (marcada como estimativa) se não houver acesso à API
- Fechamento em 1–2 frases: quanto reduziu em tokens, o que ficou intocado, confirmação de que baseline e reduzido geraram a mesma saída em todos os casos

## 🔧 Dependências & Ferramentas
- `scripts/token_validate.py` — único script da skill; subcomandos `count` (conta tokens/chars, delta se 2 arquivos) e `validate` (roda os casos nos dois alvos e emite a tabela de prova)
- API externa de contagem de tokens (`count_tokens`) e de execução do modelo (para rodar baseline/reduzido) — usada pelo `token_validate.py`; sem acesso a ela, a skill cai para simulação manual (marcada como estimativa, não prova)
- `--match rules` usa um LLM-judge de equivalência comportamental (pra tarefa de geração aberta); `--match exact` exige string idêntica (pra tarefa determinística)

## 💡 Casos de Uso Reais
O SKILL.md traz um exemplo concreto de compressão (não um caso de uso ponta a ponta, mas um exemplo de calibração de técnica): uma regra de tool-use sobre confirmar antes de apagar arquivo/reescrever histórico git é reescrita de 4 linhas pra 3, mantendo mesmo gatilho, mesma obrigação de parar e explicar risco, mesma proibição de prosseguir sem confirmação.

## ⚠️ Tratamento de Erros
- `token_validate.py validate` sai com código ≠ 0 se qualquer caso divergir entre original e reduzido — divergência é tratada como falha a investigar, nunca como "provável ok"
- Se a validação encontrar perda de qualidade, regra sumida ou saída divergente, o fluxo documentado é desfazer o excesso da compressão e repetir o teste — não há "aceitar com ressalva"
- Sem acesso à API de contagem/execução, a skill não bloqueia: cai pra simulação no próprio contexto, mas essa saída deve ser marcada explicitamente como estimativa, não prova externa
- Não há tratamento documentado para `casos.json` malformado ou para o próprio `token_validate.py` falhar ao chamar a API (ex.: erro de rede/autenticação)
