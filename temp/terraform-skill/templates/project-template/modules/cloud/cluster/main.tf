# Módulo cluster — cluster gerenciado (EKS/AKS/GKE) na rede do componente network.
#
# Preencher NA GERAÇÃO com a sintaxe da ÚLTIMA versão do provider (Context7 via MCP;
# versão pela Registry API; terraform validate como rede anti-legado). Zero arg deprecado.
#
# Regras de forma:
#   - node pool / add-on como resource DEDICADO quando o provider oferecer (não bloco aninhado legado)
#   - nome de resource local NÃO repete o tipo
#   - consome var.network_id / var.subnet_ids (vindos do network via dependency)
#
# Exemplo de forma (NÃO copiar cru):
#   resource "aws_eks_cluster"    "this" { ... }
#   resource "aws_eks_node_group" "this" { ... }
