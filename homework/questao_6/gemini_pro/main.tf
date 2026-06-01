# main.tf

locals {
  # Consolidação das tags obrigatórias
  common_tags = {
    Owner       = var.owner
    CostCenter  = var.cost_center
    Environment = var.environment
  }

  # Aplicação estrita da política de nomenclatura (prefixo hvt-)
  bucket_full_name = "hvt-${var.bucket_name}-${var.environment}"
}

# Criação do recurso base do Bucket S3
resource "aws_s3_bucket" "this" {
  bucket = local.bucket_full_name

  tags = merge(local.common_tags, {
    Name = local.bucket_full_name
  })
}

# Requirement 1: Versionamento ativo para resiliência de dados
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Requirement 2: Criptografia habilitada (SSE-S3 - AES256) no server-side
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Requirement 3: Bloqueio de acesso público total (Block Public Access)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Requirement 4: Logging de auditoria configurado para rastreabilidade
resource "aws_s3_bucket_logging" "this" {
  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_target_bucket
  target_prefix = "${var.logging_target_prefix}${local.bucket_full_name}/"
}