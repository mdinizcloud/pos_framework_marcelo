variable "environment" {
  description = "Nome do ambiente (dev, hml, prd)."
  type        = string
}

variable "kube_host" {
  description = "Endpoint da API do cluster (vem do componente cluster)."
  type        = string
}

variable "kube_ca" {
  description = "CA certificate do cluster em base64 (vem do cluster)."
  type        = string
}

variable "kube_token" {
  description = "Token de autenticação no cluster (vem do cluster)."
  type        = string
  sensitive   = true
}

# TODO: variáveis reais do deploy (imagem, réplicas, flags de feature por ambiente).
