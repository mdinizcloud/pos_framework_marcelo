# CONTEXT
Você é um Engenheiro de Cloud e SRE especialista em Terraform e em infraestrutura como código (IaC). 

Usamos padrões estritos de segurança, compliance e governança. O especialista de segurança (Strickland) publicou a política interna que exige que todo novo módulo Terraform siga estas premissas:

1. Tags obrigatórias em todo recurso: `Owner`, `CostCenter`, `Environment`.
2. Prefixo `hvt-` em todos os nomes de recursos.
3. Todo bucket S3 deve possuir obrigatoriamente: Criptografia habilitada (SSE-S3 no mínimo), Versionamento ativo, Bloqueio de acesso público total (Block Public Access) e Logging de auditoria configurado.
4. Todas as variáveis de entrada no arquivo `variables.tf` devem ter os blocos `description` e `type` preenchidos.

# ACTION
Crie um módulo Terraform reutilizável para provisionar buckets S3 que atenda todos os requisitos de compliance descritos no contexto. 
Estruture o código separando-o logicamente (ex: `variables.tf`, `main.tf`, `outputs.tf`) conforme o exemplo enviado.
Forneça um exemplo prático de como um time interno consumiria este módulo .

# RESULT
Espero um conjunto de blocos de código limpos, comentados e prontos para produção. 
Garanta que o uso de `locals` para a fusão de tags (merge) e a nomenclatura dos recursos sigam à risca o padrão de design da empresa. 
Gere um artefato markdown para cada componente em terraform (ex: `variables.tf`, `main.tf`, `outputs.tf`) 
# EXAMPLE
Para garantir a consistência  do código,  utilize baseado no modelo abaixo:

```hcl
variable "environment" {
  description = "Nome do ambiente (dev, staging, production)"
  type        = string
}

locals {
  common_tags = {
    Owner       = var.owner
    CostCenter  = var.cost_center
    Environment = var.environment
  }
}

resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
  tags = merge(local.common_tags, {
    Name = "hvt-vpc-${var.environment}"
  })
}