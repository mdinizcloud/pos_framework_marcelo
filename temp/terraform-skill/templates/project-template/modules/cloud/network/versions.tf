terraform {
  required_version = ">= 1.9"

  required_providers {
    # Child module: SÓ required_providers, NUNCA provider block (config vem do root via Terragrunt).
    # Versão: ~> na última minor descoberta NA GERAÇÃO via
    #   scripts/get_latest_provider_version.sh <namespace> <name>   (Registry API, nunca de memória)
    # .terraform.lock.hcl commitado trava o patch exato. Nunca pin exato à mão, nunca versão legada.
    aws = {
      source  = "hashicorp/aws"
      version = "~> TODO_MAJOR.TODO_MINOR"
    }
  }
}
