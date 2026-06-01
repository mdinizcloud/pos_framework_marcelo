# variables.tf

variable "bucket_name" {
  description = "Nome base do bucket S3 (o prefixo 'hvt-' será adicionado automaticamente pelo módulo)"
  type        = string
}

variable "environment" {
  description = "Nome do ambiente (dev, staging, production)"
  type        = string
}

variable "owner" {
  description = "Equipe ou squad dona/responsável pelo recurso"
  type        = string
}

variable "cost_center" {
  description = "Código do centro de custo para a bilhetagem do recurso"
  type        = string
}

variable "logging_target_bucket" {
  description = "Nome do bucket S3 de destino onde os logs de auditoria serão armazenados"
  type        = string
}

variable "logging_target_prefix" {
  description = "Prefixo do diretório dentro do bucket de logs onde os registros deste bucket serão salvos"
  type        = string
  default     = "s3-access-logs/"
}