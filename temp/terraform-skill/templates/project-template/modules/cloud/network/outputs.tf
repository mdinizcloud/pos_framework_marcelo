# Outputs consumidos pelo componente cluster via dependency.network.outputs.*
output "network_id" {
  description = "ID da rede base criada por este módulo."
  value       = null # TODO: <recurso_de_rede>.this.id
}

output "subnet_ids" {
  description = "IDs das subnets criadas por este módulo."
  value       = [] # TODO: [for s in <recurso_subnet>.this : s.id]
}
