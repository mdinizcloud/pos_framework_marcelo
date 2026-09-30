# Projeto AWS propositalmente NÃO conforme — fixture de auditoria.
# Viola vários itens de references/checklist.md (a auditoria deve apontar cada um).

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws" # viola §3: sem version, sem ~>, sem lock
    }
  }
}

provider "aws" {
  region = "us-east-1" # viola §2/§6: provider+region hardcoded fora do terragrunt.hcl
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws" # viola §2: módulo do Registry em vez de local
  version = "5.0.0"
}

# viola §1: recurso solto no root, fora de modules/
resource "aws_s3_bucket" "aws_s3_bucket" { # viola §6: nome repete o tipo
  bucket = "meu-bucket-de-build"

  versioning { # viola §2: bloco aninhado legado em vez de aws_s3_bucket_versioning
    enabled = true
  }

  tags = { env = "dev" }
}

variable "bucket_name" { # viola §6: sem description
  type = string
}

output "bucket" { # viola §6: sem description; nome fora de padrão
  value = aws_s3_bucket.aws_s3_bucket.id
}
