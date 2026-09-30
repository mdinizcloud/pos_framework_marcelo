# Exemplo de backend remoto GCP (GCS, lock nativo do backend).
# Referência — o backend real é gerado pelo Terragrunt a partir do terragrunt.hcl raiz.

# Bucket é por CATEGORIA — 1 por categoria, não 1 único pro projeto.

terraform {
  backend "gcs" {
    bucket = "acme-tfstate-cloud"
    prefix = "<projeto>/environments/<env>/<categoria>/<componente>"
  }
}
