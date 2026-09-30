---
name: gerador-docker-v2
description: Gera ou corrige Dockerfile e docker-compose.yml seguindo regras específicas do projeto, para qualquer linguagem/stack (Node.js, Python, Go, Java, .NET, Rust, PHP). Use esta skill sempre que o usuário pedir para criar, gerar, corrigir ou revisar um Dockerfile ou docker-compose — mesmo que não use esses termos exatos. Também use quando o usuário mencionar "containerizar", "subir com docker", "configurar docker", "preparar docker", "criar imagem", "montar compose", ou qualquer variação que indique configuração de ambiente Docker para o projeto.
---

## O que esta skill faz

Gera Dockerfile e/ou docker-compose.yml do zero, ou corrige arquivos existentes, aplicando as regras abaixo sem pedir confirmação — exceto nos casos explicitamente marcados como destrutivos, onde é obrigatório avisar e aguardar confirmação antes de aplicar. Ao final, valida o resultado e exibe um resumo das decisões tomadas.

---

## Regras obrigatórias

### 1. Multi-stage build (qualquer linguagem)

Regra geral: multi-stage é justificado quando existe artefato compilável/transpilável/bundle que pode ser copiado pro runtime sem carregar a toolchain de build na imagem final. Stack só interpretado, sem etapa de build, não precisa.

Detecção de contexto por stack (Node.js, Python, Go, Java, .NET, Rust, PHP, Ruby, fallback genérico): ver `references/multi-stage-detection.md`.

### 2. Tag de imagem

- **Proibido** usar `latest`. Sempre especifique uma versão explícita (ex: `node:20-alpine`, `postgres:16-alpine`, `golang:1.22-alpine`).
- **Prefira Alpine** (`-alpine`) como padrão, por ser mais enxuta.
- **Exceção — trocar por `-slim` (Debian) ou distroless:** quando houver dependência nativa que exige glibc ou não tem build compatível com musl (ex: Prisma engine, alguns wheels Python `manylinux` sem variante musl, bibliotecas C sem porte Alpine). Documentar a escolha e o motivo na tabela de resumo final.
- **Pin por digest:** quando o usuário pedir build reprodutível/imutável (ex: pipeline de release, compliance), usar `imagem:tag@sha256:<digest>` em vez de só tag.
- **Mudança destrutiva — exigir confirmação:** se um Dockerfile existente já usa uma família de imagem (`-alpine`, `-slim`, distroless) intencionalmente e a correção implicaria trocar essa família, **não aplicar automaticamente** — pode quebrar build já funcional. Sinalizar a troca sugerida e o motivo no resumo e aguardar confirmação antes de aplicar.
- **Labels de proveniência:** todo Dockerfile ganha `LABEL org.opencontainers.image.revision="<git sha>"` e `org.opencontainers.image.version="<versão/tag>"` (usar `ARG GIT_SHA`/`ARG VERSION` passado no build) — permite correlacionar container rodando em produção com commit/versão exata durante incidente, sem depender de log de deploy externo.

### 3. Volumes no docker-compose

- **Código-fonte em dev (hot reload):** bind mount (`.:/app`).
- **Dado persistente (banco, cache, fila):** volume nomeado por padrão — Docker gerencia, evita problema de permissão e é mais performático no Docker Desktop (macOS/Windows). Bind mount em `.docker/` (ex: `.docker/postgres`) só quando o ambiente é dev **e** o usuário pedir explicitamente inspecionar o dado pelo host.
- Adicionar `.docker/` ao `.gitignore` quando usado.
- **Mudança destrutiva — exigir confirmação:** se um compose existente já usa volume nomeado com dado real e a correção implicaria convertê-lo para bind mount (ou vice-versa, com risco de perda de referência ao dado), **não aplicar automaticamente** — sinalizar a mudança e o risco no resumo e aguardar confirmação do usuário antes de tocar nesse volume.

### 4. Segurança e cache de camadas

- **Usuário não-root:** runtime stage sempre define `USER` não-root, exceto se a aplicação exigir bind em porta <1024 e isso for justificado no resumo final.
- **UID em bind mount dev:** quando o stage de dev roda como não-root **e** usa bind mount de código-fonte (`.:/app`), criar o usuário do container com o mesmo UID/GID do host. Mecanismo completo: `ARG UID=1000` / `ARG GID=1000` no Dockerfile (default 1000 cobre a maioria dos casos Linux/macOS); no compose, `build.args: {UID: "${HOST_UID:-1000}", GID: "${HOST_GID:-1000}"}`. **Não usar `$UID` direto** — é variável somente-leitura em bash e não é exportada por padrão. Usar nome próprio (`HOST_UID`/`HOST_GID`) e instruir o usuário a exportar antes de subir (`export HOST_UID=$(id -u) HOST_GID=$(id -g)`) ou gravar em `.env` do projeto (não versionado se tiver dado sensível, mas UID/GID não é segredo).
- **`.dockerignore`:** sempre gerar ou verificar `.dockerignore` na raiz junto com o Dockerfile, cobrindo no mínimo `.git`, dependências instaladas (`node_modules`, `vendor`, `venv`, etc.), `.env`, `.docker/`.
- **Ordem de camadas:** copiar arquivos de manifesto de dependências (`package.json`, `requirements.txt`, `go.mod`, `pom.xml`, `*.csproj`, `Cargo.toml`, etc.) e instalar dependências **antes** de copiar o restante do código-fonte, para maximizar cache de build.
- **`HEALTHCHECK`:** todo serviço que expõe porta ganha instrução `HEALTHCHECK` no Dockerfile ou `healthcheck` no docker-compose, com `start_period`/`start-period` calibrado pro tempo de boot real da stack (ex: JVM/app com migração no start precisa de start_period maior que o default) — evita falso-unhealthy/restart durante o próprio warmup.
- **`CMD`/`ENTRYPOINT` em exec form:** sempre usar forma de array (`CMD ["node", "server.js"]`), nunca shell form (`CMD npm start`) — shell form roda sob `/bin/sh -c` e não repassa `SIGTERM` pro processo filho, travando o container até `SIGKILL` em todo `docker stop`/deploy/restart.

### 5. Segredos

- **Runtime — proibido** hardcode de segredo (API key, senha, token) em `ENV` do Dockerfile ou direto no `docker-compose.yml`. Usar `env_file: .env` (com `.env` no `.gitignore`) ou Docker secrets.
- **Build-time — proibido** usar `ARG` para passar segredo (fica gravado na história das camadas mesmo removido depois). Usar BuildKit secret mount: `# syntax=docker/dockerfile:1` no topo do Dockerfile e `RUN --mount=type=secret,id=<nome> ...`, com `docker build --secret id=<nome>,src=<arquivo>` (ou equivalente `secrets:` no compose build).
- **`.env.example`:** sempre que gerar/usar `.env`, gerar também `.env.example` versionado (mesmas chaves, valores placeholder tipo `CHANGE_ME` ou vazio, nunca o valor real) — onboarding de novo dev/CI sabe quais variáveis são exigidas sem precisar do segredo real.

### 6. Exposição de rede

- Serviço interno (db, redis, etc.) **não** expõe porta publicamente — bind em `127.0.0.1:PORTA:PORTA` ou omitir `ports` inteiramente quando só outros serviços do compose precisam acessá-lo (usar `expose` em vez de `ports` nesse caso, se precisar documentar a porta sem publicá-la no host).
- Usar redes segmentadas (`networks`) quando houver camada frontend/backend, restringindo acesso do frontend a serviços de dado.

### 7. Hardening de compose

- Adicionar `security_opt: [no-new-privileges:true]`, `cap_drop: [ALL]` (com `cap_add` pontual só se necessário) e `read_only: true` (com `tmpfs` pros diretórios que precisam escrita, ex: `/tmp`, cache da aplicação) em serviços de aplicação.
- **Critério de compatibilidade:** teste local não-destrutivo, isolado de dependências pra não gerar falso positivo. Preferir `docker build` + `docker run --rm` só na imagem do serviço (sem `depends_on`) checando se o processo sobe e escreve o que precisa; se o serviço exigir banco/fila pra sequer iniciar, usar `docker compose up -d` do grafo completo (serviço + `depends_on`) em vez de isolado, senão a falha de conexão é confundida com falha de `read_only`. Checar porta livre antes de qualquer teste (se ocupada, pular e avisar no resumo). Derrubar tudo (`down`) logo depois. Não expõe dado nem é irreversível — por isso não entra no gate de confirmação da Regra 3/2, só documenta o resultado no resumo. Se falhar por causa de `read_only`, identificar o diretório exato que precisa de escrita e adicionar via `tmpfs` ou volume específico — nunca remover `read_only` de forma genérica só porque falhou uma vez.

### 8. Volumes anônimos em dev

- Ao usar bind mount de código-fonte em dev (`.:/app`), proteger diretórios gerados no container (`node_modules`, `.next`, `vendor`, cache de build) com volume anônimo (ex: `/app/node_modules`) pra não serem sobrescritos pelo bind mount do host.
- **Ownership do volume anônimo:** volume anônimo nasce com dono `root`. Se a Regra 4 definiu usuário não-root com UID/GID custom, garantir que o diretório protegido é criado/`chown`ado pro mesmo UID/GID **antes** do `USER` non-root assumir no Dockerfile (ex: `RUN mkdir -p /app/node_modules && chown -R ${UID}:${GID} /app/node_modules` antes do `USER app`) — senão o processo não-root não consegue escrever no próprio volume anônimo.

### 9. Prontidão de produção no compose

- **Limite de recurso:** **todo** serviço ganha `deploy.resources.limits` (`cpus`, `memory`) — inclusive db/redis/fila. Serviço de infra sem limite é causa clássica de OOM (Redis sem `maxmemory`, Postgres com `shared_buffers` mal calibrado) e derruba o host inteiro junto com os outros containers.
- **Restart policy:** todo serviço de longa duração (exclui jobs one-shot/migração) ganha `restart: unless-stopped` — volta sozinho após crash ou reboot do host, sem reiniciar em loop se for parado manualmente (`docker stop`).

### 10. Gestão de log

- Todo serviço ganha `logging.driver: json-file` com `options: {max-size: "10m", max-file: "3"}` (ou equivalente) — driver default do Docker não rotaciona sozinho e enche o disco do host indefinidamente ao longo do tempo.
- **Log estruturado:** aplicação deve logar em JSON pro `stdout`/`stderr` (nunca arquivo dentro do container) — formato não-parseável quebra correlação por campo em pipeline de observabilidade (Loki/ELK/etc). Se o framework tiver logger estruturado nativo (ex: pino/winston JSON, logrus/zap, structlog), configurar como padrão; senão, sinalizar a limitação no resumo em vez de forçar uma dependência nova.

### 11. Sinalização e desligamento gracioso

- **PID 1 / init:** todo serviço em compose ganha `init: true` (usa o `tini` embutido do Docker Engine como PID 1) — sem isso, processo zumbi de app multi-processo não é colhido e sinal pode não propagar corretamente pros filhos.
- **`stop_grace_period`:** calibrar acima do default de 10s quando a aplicação precisa drenar conexão em andamento antes de encerrar (ex: `stop_grace_period: 30s` pra API com request longa) — evita `SIGKILL` prematuro cortando request no meio.

---

## Processo de execução

1. **Identifique o escopo:** o usuário quer Dockerfile, docker-compose, ou ambos?
2. **Detecte a stack:** identifique a linguagem/framework pelo arquivo de manifesto presente (`package.json`, `requirements.txt`/`pyproject.toml`, `go.mod`, `pom.xml`/`build.gradle`, `*.csproj`, `Cargo.toml`, `composer.json`) e aplique a lógica de detecção da Regra 1 correspondente.
3. **Verifique arquivos existentes:** se Dockerfile ou docker-compose.yml já existem, leia-os e identifique violações. Marque mudanças destrutivas (Regra 3) sem aplicar ainda.
4. **Gere ou corrija:** crie do zero ou aplique as correções necessárias diretamente, exceto mudanças destrutivas marcadas no passo 3 — essas aguardam confirmação.
5. **Atualize `.gitignore`:** se criou volumes ou `.env`, garanta que estão no `.gitignore`.
6. **Valide o resultado:** rode `docker compose config --quiet` (se houver compose) para checar sintaxe. Pra Dockerfile: se `hadolint` estiver disponível, rode contra o Dockerfile; senão, use `docker build --check .` (linter nativo do BuildKit, sem instalar nada extra) como fallback. Se algo falhar, corrija e valide de novo antes de fechar — nunca declare pronto com validação falhando.
7. **Escaneie vulnerabilidade:** depois do build, se `docker scout` ou `trivy` estiver disponível no ambiente, rodar contra a imagem final e reportar CVE crítico/alto no resumo. Se nenhuma ferramenta estiver disponível, registrar no resumo que o scan não foi executado (não bloquear a entrega por isso, só não omitir a lacuna).
8. **Exiba o resumo:** ao final, mostre uma tabela com as decisões tomadas.

---

## Resumo final (sempre exibir)

Após gerar ou corrigir os arquivos, mostre:

```
## Decisões aplicadas

### Build & imagem

| Regra | Situação | Ação |
|---|---|---|
| Stack detectada | [linguagem/framework] | [manifesto usado pra detectar] |
| Multi-stage build | [contexto detectado] | [o que foi feito] |
| Tag de imagem | [tags utilizadas] | [ok / corrigido / trocado p/ slim-distroless + motivo] |
| Labels de proveniência | [git sha/versão presente?] | [ok / adicionado] |
| Ordem de camadas | [deps antes do código?] | [ok / corrigido] |
| .dockerignore | [presente e completo?] | [ok / criado / corrigido] |

### Segurança

| Regra | Situação | Ação |
|---|---|---|
| Usuário não-root | [USER definido?] | [ok / corrigido / justificado root] |
| UID bind mount dev | [UID host=container?] | [ok / corrigido / n/a] |
| Segredos (runtime) | [hardcode encontrado?] | [ok / corrigido] |
| Segredos (build-time) | [ARG com segredo encontrado?] | [ok / migrado p/ BuildKit secret mount] |
| .env.example | [presente e sincronizado?] | [ok / criado / corrigido] |
| Exposição de rede | [portas internas expostas?] | [ok / corrigido] |
| Hardening compose | [security_opt/cap_drop/read_only] | [ok / adicionado] |
| Scan de vulnerabilidade | [docker scout / trivy] | [passou / CVE encontrado / não executado] |

### Armazenamento

| Regra | Situação | Ação |
|---|---|---|
| Volumes | [bind mount ou nomeado, por serviço] | [ok / criado / corrigido / PENDENTE confirmação] |
| .gitignore | [.docker/ e .env presentes?] | [ok / adicionado] |
| Volumes anônimos (dev) | [node_modules/cache protegido?] | [ok / adicionado / n/a] |

### Observabilidade & operação

| Regra | Situação | Ação |
|---|---|---|
| HEALTHCHECK | [presente + start_period calibrado?] | [ok / adicionado] |
| CMD exec form | [shell form encontrado?] | [ok / corrigido] |
| Gestão de log | [max-size/max-file] | [ok / adicionado] |
| Log estruturado | [JSON no stdout?] | [ok / configurado / limitação sinalizada] |
| PID 1 / init | [init: true presente?] | [ok / adicionado] |
| stop_grace_period | [calibrado?] | [ok / adicionado / default mantido] |
| Limite de recurso | [deploy.resources.limits] | [ok / adicionado] |
| Restart policy | [restart: unless-stopped] | [ok / adicionado] |

### Validação

| Regra | Situação | Ação |
|---|---|---|
| Sintaxe/lint | [docker compose config / hadolint / build --check] | [passou / corrigido após falha] |
```

Se nenhum arquivo existia antes, indique "gerado do zero" na coluna Situação. Se houver item PENDENTE confirmação, listar claramente após a tabela o que precisa da decisão do usuário antes de prosseguir.
