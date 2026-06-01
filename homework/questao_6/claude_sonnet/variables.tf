# ============================================================
# variables.tf
# Módulo: hvt-s3-bucket
# Responsável: Cloud & SRE Team
# Política: Strickland Security Policy v1.0
# ============================================================

# ------------------------------------------------------------------
# Identificação e governança obrigatória (Strickland Policy §1)
# ------------------------------------------------------------------

variable "owner" {
  description = "Nome do time ou pessoa responsável pelo recurso (tag obrigatória: Owner)."
  type        = string
}

variable "cost_center" {
  description = "Centro de custo associado ao recurso para fins de FinOps (tag obrigatória: CostCenter)."
  type        = string
}

variable "environment" {
  description = "Nome do ambiente onde o recurso será provisionado. Valores aceitos: dev, staging, production."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "O ambiente deve ser um dos valores: dev, staging, production."
  }
}

# ------------------------------------------------------------------
# Identificação do bucket
# ------------------------------------------------------------------

variable "bucket_suffix" {
  description = "Sufixo único que compõe o nome final do bucket junto ao prefixo 'hvt-' e ao ambiente. Ex: 'data-lake' resulta em 'hvt-data-lake-production'."
  type        = string
}

# ------------------------------------------------------------------
# Criptografia (Strickland Policy §3)
# ------------------------------------------------------------------

variable "sse_algorithm" {
  description = "Algoritmo de Server-Side Encryption. Use 'aws:kms' para KMS gerenciado ou 'AES256' para SSE-S3. Padrão: AES256 (SSE-S3)."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "O algoritmo SSE deve ser 'AES256' (SSE-S3) ou 'aws:kms'."
  }
}

variable "kms_master_key_id" {
  description = "ARN ou ID da chave KMS utilizada quando sse_algorithm = 'aws:kms'. Ignorado se o algoritmo for AES256."
  type        = string
  default     = null
}

# ------------------------------------------------------------------
# Versionamento (Strickland Policy §3)
# ------------------------------------------------------------------

variable "versioning_enabled" {
  description = "Habilita ou desabilita o versionamento de objetos no bucket. Padrão: true (obrigatório por política)."
  type        = bool
  default     = true
}

# ------------------------------------------------------------------
# Logging de auditoria (Strickland Policy §3)
# ------------------------------------------------------------------

variable "log_bucket_id" {
  description = "ID do bucket S3 de destino para os logs de acesso e auditoria deste bucket."
  type        = string
}

variable "log_prefix" {
  description = "Prefixo de caminho dentro do bucket de logs. Facilita a segregação por serviço. Ex: 's3-access-logs/data-lake/'."
  type        = string
  default     = ""
}

# ------------------------------------------------------------------
# Tags adicionais (merge com tags obrigatórias)
# ------------------------------------------------------------------

variable "additional_tags" {
  description = "Mapa de tags extras a serem mescladas com as tags obrigatórias de governança. Não sobrescrevem Owner, CostCenter ou Environment."
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------
# Lifecycle / proteção
# ------------------------------------------------------------------

variable "force_destroy" {
  description = "Se true, permite destruir o bucket mesmo que ele contenha objetos. Use apenas em ambientes não-produtivos. Padrão: false."
  type        = bool
  default     = false
}

