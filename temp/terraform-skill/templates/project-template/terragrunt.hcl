# Config raiz do Terragrunt — herdada por TODO componente via include "root".
# Define UMA vez: backend remoto (state split por path) + provider gerado.
# A key do state sai do path automaticamente — nunca escrever key à mão por componente.

locals {
  # TODO: preencher com os valores reais do projeto (ver README.md e docs/backend-examples/).
  project      = "TODO_NOME_DO_PROJETO"
  cloud        = "aws" # aws | azure | gcp
  state_region = "us-east-1"

  # path_relative_to_include() = "environments/<env>/<categoria>/<componente>" (a partir da
  # raiz do projeto, onde este include vive) — segmento [2] é sempre a categoria. Bucket/tabela
  # de lock derivados dela, nunca hardcoded (checklist.md §4). Cada categoria precisa ter
  # passado por scripts/bootstrap-state-backend.sh antes do 1º apply.
  categoria = element(split("/", path_relative_to_include()), 2)
}

# ---- State remoto: 1 state por componente-folha, 1 bucket por CATEGORIA ----
# Resultado: <projeto>-tfstate-<categoria>/<projeto>/<categoria>/<componente>/terraform.tfstate
# Trocar backend "s3" por "azurerm"/"gcs" conforme a cloud (ver docs/backend-examples/) — Azure
# não aceita hífen no nome do storage account, usar "${local.project}tfstate${local.categoria}".
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "${local.project}-tfstate-${local.categoria}"
    key            = "${local.project}/${path_relative_to_include()}/terraform.tfstate"
    region         = local.state_region
    encrypt        = true
    dynamodb_table = "${local.project}-tflock-${local.categoria}"
  }
}

# ---- Provider gerado automaticamente em cada componente ----
# Provider config NUNCA vive nos módulos (child modules só declaram required_providers).
# Componentes que precisam de outro provider (ex: workloads → kubernetes/helm) sobrescrevem
# este bloco com um generate "provider" próprio no seu terragrunt.hcl.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    # Gerado pelo Terragrunt — não editar à mão.
    provider "aws" {
      region = "${local.state_region}"
    }
  EOF
}

# ---- Gate de validação amarrado a TODO plan/apply, não só à geração pela skill ----
# Roda mesmo se um humano der `terragrunt apply` direto, meses depois, sem a skill no caminho.
# Falha o comando (não é opcional) se fmt/validate não passar.
terraform {
  before_hook "validate" {
    commands = ["plan", "apply"]
    execute  = ["terraform", "validate"]
  }
  before_hook "fmt_check" {
    commands = ["plan", "apply"]
    execute  = ["terraform", "fmt", "-check"]
  }
}
