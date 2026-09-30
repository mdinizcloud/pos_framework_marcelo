variable "environment" {
  description = "Nome do ambiente (dev, hml, prd)."
  type        = string
}

# TODO: variáveis reais do módulo network. Regras (checklist §6):
#   snake_case · description+type obrigatórios · boolean enable_/is_/use_ · sensitive=true em segredo
