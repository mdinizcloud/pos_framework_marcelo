# Outputs consumidos pelo componente workloads (configura os providers kubernetes/helm).
output "cluster_id" {
  description = "ID do cluster gerenciado."
  value       = null # TODO: <recurso_cluster>.this.id
}

output "kube_host" {
  description = "Endpoint da API do cluster."
  value       = null # TODO: <recurso_cluster>.this.endpoint
}

output "kube_ca" {
  description = "CA certificate do cluster (base64)."
  value       = null # TODO: <recurso_cluster>.this.certificate_authority_data
  sensitive   = true
}

output "kube_token" {
  description = "Token de autenticação no cluster."
  value       = null # TODO: data source de auth do cluster
  sensitive   = true
}
