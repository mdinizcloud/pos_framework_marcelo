terraform {
  required_version = ">= 1.9"

  required_providers {
    # Child module: SÓ required_providers, NUNCA provider block.
    # Versão ~> da última minor via scripts/get_latest_provider_version.sh (Registry API).
    aws = {
      source  = "hashicorp/aws"
      version = "~> TODO_MAJOR.TODO_MINOR"
    }
  }
}
