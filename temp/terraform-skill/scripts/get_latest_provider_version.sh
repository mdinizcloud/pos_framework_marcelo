#!/usr/bin/env bash
# Consulta a Terraform Registry API (fonte live) pra pegar a versão mais
# recente de um provider. Nunca usar context7 pra número de versão — context7
# é snapshot pré-crawleado e pode estar defasado em relação ao release real.
#
# Uso:
#   get_latest_provider_version.sh <namespace> <name>
#   get_latest_provider_version.sh hashicorp azurerm
#   get_latest_provider_version.sh hashicorp kubernetes
#
# Saída: só o número da versão (ex: 4.15.0), stdout. Erro em stderr + exit 1.

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Uso: $0 <namespace> <name>" >&2
  exit 1
fi

NAMESPACE="$1"
NAME="$2"
URL="https://registry.terraform.io/v1/providers/${NAMESPACE}/${NAME}"

RESPONSE="$(curl -sf "$URL")" || {
  echo "Erro ao consultar $URL — checar nome/namespace do provider" >&2
  exit 1
}

VERSION="$(echo "$RESPONSE" | python3 -c "import json,sys; print(json.load(sys.stdin)['version'])" 2>/dev/null)" || {
  echo "Resposta da API sem campo 'version' esperado — checar $URL manualmente" >&2
  exit 1
}

echo "$VERSION"
