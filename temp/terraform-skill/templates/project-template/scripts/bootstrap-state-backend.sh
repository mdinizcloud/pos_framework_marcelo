#!/usr/bin/env bash
# Bootstrap do backend de state remoto (chicken-egg): cria o bucket + o lock ANTES
# de qualquer `terragrunt apply`. Idempotente onde a CLI permite. Nunca guarda
# state — usa a CLI nativa da cloud.
#
# 1 bucket por CATEGORIA de módulo (checklist.md §4), não 1 único pro projeto nem
# 1 por componente-folha — rodar 1 vez por categoria (ex: cloud, observabilidade,
# seguranca, apps), nome `<projeto>-tfstate-<categoria>` (Azure: sem hífen,
# `<projeto>tfstate<categoria>`). `<env>` fica dentro da key, não no nome do bucket.
#
# Uso:
#   ./scripts/bootstrap-state-backend.sh <cloud> <bucket> <region> [lock_table]
#   ./scripts/bootstrap-state-backend.sh aws   acme-tfstate-cloud       us-east-1  acme-tflock-cloud
#   ./scripts/bootstrap-state-backend.sh azure acmetfstatecloud         eastus
#   ./scripts/bootstrap-state-backend.sh gcp   acme-tfstate-cloud       us-east1
#
#   # repetir por categoria:
#   ./scripts/bootstrap-state-backend.sh aws acme-tfstate-observabilidade us-east-1 acme-tflock-observabilidade

set -euo pipefail

CLOUD="${1:-}"
BUCKET="${2:-}"
REGION="${3:-}"
LOCK_TABLE="${4:-tf-lock}"

if [ -z "$CLOUD" ] || [ -z "$BUCKET" ] || [ -z "$REGION" ]; then
  echo "Uso: $0 <aws|azure|gcp> <bucket> <region> [lock_table]" >&2
  exit 1
fi

case "$CLOUD" in
  aws)
    echo ">> S3 bucket $BUCKET ($REGION)"
    if [ "$REGION" = "us-east-1" ]; then
      aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
    else
      aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION"
    fi
    aws s3api put-bucket-versioning --bucket "$BUCKET" \
      --versioning-configuration Status=Enabled                       # backup do state
    aws s3api put-bucket-encryption --bucket "$BUCKET" \
      --server-side-encryption-configuration \
      '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
    aws s3api put-public-access-block --bucket "$BUCKET" \
      --public-access-block-configuration \
      BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    echo ">> DynamoDB lock table $LOCK_TABLE"
    aws dynamodb create-table --table-name "$LOCK_TABLE" \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST --region "$REGION" || true
    ;;
  azure)
    RG="${BUCKET}-rg"
    echo ">> Resource group $RG + storage account $BUCKET ($REGION)"
    az group create --name "$RG" --location "$REGION" >/dev/null
    az storage account create --name "$BUCKET" --resource-group "$RG" \
      --location "$REGION" --sku Standard_LRS --encryption-services blob \
      --min-tls-version TLS1_2 --allow-blob-public-access false >/dev/null
    az storage container create --name tfstate --account-name "$BUCKET" >/dev/null
    echo ">> Lock: nativo por blob lease (azurerm backend). Sem tabela extra."
    ;;
  gcp)
    echo ">> GCS bucket $BUCKET ($REGION)"
    gcloud storage buckets create "gs://${BUCKET}" --location="$REGION" \
      --uniform-bucket-level-access
    gcloud storage buckets update "gs://${BUCKET}" --versioning              # backup
    echo ">> Lock: nativo do backend gcs. Sem tabela extra."
    ;;
  *)
    echo "Cloud inválida: $CLOUD (use aws|azure|gcp)" >&2
    exit 1
    ;;
esac

echo "OK — backend de state pronto. Preencher terragrunt.hcl (raiz) com bucket/region."
