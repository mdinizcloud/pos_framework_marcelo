# gerador-docker

## 🎯 Propósito & Escopo
Gera ou corrige Dockerfile e docker-compose.yml pra qualquer stack, aplicando um conjunto fixo de regras de build/segurança/observabilidade — resolve o problema de containers mal configurados (root, `latest`, segredo hardcoded, sem healthcheck) chegando em produção.

## 🌟 Para que ela é útil?
Em vez de gerar um Dockerfile genérico de tutorial, a skill aplica uma lista extensa de regras de produção — multi-stage por stack, tag explícita, usuário não-root, `HEALTHCHECK` calibrado, segredo nunca em `ARG`/`ENV`, hardening de compose (`cap_drop`, `read_only`, `no-new-privileges`), rotação de log e sinalização correta pro `SIGTERM` — detectando a linguagem/framework automaticamente pelo manifesto de dependências do projeto. O valor real é fechar, numa única passada, o gap entre "container que sobe" e "container pronto pra produção", sinalizando com clareza qualquer mudança arriscada (troca de família de imagem, conversão de volume) antes de aplicá-la.

## 🛠️ Como usar?
- Pedido direto: criar, gerar, corrigir ou revisar Dockerfile ou docker-compose.
- Frases naturais: "containerizar", "subir com docker", "configurar docker", "criar imagem", "montar compose", "preparar docker".

## ⏳ Quando usar?
Sempre que o projeto precisa de configuração Docker nova ou existente precisa de correção — para qualquer linguagem/stack (Node.js, Python, Go, Java, .NET, Rust, PHP).
- Projeto sem Dockerfile/compose ainda, pronto pra containerizar.
- Dockerfile/compose existente com violação conhecida (imagem `latest`, `CMD` em shell form, segredo hardcoded, sem `HEALTHCHECK`).

## ✅ O que fazer?
- Identificar o escopo (Dockerfile, compose, ou ambos) e detectar a stack pelo manifesto de dependências presente (`package.json`, `requirements.txt`, `go.mod`, etc.).
- Ler arquivos existentes, identificar violações e marcar mudanças destrutivas sem aplicá-las ainda.
- Gerar ou corrigir diretamente tudo que não for destrutivo, seguindo as regras obrigatórias (multi-stage, tag explícita, usuário não-root, segredos via BuildKit secret mount, `.dockerignore`, ordem de camadas, `HEALTHCHECK`, `CMD` em exec form, hardening de compose, limite de recurso, `restart` policy, rotação de log, `init: true`).
- Atualizar `.gitignore` se criou volume ou `.env`.
- Validar sintaxe (`docker compose config`, lint do Dockerfile) — corrigir e revalidar se algo falhar, nunca declarar pronto com validação quebrada.
- Escanear vulnerabilidade se `docker scout`/`trivy` estiver disponível, e exibir a tabela de resumo final com todas as decisões.

## 🚫 O que NÃO fazer?
- Não aplicar automaticamente uma troca de família de imagem (`-alpine` ↔ `-slim`/distroless) ou conversão de tipo de volume — pode quebrar build já funcional; sinalizar e aguardar confirmação.
- Não usar tag `latest` em nenhuma imagem, nem `ARG` pra passar segredo (fica gravado na história das camadas).
- Não usar `CMD`/`ENTRYPOINT` em shell form — não repassa `SIGTERM` corretamente, travando o container até `SIGKILL`.
- Não expor porta de serviço interno (db, redis) publicamente quando só outros serviços do compose precisam dele.
- Não declarar a entrega pronta se a validação de sintaxe falhou.

## 📥 Parâmetros de Entrada (Inputs)
- Diretório do projeto (obrigatório) — usado pra detectar stack via manifesto (`package.json`, `requirements.txt`, `go.mod`, etc.).
- Dockerfile/docker-compose.yml existentes (opcional) — se presentes, entra em modo correção.
- Confirmação do usuário (obrigatório só pra mudanças destrutivas: troca de família de imagem, conversão de tipo de volume).

## 📤 Estrutura de Saída (Outputs)
- Dockerfile e/ou docker-compose.yml gerado/corrigido, `.dockerignore` e `.env.example` quando aplicável.
- Tabela de resumo final com 5 blocos: Build & imagem, Segurança, Armazenamento, Observabilidade & operação, Validação.

## 🔧 Dependências & Ferramentas
`docker compose config`, `hadolint` (ou `docker build --check` como fallback), `docker scout`/`trivy` se disponíveis (scan de vulnerabilidade) — nenhuma é obrigatória, ausência é só sinalizada no resumo.

## 💡 Casos de Uso Reais
- Prompt: "cria o Dockerfile e o compose pra essa API Node com Postgres." → Resposta: Dockerfile multi-stage com usuário não-root e `HEALTHCHECK`, compose com volume nomeado pro Postgres, limites de recurso e `restart: unless-stopped`, mais a tabela de resumo com cada decisão.

## ⚠️ Tratamento de Erros
- Mudança destrutiva detectada (troca de família de imagem, conversão de volume) → não aplicar automaticamente, sinalizar no resumo e aguardar confirmação.
- Validação de sintaxe falha → corrigir e validar de novo antes de declarar pronto, nunca entregar com erro conhecido.
