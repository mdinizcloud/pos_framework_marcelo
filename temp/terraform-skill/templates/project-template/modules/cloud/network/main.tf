# Módulo network — rede base (VPC/VNet, subnets, route tables).
#
# Preencher NA GERAÇÃO com a sintaxe da ÚLTIMA versão do provider:
#   1. versão (número) → scripts/get_latest_provider_version.sh (Registry API)
#   2. sintaxe/resource shape → Context7 via MCP (guardrail: se o Context7 estiver defasado
#      vs a latest da Registry, não copiar cego — preferir a doc da versão latest)
#   3. terraform validate no fim → rede anti-legado (pega arg deprecado)
#
# Regras de forma:
#   - config acessória = resource DEDICADO, nunca bloco aninhado legado
#   - nome de resource local NÃO repete o tipo (resource "aws_vpc" "this", não "aws_vpc")
#   - meta-args: count/for_each no topo do bloco; tags/lifecycle/depends_on no fim
#
# Exemplo de forma (NÃO copiar cru — gerar com a API atual):
#   resource "aws_vpc"    "this"  { ... }
#   resource "aws_subnet" "this"  { for_each = ... }
