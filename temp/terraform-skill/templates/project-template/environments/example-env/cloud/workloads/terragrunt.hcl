# Componente: workloads — depende de cluster. Providers kubernetes/helm configurados aqui,
# com credenciais que saem do cluster (sobrescreve o generate "provider" da raiz).
include "root" {
  path = find_in_parent_folders()
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "../../../../modules/cloud/workloads"
}

dependency "cluster" {
  config_path = "../cluster"

  mock_outputs = {
    cluster_id = "cluster-mock"
    kube_host  = "https://mock.example"
    kube_ca    = "bW9jaw==" # "mock" base64
    kube_token = "mock-token"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}

# Sobrescreve o provider "aws" da raiz — workloads precisa de kubernetes/helm.
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    # Gerado pelo Terragrunt — não editar à mão.
    provider "kubernetes" {
      host                   = "${dependency.cluster.outputs.kube_host}"
      cluster_ca_certificate = base64decode("${dependency.cluster.outputs.kube_ca}")
      token                  = "${dependency.cluster.outputs.kube_token}"
    }
    provider "helm" {
      kubernetes {
        host                   = "${dependency.cluster.outputs.kube_host}"
        cluster_ca_certificate = base64decode("${dependency.cluster.outputs.kube_ca}")
        token                  = "${dependency.cluster.outputs.kube_token}"
      }
    }
  EOF
}

inputs = {
  environment = local.env.environment
  kube_host   = dependency.cluster.outputs.kube_host
  kube_ca     = dependency.cluster.outputs.kube_ca
  kube_token  = dependency.cluster.outputs.kube_token
  # TODO: inputs reais do deploy (imagem, réplicas, flags por ambiente).
}
