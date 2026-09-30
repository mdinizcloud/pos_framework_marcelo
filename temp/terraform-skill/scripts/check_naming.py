#!/usr/bin/env python3
"""Checagem determinística de references/checklist.md §6 (naming) + segredo hardcoded.

Parser regex + contagem de chaves (sem dependência externa) sobre .tf/.hcl.
Não substitui `terraform validate` — cobre o que fmt/validate não pegam:
description/type ausente, nome de resource repetindo o tipo, variável sensível
sem `sensitive = true`, segredo literal em `inputs {}` do Terragrunt (commitado),
e module dentro de modules/ chamando outro module (child module não deve
chamar child module — checklist.md §2).

Uso:
  scripts/check_naming.py <path-do-projeto> [--json]

Saída: 1 finding por linha; exit 1 se houver algum. --json para saída estruturada.
"""

import argparse
import json
import os
import re
import sys

SECRET_NAME_RE = re.compile(r"(password|secret|token|credential|private_key|api_key)", re.I)
SKIP_DIRS = {".terraform", ".terragrunt-cache", ".git"}


def find_files(root):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for f in filenames:
            if f.endswith((".tf", ".hcl")):
                yield os.path.join(dirpath, f)


def extract_labeled_blocks(text, keyword):
    """Blocos tipo `keyword "a" "b" { ... }` — retorna (labels, body)."""
    pattern = re.compile(rf'\b{keyword}\s+((?:"[^"]*"\s*)+)\{{')
    for m in pattern.finditer(text):
        start = m.end()
        depth, i = 1, m.end()
        while i < len(text) and depth > 0:
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
            i += 1
        yield m.group(1).strip(), text[start : i - 1]


def extract_assignment_blocks(text, keyword):
    """Blocos tipo `keyword = { ... }` (ex: inputs do Terragrunt)."""
    pattern = re.compile(rf"\b{keyword}\s*=\s*\{{")
    for m in pattern.finditer(text):
        depth, i = 1, m.end()
        while i < len(text) and depth > 0:
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
            i += 1
        yield text[m.end() : i - 1]


def check_variables(path, text, findings):
    for labels, body in extract_labeled_blocks(text, "variable"):
        name = labels.strip('"')
        if not re.search(r"\bdescription\s*=", body):
            findings.append((path, f'variable "{name}" sem description'))
        if not re.search(r"\btype\s*=", body):
            findings.append((path, f'variable "{name}" sem type'))
        if SECRET_NAME_RE.search(name) and not re.search(r"\bsensitive\s*=\s*true", body):
            findings.append((path, f'variable "{name}" parece sensível mas sem sensitive = true'))


WHOLE_RESOURCE_VALUE_RE = re.compile(r'^\s*(?:module\.)?[a-zA-Z_][\w]*\.[a-zA-Z_][\w]*\s*$')


def check_outputs(path, text, findings):
    for labels, body in extract_labeled_blocks(text, "output"):
        name = labels.strip('"')
        if not re.search(r"\bdescription\s*=", body):
            findings.append((path, f'output "{name}" sem description'))
        m = re.search(r"\bvalue\s*=\s*(.+)", body)
        if m:
            value_line = m.group(1).splitlines()[0].rstrip(",")
            # Heurística conservadora: só flag "tipo.nome" com exatamente 1 ponto (resource
            # inteiro). "tipo.nome.atributo" (2+ pontos) ou splat/index/função não é flagado —
            # evita falso positivo, prefere deixar passar a acusar errado.
            if WHOLE_RESOURCE_VALUE_RE.match(value_line):
                findings.append((path, f'output "{name}" expõe o resource inteiro ("{value_line.strip()}") — usar atributo específico (ex: "{value_line.strip()}.id")'))


def check_resource_naming(path, text, findings):
    for m in re.finditer(r'\bresource\s+"([^"]+)"\s+"([^"]+)"\s*\{', text):
        rtype, rname = m.group(1), m.group(2)
        if rname == rtype:
            findings.append((path, f'resource "{rtype}" "{rname}" — nome repete o tipo'))


def check_hardcoded_secrets(path, text, findings):
    # inputs {} do Terragrunt é COMMITADO — segredo literal aí vaza pro git.
    for body in extract_assignment_blocks(text, "inputs"):
        for m in re.finditer(r'(\w*(?:password|secret|token|credential|private_key|api_key)\w*)\s*=\s*"([^"$]{3,})"', body, re.I):
            key, val = m.group(1), m.group(2)
            findings.append((path, f'inputs.{key} parece segredo hardcoded ("{val[:4]}...") — usar TF_VAR_*/secret manager, nunca literal commitado'))


def check_child_module_calls_module(path, text, findings):
    norm = path.replace("\\", "/")
    if "/modules/" in norm and re.search(r'\bmodule\s+"[^"]+"\s*\{', text):
        findings.append((path, "module chamando outro module dentro de modules/ — child module não deve chamar child module (checklist §2)"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("path")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    findings = []
    for path in find_files(args.path):
        try:
            text = open(path, encoding="utf-8").read()
        except OSError:
            continue
        check_variables(path, text, findings)
        check_outputs(path, text, findings)
        check_resource_naming(path, text, findings)
        check_hardcoded_secrets(path, text, findings)
        check_child_module_calls_module(path, text, findings)

    if args.json:
        print(json.dumps([{"file": p, "finding": f} for p, f in findings], indent=2))
    else:
        for p, f in findings:
            print(f"  ✗ {p}: {f}")
        if not findings:
            print("OK — nenhum finding de naming/segredo.")

    sys.exit(1 if findings else 0)


if __name__ == "__main__":
    main()
