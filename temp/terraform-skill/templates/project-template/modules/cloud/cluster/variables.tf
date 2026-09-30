variable "environment" {
  description = "Nome do ambiente (dev, hml, prd)."
  type        = string
}

variable "network_id" {
  description = "ID da rede base (vem do componente network)."
  type        = string
}

variable "subnet_ids" {
  description = "IDs das subnets onde o cluster será provisionado (vem do network)."
  type        = list(string)
}

# TODO: variáveis reais do cluster (tamanho de node pool, versão do k8s, etc).
