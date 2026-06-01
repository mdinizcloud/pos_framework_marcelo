# ============================================================
# outputs.tf
# Módulo: hvt-s3-bucket
# Responsável: Cloud & SRE Team
# Política: Strickland Security Policy v1.0
# ============================================================

# ------------------------------------------------------------------
# Identificadores do bucket
# ------------------------------------------------------------------

output "bucket_id" {
  description = "ID (nome) do bucket S3 provisionado. Equivalente ao nome do bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN do bucket S3 provisionado. Utilizado em políticas IAM e recursos dependentes."
  value       = aws_s3_bucket.this.arn
}

output "bucket_name" {
  description = "Nome gerado do bucket seguindo o padrão hvt-{suffix}-{environment}."
  value       = local.bucket_name
}

output "bucket_domain_name" {
  description = "Endpoint DNS público do bucket (formato: <bucket>.s3.amazonaws.com)."
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Endpoint DNS regional do bucket. Preferível ao domínio global para evitar redirect 307."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

# ------------------------------------------------------------------
# Região e hospedagem
# ------------------------------------------------------------------

output "bucket_region" {
  description = "Região AWS onde o bucket foi criado."
  value       = aws_s3_bucket.this.region
}

# ------------------------------------------------------------------
# Estado dos controles de segurança (útil para auditoria)
# ------------------------------------------------------------------

output "versioning_status" {
  description = "Status atual do versionamento do bucket (Enabled | Suspended)."
  value       = var.versioning_enabled ? "Enabled" : "Suspended"
}

output "sse_algorithm" {
  description = "Algoritmo de criptografia SSE configurado no bucket (AES256 ou aws:kms)."
  value       = var.sse_algorithm
}

output "public_access_blocked" {
  description = "Confirma que o bloqueio total de acesso público está ativo. Sempre true por política."
  value       = true
}

output "log_target_bucket" {
  description = "ID do bucket de destino configurado para logging de auditoria."
  value       = var.log_bucket_id
}

output "log_target_prefix" {
  description = "Prefixo de path configurado para os logs de acesso no bucket de destino."
  value       = aws_s3_bucket_logging.this.target_prefix
}

# ------------------------------------------------------------------
# Tags aplicadas
# ------------------------------------------------------------------

output "applied_tags" {
  description = "Mapa completo de tags aplicadas ao bucket (obrigatórias + adicionais)."
  value       = local.common_tags
}
