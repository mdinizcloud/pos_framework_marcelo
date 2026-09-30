# Vars comuns a TODOS os componentes deste ambiente.
# Lido pelos terragrunt.hcl de cada componente via read_terragrunt_config(find_in_parent_folders("env.hcl")).
locals {
  environment = "example-env" # TODO: renomear o diretório e o valor (dev | hml | prd)
}
