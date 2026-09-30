# Projeto Azure propositalmente NÃO conforme — fixture de auditoria.
# Viola vários itens de references/checklist.md (a auditoria deve apontar cada um).

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.0.0" # viola §3: pin exato à mão em vez de ~> da latest
    }
  }
}

provider "azurerm" { # viola §2: provider block no root do código
  features {}
}

module "storage" {
  source = "Azure/storage-account/azurerm" # viola §2: módulo do Registry
}

# viola §1: recurso solto no root, fora de modules/
resource "azurerm_storage_account" "azurerm_storage_account" { # viola §6: nome repete o tipo
  name                     = "acmebuildsa"
  resource_group_name      = "rg-build"
  location                 = "eastus" # viola §6: location hardcoded
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules { # viola §2: bloco aninhado em vez de azurerm_storage_account_network_rules
    default_action = "Deny"
  }
}

variable "sa_name" { # viola §6: sem description
  type = string
}

output "sa_id" { # viola §6: sem description
  value = azurerm_storage_account.azurerm_storage_account.id
}
