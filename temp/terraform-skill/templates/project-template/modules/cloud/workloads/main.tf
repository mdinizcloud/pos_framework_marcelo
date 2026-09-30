# Módulo workloads — deploy in-cluster (namespaces, Helm releases, manifests, Istio).
#
# Providers kubernetes/helm NÃO são configurados aqui — vêm do terragrunt.hcl do componente
# workloads (generate "provider"), com credenciais do cluster.
#
# Escopo: este módulo NÃO substitui GitOps. Para deploy contínuo de app, preferir ArgoCD/Flux
# (bootstrap do control plane pode ser um helm_release aqui). Ver docs/architecture.md.
#
# Preencher NA GERAÇÃO com a sintaxe da ÚLTIMA versão do provider (Context7 via MCP;
# versão pela Registry API; terraform validate como rede anti-legado). Zero arg deprecado.
#
# Exemplo de forma (NÃO copiar cru):
#   resource "kubernetes_namespace" "this" { ... }
#   resource "helm_release"         "this" { ... }
