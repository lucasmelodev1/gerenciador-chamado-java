#!/usr/bin/env bash
# S33 — remocao do CSS legado (`base.css`, `layout.css`, `components.css`,
# `responsive.css`). Plano em UI-REWRITE-PLAN.md > S17/S18.
#
#   bash scripts/ui-legado.sh inventario   # lista o que ainda falta migrar (nao falha)
#   bash scripts/ui-legado.sh check        # falha se sobrar arquivo, <link> ou classe legada
#
# Por que existe: os quatro arquivos nao estao em cascade layer, entao venciam a
# daisyUI/Tailwind onde os dois definiam a mesma propriedade. Migrar uma classe por vez e
# aditivo (a regra antiga simplesmente deixa de casar); o desligamento e ato unico, no F6.
# Sem este guard nada impede alguem de reintroduzir uma classe legada no markup.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

WEBAPP="src/main/webapp"
CSS_DIR="src/main/resources/static/css"
HEAD="$WEBAPP/WEB-INF/jsp/fragments/head.jspf"
LEGADOS=(base layout components responsive)

# Inventario dos 41 seletores dos quatro arquivos no inicio da S33.
#   - `card` e `divider` NAO entram: sao componentes da daisyUI que o app usa de verdade.
#   - `list-row` e `timeline` entram: a daisyUI tambem os define, mas a aparencia de hoje e
#     a do legado; a F4 decide se adota o componente (e entao sai daqui).
CLASSES=(
    auth-body
    auth-brand
    auth-form-panel
    auth-layout
    auth-panel
    button-row
    cell-actions
    compact
    compact-form
    danger-zone
    description-box
    detail-grid
    detail-list
    empty-state
    eyebrow
    feature-list
    field
    field-hint
    form-grid
    hero-card
    hero-metrics
    inline-form
    inline-panel
    is-hidden
    link-row
    list-row
    narrow-content
    page-content
    pagination
    password-field
    section-header
    stack-form
    stack-list
    stat-card
    stat-card-wide
    stats-grid
    timeline
    timeline-item
    two-column-grid
)

modo="${1:-check}"
case "$modo" in
    inventario|check) ;;
    *) echo "usage: $0 [inventario|check]"; exit 2 ;;
esac

falhas=0
ok()  { printf '  OK   %s\n' "$*"; }
bad() { printf '  FAIL %s\n' "$*"; falhas=1; }

echo "== arquivos e <link> =="
for f in "${LEGADOS[@]}"; do
    if [ -f "$CSS_DIR/$f.css" ]; then
        if [ "$modo" = "inventario" ]; then
            printf '  pendente  %s.css (%s linhas)\n' "$f" "$(wc -l < "$CSS_DIR/$f.css" | tr -d ' ')"
        else
            bad "$f.css ainda existe"
        fi
    else
        ok "$f.css removido"
    fi

    if grep -q "/css/$f.css" "$HEAD" 2>/dev/null; then
        if [ "$modo" = "inventario" ]; then
            printf '  linkado   %s.css\n' "$f"
        else
            bad "head.jspf ainda linka $f.css"
        fi
    fi
done

echo "== classes no markup =="
python3 - "$WEBAPP" "$modo" "${CLASSES[@]}" <<'PY'
import re
import sys
from pathlib import Path

raiz = Path(sys.argv[1])
modo = sys.argv[2]
classes = set(sys.argv[3:])

comentario = re.compile(r"<%--.*?--%>|<!--.*?-->", re.S)
expressao = re.compile(r"\$\{[^}]*\}")

sobras = {}
for ext in ("*.jsp", "*.jspf", "*.tag"):
    for arquivo in sorted(raiz.rglob(ext)):
        texto = comentario.sub("", arquivo.read_text(encoding="utf-8"))
        for atributo in ("class", "classe", "classeMain"):
            for encontrado in re.finditer(atributo + r'="([^"]*)"', texto):
                for token in expressao.sub(" ", encontrado.group(1)).split():
                    if token in classes:
                        sobras.setdefault(token, set()).add(str(arquivo.relative_to(raiz)))

if not sobras:
    print("  OK   nenhuma classe legada no markup")
    sys.exit(0)

if modo == "inventario":
    print(f"  {len(sobras)} classe(s) pendente(s):")
    for token in sorted(sobras):
        arquivos = ", ".join(sorted(sobras[token]))
        print(f"    {token:16} {len(sobras[token]):>2} arquivo(s): {arquivos}")
    sys.exit(0)

print(f"  FAIL {len(sobras)} classe(s) legada(s) no markup:")
for token in sorted(sobras):
    for arquivo in sorted(sobras[token]):
        print(f"    {arquivo}: {token}")
sys.exit(1)
PY

echo
if [ "$modo" = "inventario" ]; then
    echo "LEGADO — inventario acima (check completo a partir do F6)"
else
    if [ "$falhas" -eq 0 ]; then echo "LEGADO OK"; else echo "LEGADO PENDENTE"; fi
    exit "$falhas"
fi
