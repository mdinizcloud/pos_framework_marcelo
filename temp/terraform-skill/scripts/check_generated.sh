#!/usr/bin/env bash
# Gate determinístico de validação do código Terraform + Terragrunt gerado/auditado.
# Estático e rápido — não precisa de credencial de cloud nem de state. Roda ao fim da
# geração (self-validation em runtime) e no pre-commit do skills_registry.
#
# Uso:  scripts/check_generated.sh <path-do-projeto>
# Saída: lista de findings; exit 1 se houver algum bloqueante.

set -uo pipefail

# Resolver ANTES do cd pro projeto auditado — senão "scripts/" pode colidir com o
# scripts/ do próprio projeto alvo (ex: templates/project-template/scripts/bootstrap-*.sh).
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ROOT="${1:-.}"
FAIL=0
note() { echo "  ✗ $*"; FAIL=1; }
ok()   { echo "  ✓ $*"; }

if [ ! -d "$ROOT" ]; then
  echo "path inválido: $ROOT" >&2
  exit 1
fi
cd "$ROOT"

echo "== check_generated: $ROOT =="

# 1. Formatação -----------------------------------------------------------------
if command -v terraform >/dev/null 2>&1; then
  if terraform fmt -check -recursive >/dev/null 2>&1; then ok "terraform fmt"; else note "terraform fmt -check falhou (rodar: terraform fmt -recursive)"; fi
else
  echo "  ~ terraform não instalado — pulando fmt"
fi
if command -v terragrunt >/dev/null 2>&1; then
  if terragrunt hclfmt --check >/dev/null 2>&1 || terragrunt hcl fmt --check >/dev/null 2>&1; then ok "terragrunt hclfmt"; else note "terragrunt hclfmt --check falhou"; fi
else
  echo "  ~ terragrunt não instalado — pulando hclfmt"
fi

# 2. Provider: ~> presente, sem pin exato à mão ----------------------------------
# Busca recursiva (não `modules/*/versions.tf`) — módulo agora mora 1 nível mais fundo,
# dentro de categoria (`modules/<categoria>/<nome>/versions.tf`); glob raso pulava tudo em
# silêncio.
mapfile -t VERSIONS_FILES < <(find modules -name versions.tf 2>/dev/null)
if [ "${#VERSIONS_FILES[@]}" -gt 0 ]; then
  if grep -hoE 'version[[:space:]]*=[[:space:]]*"[^"]+"' "${VERSIONS_FILES[@]}" | grep -qvE '"~>'; then
    note "versão de provider sem '~>' (pin exato à mão ou constraint diferente) em algum modules/**/versions.tf"
  else
    ok "provider com ~> em modules/**/versions.tf"
  fi
  if grep -lE 'TODO_MAJOR|TODO_MINOR|TODO_VERSAO' "${VERSIONS_FILES[@]}" 2>/dev/null | grep -q .; then
    note "placeholder de versão não preenchido (TODO_*) em algum modules/**/versions.tf"
  fi
else
  echo "  ~ nenhum modules/**/versions.tf — pulando checagem de versão"
fi

# 2b. README.md por módulo (checklist §2) ----------------------------------------
# Módulo = diretório que tem versions.tf (folha real), qualquer profundidade dentro de
# modules/ — cobre tanto modules/<nome>/ (legado) quanto modules/<categoria>/<nome>/.
if [ -d modules ]; then
  missing_readme=0
  module_count=0
  while IFS= read -r vf; do
    d="$(dirname "$vf")"
    module_count=$((module_count + 1))
    [ -f "${d}/README.md" ] || { note "módulo sem README.md: ${d}/"; missing_readme=1; }
  done < <(find modules -name versions.tf 2>/dev/null)
  [ "$module_count" -gt 0 ] && [ "$missing_readme" -eq 0 ] && ok "todo módulo em modules/ tem README.md"
fi

# 3. provider {} block dentro de módulo (proibido) ------------------------------
if grep -RqE '^\s*provider\s+"' modules/ 2>/dev/null; then
  note "provider block dentro de modules/ (config de provider deve vir do terragrunt.hcl)"
else
  ok "sem provider block em modules/"
fi

# 4. Lock file commitado --------------------------------------------------------
if find . -name '.terraform.lock.hcl' -not -path '*/.terragrunt-cache/*' | grep -q .; then
  ok ".terraform.lock.hcl presente"
else
  note ".terraform.lock.hcl ausente (deve ser commitado — rodar terraform/terragrunt init)"
fi

# 5. Backend local ou state central (proibido) ----------------------------------
if grep -RqE 'backend\s+"local"' . --include='*.tf' --include='*.hcl' 2>/dev/null; then
  note "backend \"local\" encontrado — workspace usa backend remoto"
else
  ok "sem backend local"
fi

# 6. State versionado por engano ------------------------------------------------
if find . -name '*.tfstate' -not -path '*/.terragrunt-cache/*' | grep -q .; then
  note "arquivo *.tfstate no projeto — nunca commitar state (segredo em texto plano)"
else
  ok "sem *.tfstate no projeto"
fi

# 7. Naming/description/segredo hardcoded (checklist §2/§6) --------------------
if command -v python3 >/dev/null 2>&1; then
  if python3 "$SELF_DIR/check_naming.py" . ; then
    ok "check_naming.py (description/type/naming/segredo hardcoded)"
  else
    note "check_naming.py encontrou finding (ver saída acima)"
  fi
else
  echo "  ~ python3 não instalado — pulando check_naming.py"
fi

# 8. Legado / deprecated conhecido ----------------------------------------------
#    lista mínima e conservadora — validate é a rede principal; isto pega casos óbvios.
DEPRECATED='ignore_changes\s*=\s*\["\*"\]|version\s*=\s*">=\s*0|azurerm_.*enable_https_traffic_only'
if grep -RqE "$DEPRECATED" . --include='*.tf' 2>/dev/null; then
  note "padrão possivelmente deprecado encontrado (conferir contra a versão latest do provider)"
else
  ok "sem padrão deprecado óbvio"
fi

echo "== fim =="
if [ "$FAIL" -ne 0 ]; then
  echo "FINDINGS encontrados — corrigir antes de considerar pronto." >&2
  exit 1
fi
echo "OK — nenhum finding determinístico."
