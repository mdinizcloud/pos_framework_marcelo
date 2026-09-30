output "app_url" {
  description = "URL pública da aplicação exposta neste ambiente."
  value       = null # TODO: computar do ingress/service
}

output "ingress_ip" {
  description = "IP do ingress do cluster."
  value       = null # TODO: <recurso_ingress>.this.status...
}
