# Projeto GCP propositalmente NÃO conforme — fixture de auditoria.
# Viola vários itens de references/checklist.md (a auditoria deve apontar cada um).

terraform {
  required_providers {
    google = {
      source = "hashicorp/google" # viola §3: sem version, sem ~>, sem lock
    }
  }
}

provider "google" {
  region = "us-east1" # viola §2/§6: provider+region hardcoded
}

module "gcs" {
  source = "terraform-google-modules/cloud-storage/google" # viola §2: módulo do Registry
}

# viola §1: recurso solto no root, fora de modules/
resource "google_storage_bucket" "google_storage_bucket" { # viola §6: nome repete o tipo
  name     = "acme-build-artifacts"
  location = "US" # viola §6: location hardcoded

  versioning { # config acessória inline — preferir resource dedicado quando existir
    enabled = true
  }
}

variable "bucket_name" { # viola §6: sem description
  type = string
}

output "bucket" { # viola §6: sem description
  value = google_storage_bucket.google_storage_bucket.id
}
