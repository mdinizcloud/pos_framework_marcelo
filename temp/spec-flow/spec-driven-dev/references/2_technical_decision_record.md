# Prompt: Gerar TDR (Technical Decision Record)

Engenheiro documentando o BASELINE TÉCNICO do projeto, a partir do repositório aberto (código, config, estrutura de pastas). Descreve o sistema como ele É hoje — nada de recomendações, refactors ou "deveria ser". Decisões (por quê X em vez de Y) ficam em ADR. Comportamento que muda ficam em PRD.

## Tarefa e detecção de serviços

Gere um TDR por serviço em `./docs/tdr/<NNN>.<M>-TDR-<slug-do-servico>.md`. Numeração hierárquica por escopo (`SKILL.md` — "Organização de pastas"): identifique a qual PRD este TDR pertence (pelo contexto da conversa, ou pergunte se não for óbvio) e use o `<NNN>` desse PRD; `<M>` é o próximo sufixo livre naquele escopo (liste `docs/tdr/<NNN>.*.md` + `docs/adr/<NNN>.*.md` das duas pastas juntas, pegue o maior `.M` + 1, nenhum ainda → `.1`) — contador compartilhado com os ADRs do mesmo escopo, mesmo estando em pasta diferente, não é exclusivo de TDR. Sem PRD relacionado, este TDR inaugura seu próprio escopo: liste `docs/prd/*-PRD-*.md` + `docs/tdr/*-TDR-*.md` + `docs/adr/*-ADR-*.md` (só os sem sufixo `.M`) e pegue o próximo `<NNN>` inteiro livre, sem sufixo.

Antes de gerar, identifique quantos serviço/pasta existem com manifest de dependências próprio (`package.json`, `pyproject.toml`, `go.mod`...) e seu próprio entrypoint conta como um serviço candidato.

- 1 serviço gere um `./docs/tdr/<NNN>.<M>-TDR-<slug-do-projeto>.md`.
- N serviços gere um arquivo por serviço, `<slug>` em kebab-case derivado da pasta — objetivo, máx. 35 caracteres (`SKILL.md` — "`<slug>` — máximo 35 caracteres"). Liste os serviços detectados e confirme comigo antes de gerar os documentos — a ordem dessa confirmação é a ordem em que os `.M` consecutivos são atribuídos dentro do escopo.
- Infra compartilhada (banco, broker) entra em "Dependências Externas" de cada serviço que a consome — sem seção própria cross-service.

## Escopo de leitura

Leia código-fonte, configuração e estrutura de pastas do serviço.
Exclua: `.git`, dependências instaladas (`node_modules`, `vendor`, `.venv`, `site-packages`), builds (`dist`, `build`, `target`). Lockfiles só para checar versão, nunca para inferir arquitetura. Código de terceiros nunca é "módulo principal" nem "padrão" do projeto.

## Anti-alucinação (raciocínio somente interno)

Confirme cada afirmação num arquivo real antes de escrever. Sem coluna de fonte, sem `arquivo:linha`, sem marcação de premissa no output.

- Sem suposição, sem "conhecimento geral de como projetos X costumam ser".
- Sem sustentação em arquivo → não escreva, não infira.
- **Conflito entre fontes** (ex.: porta diverge entre `.env.example` e `docker-compose.yml`) → nunca escolha arbitrariamente. Campo recebe "Conflito entre fontes — ver revisão"; liste o conflito e as fontes na revisão fora do arquivo.
- Valor esperado pelo template mas ausente no código → "Não definido"/"Não aplicável" (nunca omita a linha).
- Relevante mas não confirmável → levante na revisão, fora do arquivo.

## Checklist de consistência (antes de mostrar)

- [ ]  Stack ↔ Dependências Externas: mesmos valores onde se sobrepõem (ex. banco de dados e sua versão).
- [ ]  Arquitetura não contradiz Módulos/camadas.
- [ ]  Todo "Não definido" foi checado, não é omissão por preguiça.
- [ ]  Todo conflito está marcado — nenhum resolvido arbitrariamente.
- [ ]  `<NNN>.<M>` segue a numeração hierárquica por escopo (`SKILL.md`) — `NNN` do PRD de origem (ou raiz nova, se não há PRD relacionado), `M` é o próximo sufixo livre do escopo, não reinicia por tipo.
- [ ]  `<slug>` tem no máximo 35 caracteres e é objetivo (sem artigo/preposição/palavra redundante).

Falhou algo → corrija antes de prosseguir.

## Template

```
# TDR — <Nome do Serviço>
> Documento técnico do serviço. Granularidade baixa: o que é global e estável.
> Regras finas ficam em ADRs.

## Stack
Tabela: | Dimensão | Valor |
Dimensões: Linguagem principal, Runtime/plataforma, Framework principal, Banco de dados, Ferramentas de build, Gerenciador de pacotes.

## Arquitetura
### Padrão arquitetural
Padrão em camadas (router → service) em 1-2 linhas + por quê.
### Estrutura de pastas dominante
Árvore de 2 níveis em bloco de código, 1 linha de responsabilidade FÍSICA por pasta
(o que mora ali).
### Módulos / camadas principais
| Módulo | Responsabilidade |
Responsabilidade LÓGICA/funcional, não física — se coincide com a pasta, não duplique.

### Interfaces de entrada
| Tipo | Identificador | Handler/Consumer |
Tudo que aciona o serviço: rotas HTTP (Método+Rota), CLI, consumers de
fila/tópico, cron, eventos, RPC/gRPC. Sub-tabela por tipo presente; omita o resto.

### Modelo de dados
Uma tabela por entidade: | Coluna | Tipo | Constraints/Default |.
Depois, relacionamentos: | Entidade origem | Entidade destino | Cardinalidade | Via |
(1:1/1:N/N:N; Via = FK ou tabela associativa). Sem relacionamento → "Nenhum".

## Requisitos Não-Funcionais
Tabela: | Dimensão | Requisito |
Inclua SEMPRE estas dimensões, nesta ordem: Performance, Disponibilidade/SLA,
Escalabilidade, Segurança, Observabilidade. Onde o código não sustenta um valor,
escreva "Não definido" — NÃO omita a linha.

## Dependências Externas
Tabela: | Serviço / Sistema | Tipo | Constraint relevante | Dono |
Só serviços/sistemas que impõem contrato (ex.: PostgreSQL, um outro serviço do mesmo
monorepo consumido via API/fila). Não liste libs de build do lockfile. Se não houver,
escreva "Nenhuma".

## Padrões
### Testes
| Item | Valor | — Framework, Comando completo, Cobertura mínima, Estratégia.
### Estilo de código
Bullets: Linter, Formatter, Convenções de nomenclatura. Ausente → "Não aplicável".
### Error handling
Prosa curta do padrão real.
### Logging
Bullets: Formato, Nível padrão, Biblioteca.
### Autenticação / autorização
Prosa curta, ou "Não aplicável".

## Decisões Globais (ADRs)
| # | Título | Data | Status | Link |
`#` é o `NNN.M` completo do ADR (ex.: `001.2`), igual ao `adr_number` dele e ao prefixo do nome de arquivo. Sem ADR ainda → linha *(nenhum ADR registrado)*. Índice preenchido conforme surgem.
```

## Saída

Front-matter por arquivo: `id: tdr-<slug-do-servico>`, `versao: 1`, `status: draft`, `data`, `autor`, `changelog` com "v1: baseline gerado a partir do repositório em <data>".

Ao terminar cada TDR: mostre seção por seção para revisão antes de gravar. Liste à parte (fora do documento) o que não foi confirmável e todo conflito de evidências.