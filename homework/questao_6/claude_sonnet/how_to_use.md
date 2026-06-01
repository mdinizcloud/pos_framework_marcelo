# `example/main.tf` — Consumo do Módulo por Times Internos

> Exemplo prático de como um time interno referencia o módulo `hvt-s3-bucket` em seus próprios workspaces Terraform.

---

## Estrutura do exemplo

```
example/
├── main.tf          ← Este arquivo
├── variables.tf     ← Variáveis do workspace consumidor
├── outputs.tf       ← Re-exporta outputs relevantes
└── terraform.tfvars ← Valores concretos por ambiente
```

---

## `example/main.tf`

```hcl
# ============================================================
# example/main.tf
# Time: Data Platform Squad
# Workspace: data-platform-production
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  # Backend remoto recomendado (S3 + DynamoDB para lock)
  backend "s3" {
    bucket         = "hvt-terraform-state-production"
    key            = "data-platform/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "hvt-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Module    = "hvt-s3-bucket"
    }
  }
}

# ------------------------------------------------------------------
# Módulo: bucket principal de dados do Data Lake
# ------------------------------------------------------------------

module "data_lake_raw" {
  # Referência ao módulo versionado no repositório central de IaC
  source  = "git::https://github.com/hvt-corp/terraform-modules.git//s3-bucket?ref=v1.2.0"

  # Governança obrigatória (Strickland Policy §1)
  owner       = "data-platform-squad"
  cost_center = "CC-4421"
  environment = var.environment

  # Identificação do bucket: resultará em "hvt-data-lake-raw-production"
  bucket_suffix = "data-lake-raw"

  # Criptografia com KMS gerenciado pelo time de segurança (§3)
  sse_algorithm     = "aws:kms"
  kms_master_key_id = data.aws_kms_key.data_platform.arn

  # Logging de auditoria apontando para bucket centralizado (§3)
  log_bucket_id = module.audit_logs.bucket_id
  log_prefix    = "s3-access-logs/data-lake-raw/"

  # Tags adicionais específicas do time (serão mescladas, não sobrescrevem)
  additional_tags = {
    Squad      = "data-platform"
    DataDomain = "raw-ingestion"
    Tier       = "bronze"
  }

  # Proteção extra em produção: nunca destruir com dados
  force_destroy = false
}

# ------------------------------------------------------------------
# Módulo: bucket de logs de auditoria centralizado
# (provisionado antes dos demais para evitar dependência circular)
# ------------------------------------------------------------------

module "audit_logs" {
  source  = "git::https://github.com/hvt-corp/terraform-modules.git//s3-bucket?ref=v1.2.0"

  owner       = "sre-team"
  cost_center = "CC-0010"
  environment = var.environment

  bucket_suffix = "audit-logs-central"

  # Logs do bucket de logs vão para si mesmo com prefixo distinto
  log_bucket_id = "hvt-audit-logs-central-${var.environment}"
  log_prefix    = "self-audit/"

  sse_algorithm = "AES256"

  additional_tags = {
    Squad   = "sre"
    Purpose = "centralized-audit-logging"
  }
}

# ------------------------------------------------------------------
# Módulo: bucket de artefatos de ML (exemplo de múltiplas instâncias)
# ------------------------------------------------------------------

module "ml_artifacts" {
  source  = "git::https://github.com/hvt-corp/terraform-modules.git//s3-bucket?ref=v1.2.0"

  owner       = "ml-platform-squad"
  cost_center = "CC-5530"
  environment = var.environment

  # Resultará em: "hvt-ml-artifacts-production"
  bucket_suffix = "ml-artifacts"

  sse_algorithm     = "aws:kms"
  kms_master_key_id = data.aws_kms_key.data_platform.arn

  log_bucket_id = module.audit_logs.bucket_id
  log_prefix    = "s3-access-logs/ml-artifacts/"

  additional_tags = {
    Squad      = "ml-platform"
    DataDomain = "model-registry"
  }
}

# ------------------------------------------------------------------
# Data source: chave KMS pré-existente gerenciada pelo time de segurança
# ------------------------------------------------------------------

data "aws_kms_key" "data_platform" {
  key_id = "alias/hvt-data-platform-${var.environment}"
}
```

---

## `example/variables.tf`

```hcl
variable "environment" {
  description = "Ambiente de deploy do workspace consumidor (dev, staging, production)."
  type        = string
}
```

---

## `example/outputs.tf`

```hcl
# Re-exporta outputs críticos para outros workspaces via terraform_remote_state

output "data_lake_raw_bucket_arn" {
  description = "ARN do bucket raw do Data Lake para uso em políticas IAM downstream."
  value       = module.data_lake_raw.bucket_arn
}

output "data_lake_raw_bucket_id" {
  description = "ID do bucket raw do Data Lake."
  value       = module.data_lake_raw.bucket_id
}

output "audit_logs_bucket_id" {
  description = "ID do bucket centralizado de audit logs."
  value       = module.audit_logs.bucket_id
}

output "ml_artifacts_bucket_arn" {
  description = "ARN do bucket de artefatos de ML."
  value       = module.ml_artifacts.bucket_arn
}

output "security_compliance_summary" {
  description = "Resumo dos controles de segurança ativos em todos os buckets provisionados."
  value = {
    data_lake_raw = {
      versioning_status   = module.data_lake_raw.versioning_status
      sse_algorithm       = module.data_lake_raw.sse_algorithm
      public_access_blocked = module.data_lake_raw.public_access_blocked
      log_target_bucket   = module.data_lake_raw.log_target_bucket
    }
    ml_artifacts = {
      versioning_status   = module.ml_artifacts.versioning_status
      sse_algorithm       = module.ml_artifacts.sse_algorithm
      public_access_blocked = module.ml_artifacts.public_access_blocked
    }
  }
}
```

---

## `example/terraform.tfvars`

```hcl
# Valores para o ambiente de produção
environment = "production"
```

---

## Fluxo de deploy recomendado

```bash
# 1. Inicializa o backend e baixa o módulo versionado
terraform init

# 2. Valida sintaxe e tipos
terraform validate

# 3. Revisa o plano de execução
terraform plan -var-file="terraform.tfvars" -out=tfplan

# 4. Aplica somente após aprovação do SRE lead
terraform apply tfplan
```
