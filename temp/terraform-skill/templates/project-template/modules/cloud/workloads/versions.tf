terraform {
  required_version = ">= 1.9"

  required_providers {
    # Child module: SÓ required_providers, NUNCA provider block.
    # Providers kubernetes/helm são CONFIGURADOS no terragrunt.hcl do componente workloads,
    # com credenciais vindas do componente cluster (dependency.cluster.outputs.*).
    # Versão ~> da última minor via scripts/get_latest_provider_version.sh (Registry API).
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> TODO_MAJOR.TODO_MINOR"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> TODO_MAJOR.TODO_MINOR"
    }
  }
}
