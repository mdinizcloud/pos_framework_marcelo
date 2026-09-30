#!/usr/bin/env python3
"""
Harness de validação da skill reducao-token.

Prova, com números reais e execução externa via API, que um alvo comprimido
(skill, agent ou prompt de IA — nunca documento de negócio/arquitetura como
ADR/TDR/PDR) gera a MESMA saída que o original com menos tokens.

Faz duas coisas que o modelo sozinho não faz de forma confiável:
  1. conta TOKENS reais (API count_tokens da Anthropic — nunca tiktoken, que
     subestima tokens de Claude em ~15-20%);
  2. executa original e reduzido pela Messages API com o MESMO input fixo, e
     compara as saídas — prova determinística externa, não auto-simulação.

Subcomandos:
  count     conta tokens+chars de um ou dois arquivos (delta se dois)
  validate  roda N casos de teste contra original e reduzido e emite a tabela

Determinismo: os modelos atuais (claude-opus-4-8, sonnet-5, fable-5) REJEITAM
`temperature`/`top_p` com 400 — o harness não os envia. Reprodutibilidade vem de
usar effort baixo e o MESMO input em ambos os lados; divergência é sempre falha a
investigar, nunca "provável ok". Rode com múltiplos casos, incluindo caso de borda.

Critério de comparação (--match):
  exact  (default) string idêntica (ignora whitespace) — use pra tarefa
         DETERMINÍSTICA: extração, classificação, formato fixo, checklist.
         Geração aberta (texto livre, ADR, redação) quase sempre diverge aqui
         mesmo com input idêntico — não é bug do alvo, é natureza da tarefa.
  rules  LLM-judge compara as 2 saídas (sem ver qual é original/reduzida) e
         julga se cobrem o mesmo conjunto de regras/comportamento, ignorando
         fraseado. Use pra tarefa de GERAÇÃO ABERTA. Judge roda no mesmo
         --model, effort=low, chamada separada — não vê o prompt-alvo, só as
         2 saídas, pra não vazar viés de qual é a versão "certa".

Uso:
  scripts/token_validate.py count  ORIGINAL.md [REDUZIDO.md]
  scripts/token_validate.py validate ORIGINAL.md REDUZIDO.md --cases casos.json \
      [--model claude-opus-4-8] [--role system|user] [--effort low] [--match exact|rules]

Formato de casos.json:
  [
    {"name": "caso 1", "input": "texto do input fixo"},
    {"name": "borda",  "input": "input que exercita uma regra rara"}
  ]

Requer: pip install anthropic  (+ credencial: ANTHROPIC_API_KEY ou `ant auth login`).
"""

import argparse
import json
import sys
from pathlib import Path

try:
    import anthropic
except ImportError:
    sys.exit("Falta a lib: pip install anthropic")

DEFAULT_MODEL = "claude-opus-4-8"


def read(path: str) -> str:
    return Path(path).read_text(encoding="utf-8")


def count_tokens(client, model: str, text: str) -> int:
    """Tokens reais via API. Model-específico — passe o mesmo model da inferência."""
    resp = client.messages.count_tokens(
        model=model,
        messages=[{"role": "user", "content": text}],
    )
    return resp.input_tokens


def run_prompt(client, model: str, prompt: str, user_input: str, role: str, effort: str) -> str:
    """Executa o alvo. role=system: prompt vira system e o caso vira a mensagem do
    usuário. role=user: prompt e caso são concatenados numa única mensagem."""
    kwargs = {
        "model": model,
        "max_tokens": 16000,
        # effort baixo = saída mais estável e barata; sobe pra 'high' se a tarefa
        # do alvo exigir raciocínio. Sem temperature (removido nos modelos atuais).
        "output_config": {"effort": effort},
    }
    if role == "system":
        kwargs["system"] = prompt
        kwargs["messages"] = [{"role": "user", "content": user_input}]
    else:
        joined = prompt if not user_input else f"{prompt}\n\n{user_input}"
        kwargs["messages"] = [{"role": "user", "content": joined}]

    resp = client.messages.create(**kwargs)
    return "".join(b.text for b in resp.content if b.type == "text").strip()


JUDGE_PROMPT = """Você julga se duas respostas de IA a um mesmo pedido são \
EQUIVALENTES em comportamento — mesmas regras seguidas, mesmo conteúdo \
essencial, mesma estrutura de seções — mesmo que o fraseado difira.

Não penalize: sinônimo, ordem de frase diferente, formatação levemente \
diferente, nível de detalhe levemente diferente, desde que a essência e as \
regras aplicadas sejam as mesmas.

Penalize (retorne DIVERGE): uma marca/regra/seção presente numa resposta e \
ausente na outra; conclusão ou decisão diferente; informação factual \
diferente; regra do pedido original seguida numa resposta e ignorada na outra.

Resposta A:
---
{a}
---

Resposta B:
---
{b}
---

Responda em EXATAMENTE 2 linhas:
VEREDITO: MATCH ou DIVERGE
RAZAO: uma frase curta explicando por quê"""


def judge_match(client, model: str, a: str, b: str) -> tuple[bool, str]:
    """LLM-judge: compara 2 saídas sem saber qual é original/reduzida."""
    resp = client.messages.create(
        model=model,
        max_tokens=300,
        output_config={"effort": "low"},
        messages=[{"role": "user", "content": JUDGE_PROMPT.format(a=a, b=b)}],
    )
    text = "".join(blk.text for blk in resp.content if blk.type == "text").strip()
    verdict_line = next((ln for ln in text.splitlines() if "VEREDITO" in ln.upper()), "")
    match = "MATCH" in verdict_line.upper() and "DIVERGE" not in verdict_line.upper()
    reason_line = next((ln for ln in text.splitlines() if ln.upper().startswith("RAZAO") or ln.upper().startswith("RAZÃO")), text)
    return match, reason_line.split(":", 1)[-1].strip() if ":" in reason_line else reason_line


def pct(orig: int, red: int) -> str:
    if orig == 0:
        return "n/a"
    return f"-{(orig - red) / orig * 100:.1f}%"


def clip(s: str, n: int = 500) -> str:
    """Corta pra caber na célula da tabela, escapando quebras de linha e pipes."""
    s = s.replace("|", "\\|").replace("\n", "<br>")
    return s if len(s) <= n else s[:n] + "…"


def cmd_count(args):
    client = anthropic.Anthropic()
    orig = read(args.original)
    ot = count_tokens(client, args.model, orig)
    print(f"{args.original}: {ot} tokens, {len(orig)} chars")
    if args.reduced:
        red = read(args.reduced)
        rt = count_tokens(client, args.model, red)
        print(f"{args.reduced}: {rt} tokens, {len(red)} chars")
        print(f"delta: {pct(ot, rt)} tokens, {pct(len(orig), len(red))} chars")


def cmd_validate(args):
    client = anthropic.Anthropic()
    orig, red = read(args.original), read(args.reduced)
    cases = json.loads(read(args.cases))
    if not isinstance(cases, list) or not cases:
        sys.exit("--cases precisa ser uma lista JSON não-vazia de {name, input}")

    ot = count_tokens(client, args.model, orig)
    rt = count_tokens(client, args.model, red)

    rows = []
    all_match = True
    for i, c in enumerate(cases):
        name = c.get("name", f"caso {i + 1}")
        inp = c.get("input", "")
        o_out = run_prompt(client, args.model, orig, inp, args.role, args.effort)
        r_out = run_prompt(client, args.model, red, inp, args.role, args.effort)

        if args.match == "rules":
            match, reason = judge_match(client, args.model, o_out, r_out)
            verdict = f"✅ equivalente ({reason})" if match else f"❌ diverge ({reason})"
        else:
            match = o_out.split() == r_out.split()  # ignora só diferença de whitespace
            verdict = "✅ igual" if match else "❌ divergiu"

        all_match = all_match and match
        rows.append((name, o_out, r_out, verdict))

    print(f"\n## Prova de redução — {args.original} → {args.reduced}\n")
    print(f"Modelo: `{args.model}` · effort: `{args.effort}` · role: `{args.role}` · match: `{args.match}` · casos: {len(cases)}\n")
    print("| Métrica | Original | Reduzido | Δ |")
    print("| :--- | :--- | :--- | :--- |")
    print(f"| **Tokens (API)** | `{ot}` | `{rt}` | `{pct(ot, rt)}` |")
    print(f"| **Caracteres** | `{len(orig)}` | `{len(red)}` | `{pct(len(orig), len(red))}` |")
    for name, o_out, r_out, verdict in rows:
        print(f"| **{clip(name, 60)}** | {clip(o_out)} | {clip(r_out)} | {verdict} |")
    print(f"| **Veredito** | — | — | {'✅ mesma saída em todos os casos' if all_match else '❌ há divergência — refine a compressão'} |")

    sys.exit(0 if all_match else 1)


def main():
    p = argparse.ArgumentParser(description="Valida a skill reducao-token com tokens reais.")
    sub = p.add_subparsers(dest="cmd", required=True)

    pc = sub.add_parser("count", help="conta tokens+chars (delta se 2 arquivos)")
    pc.add_argument("original")
    pc.add_argument("reduced", nargs="?")
    pc.add_argument("--model", default=DEFAULT_MODEL)
    pc.set_defaults(func=cmd_count)

    pv = sub.add_parser("validate", help="roda casos e emite a tabela de prova")
    pv.add_argument("original")
    pv.add_argument("reduced")
    pv.add_argument("--cases", required=True, help="JSON: [{name, input}, ...]")
    pv.add_argument("--model", default=DEFAULT_MODEL)
    pv.add_argument("--role", choices=["system", "user"], default="system",
                    help="system: prompt=system, caso=user (default). user: concatena.")
    pv.add_argument("--effort", default="low", choices=["low", "medium", "high", "xhigh", "max"])
    pv.add_argument("--match", default="exact", choices=["exact", "rules"],
                    help="exact: string idêntica (tarefa determinística). rules: LLM-judge "
                         "de equivalência comportamental (tarefa de geração aberta).")
    pv.set_defaults(func=cmd_validate)

    args = p.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
