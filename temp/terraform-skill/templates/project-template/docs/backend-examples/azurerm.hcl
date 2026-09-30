# Exemplo de backend remoto Azure (Storage Account, lock nativo por blob lease).
# Referência — o backend real é gerado pelo Terragrunt a partir do terragrunt.hcl raiz.

# Storage account é por CATEGORIA — sem hífen no nome (limite do Azure).

terraform {
  backend "azurerm" {
    resource_group_name  = "acmetfstatecloud-rg"
    storage_account_name = "acmetfstatecloud"
    container_name       = "tfstate"
    key                  = "<projeto>/environments/<env>/<categoria>/<componente>/terraform.tfstate"
  }
}
