# Exemplo de backend remoto AWS (S3 + DynamoDB lock).
# Referência — o backend real é gerado pelo Terragrunt a partir do terragrunt.hcl raiz.
# Se usar Terraform puro (sem Terragrunt), este é o bloco por componente:

# Bucket é por CATEGORIA (checklist.md §4) — 1 bucket por categoria, não 1 único
# pro projeto nem 1 por componente-folha. <env> e <componente> viram segmento da key.

terraform {
  backend "s3" {
    bucket         = "acme-tfstate-cloud"
    key            = "<projeto>/environments/<env>/<categoria>/<componente>/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "acme-tflock-cloud"
  }
}
