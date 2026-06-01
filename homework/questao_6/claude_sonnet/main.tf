# ============================================================
# main.tf
# Módulo: hvt-s3-bucket
# Responsável: Cloud & SRE Team
# Política: Strickland Security Policy v1.0
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

# ------------------------------------------------------------------
# locals — nomenclatura e merge de tags (Strickland Policy §1 e §2)
# ------------------------------------------------------------------

locals {
  # Prefixo obrigatório de empresa + sufixo + ambiente
  bucket_name = "hvt-${var.bucket_suffix}-${var.environment}"

  # Tags obrigatórias por política (§1)
  mandatory_tags = {
    Owner       = var.owner
    CostCenter  = var.cost_center
    Environment = var.environment
  }

  # Merge: tags adicionais nunca sobrescrevem as obrigatórias
  common_tags = merge(var.additional_tags, local.mandatory_tags)
}

# ------------------------------------------------------------------
# Recurso principal: bucket S3 (Strickland Policy §2 — prefixo hvt-)
# ------------------------------------------------------------------

resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = merge(local.common_tags, {
    Name = local.bucket_name
  })
}

# ------------------------------------------------------------------
# Criptografia SSE (Strickland Policy §3 — obrigatória)
# ------------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      # kms_master_key_id é ignorado quando sse_algorithm = "AES256"
      kms_master_key_id = var.sse_algorithm == "aws:kms" ? var.kms_master_key_id : null
    }

    # Garante que uploads sem header SSE explícito também sejam criptografados
    bucket_key_enabled = var.sse_algorithm == "aws:kms" ? true : false
  }
}

# ------------------------------------------------------------------
# Versionamento (Strickland Policy §3 — obrigatório)
# ------------------------------------------------------------------

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# ------------------------------------------------------------------
# Block Public Access — total (Strickland Policy §3 — obrigatório)
# ------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  # Todos os quatro controles habilitados para bloqueio total
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------
# Logging de auditoria (Strickland Policy §3 — obrigatório)
# ------------------------------------------------------------------

resource "aws_s3_bucket_logging" "this" {
  bucket = aws_s3_bucket.this.id

  # Bucket destino fornecido externamente (evita dependência circular)
  target_bucket = var.log_bucket_id
  target_prefix = var.log_prefix != "" ? var.log_prefix : "s3-access-logs/${local.bucket_name}/"
}

# ------------------------------------------------------------------
# Bucket policy: forçar TLS em trânsito (defence-in-depth)
# ------------------------------------------------------------------

data "aws_iam_policy_document" "deny_http" {
  statement {
    sid    = "DenyNonTLS"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "deny_http" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.deny_http.json

  # A política só pode ser aplicada após o Block Public Access estar ativo
  depends_on = [aws_s3_bucket_public_access_block.this]
}

# ------------------------------------------------------------------
# Lifecycle rule padrão: limpar versões antigas (boas práticas)
# ------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  # Depende do versionamento estar configurado antes
  depends_on = [aws_s3_bucket_versioning.this]

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      # Remove versões não-correntes após 90 dias para controle de custos
      noncurrent_days = 90
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      # Move para IA após 30 dias para otimização de custos
      storage_class   = "STANDARD_IA"
    }

    abort_incomplete_multipart_upload {
      # Limpa uploads multipart incompletos após 7 dias
      days_after_initiation = 7
    }
  }
}
