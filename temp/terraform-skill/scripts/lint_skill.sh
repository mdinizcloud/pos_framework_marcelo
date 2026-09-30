#!/usr/bin/env bash
# Lint dos artefatos DA SKILL terraform-skill (não de um projeto gerado).
# Roda no pre-commit do skills_registry quando a skill muda, e pode rodar à mão.
# Checa: fmt do template, JSON dos evals, sintaxe dos scripts shell, frontmatter do SKILL.md.
#
# Uso: scripts/lint_skill.sh   (rodar da raiz da skill)

set -uo pipefail
cd "$(dirname "$0")/.."
FAIL=0
note() { echo "  ✗ $*"; FAIL=1; }
ok()   { echo "  ✓ $*"; }

echo "== lint_skill: $(pwd) =="

# 1. terraform fmt do template (.tf) -------------------------------------------
if command -v terraform >/dev/null 2>&1; then
  if terraform fmt -check -recursive templates/project-template >/dev/null 2>&1; then
    ok "terraform fmt (templates/project-template)"
  else
    note "terraform fmt -check falhou em templates/project-template (rodar: terraform fmt -recursive templates/project-template)"
  fi
else
  echo "  ~ terraform não instalado — pulando fmt"
fi

# 2. terragrunt hcl format do template (.hcl), se disponível -------------------
# "hcl format --check" (não "hclfmt --check") — CLI redesenhado no Terragrunt
# v1.x aposentou o subcomando antigo ("flag --check is not a valid global flag").
if command -v terragrunt >/dev/null 2>&1; then
  if terragrunt hcl format --check --working-dir templates/project-template >/dev/null 2>&1; then
    ok "terragrunt hcl format (templates/project-template)"
  else
    note "terragrunt hcl format --check falhou em templates/project-template"
  fi
else
  echo "  ~ terragrunt não instalado — pulando hcl format"
fi

# 3. evals.json válido ----------------------------------------------------------
if python3 -m json.tool evals/evals.json >/dev/null 2>&1; then
  ok "evals/evals.json é JSON válido"
else
  note "evals/evals.json não é JSON válido"
fi

# 4. sintaxe dos scripts shell --------------------------------------------------
for s in scripts/*.sh templates/project-template/scripts/*.sh; do
  [ -f "$s" ] || continue
  if bash -n "$s" 2>/dev/null; then ok "bash -n $s"; else note "erro de sintaxe em $s"; fi
done

# 4b. sintaxe dos scripts python --------------------------------------------------
for s in scripts/*.py templates/project-template/scripts/*.py; do
  [ -f "$s" ] || continue
  if python3 -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" "$s" 2>/dev/null; then
    ok "python3 -m ast $s"
  else
    note "erro de sintaxe em $s"
  fi
done

# 5. frontmatter do SKILL.md: name == nome do diretório -------------------------
DIRNAME="$(basename "$(pwd)")"
SKILLNAME="$(grep -m1 '^name:' SKILL.md | awk '{print $2}')"
if [ "$DIRNAME" = "$SKILLNAME" ]; then
  ok "SKILL.md name ($SKILLNAME) == diretório"
else
  note "SKILL.md name ($SKILLNAME) != diretório ($DIRNAME)"
fi

echo "== fim =="
if [ "$FAIL" -ne 0 ]; then echo "LINT falhou." >&2; exit 1; fi
echo "OK — lint limpo."
