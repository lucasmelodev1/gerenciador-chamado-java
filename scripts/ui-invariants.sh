#!/usr/bin/env bash
# S3 — Invariant guard (UI-REWRITE-PLAN.md §3 / S3, contract in §1).
#
# The UI rewrite is presentation-only. This script is the machine checkable form of
# that promise: it freezes the contract the JSPs share with the controllers, the
# tests, the JS and the build, and fails on any accidental drift.
#
#   bash scripts/ui-invariants.sh snapshot   # write baseline/invariants/*
#   bash scripts/ui-invariants.sh check      # compare current tree against the snapshot
#
# Exit code: 0 = contract intact, 1 = drift detected (details on stdout).
#
# Deliberately NOT frozen (intentional changes, tracked in the plan):
#   - data-sidebar, data-sidebar-toggle, data-sidebar-backdrop  -> removed by S7 (daisyUI drawer)
#   - the split between data-confirm and inline onsubmit confirm -> normalised by S13
#   - legacy presentation classes (data-table, status-pill, ...)  -> deleted by S7/S10/S17
#
# Contagem de markup repetido NAO e congelada (ver `collect_form_contract`): extrair um
# formulario ou um include repetido para um componente/tag derruba o total sem perder
# invariante nenhum, e um piso de contagem leria isso como regressao. O que se congela e
# ESTRUTURA (todo form nao-GET tem CSRF, todo `_method`/`data-confirm` vive num form,
# toda pagina declara o marcador do <body>).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

WEBAPP="${WEBAPP:-src/main/webapp}"

# Os coletores contam SO markup. O `CONTEXT.md` de cada diretorio vive dentro de
# `src/main/webapp` e, sem este filtro, escrever um `name="_method"` ou um `data-*` na
# documentacao movia o floor — foi o que aconteceu na S26, quando as telas passaram a ser
# montadas por tags e os CONTEXT.md comecaram a citar o markup que eles emitem.
MARKUP=(--include='*.jsp' --include='*.jspf' --include='*.tag')
CONTROLLERS="src/main/java/br/com/dunnastecnologia/chamados/infrastructure/controller/web"
SNAP="baseline/invariants"

# Hooks owned by the JS/CSS and by calendar.js. Each must never drop below its snapshot count.
# data-sidebar* is excluded on purpose: S7 replaces the sidebar JS with the daisyUI drawer.
FROZEN_HOOKS=(
    data-confirm
    data-password-toggle data-password-input
    data-character-count data-character-output
    data-auto-submit
    data-filter-input data-filter-target data-filter-table
    data-drawer data-drawer-abrir data-drawer-fechar data-drawer-aberto data-drawer-backdrop
    data-drawer-editar data-drawer-form data-drawer-titulo
    data-detalhe
    data-alert data-dismiss-alert
    data-view data-referencia data-base-url data-modo
    data-id data-area-id data-start data-end data-area data-morador data-unidade data-status
    data-inicio-formatado data-fim-formatado data-motivo
)

# Calendar contract consumed by calendar.js (ids and hooks inside reservas-agenda.jspf,
# reservas-agenda-paineis.jspf and the two agenda JSPs).
#
# S30 trocou o painel de detalhe no fim da pagina por um `ui:drawer` e o formulario escondido
# de cancelamento por um `ui:dialog` central: sairam `id="reserva-detalhe"`,
# `.reserva-titulo|meta|motivo`, `id="form-aprovar|negar|cancelar"` e `id="reserva-fechar"`,
# e entraram o drawer (com a lista `data-detalhe`, que esta em FROZEN_HOOKS) e o gatilho que
# aponta o dialogo para a reserva clicada.
FROZEN_CALENDAR=(
    'id="calendar"' 'id="reservas-data"' 'reserva-data' 'id="filtro-area"'
    'id="drawer-reserva"' 'painelAcao="dialog-cancelamento"' 'data-drawer-editar="${painelAcao}"'
)

fail=0
note() { printf '  %s\n' "$*"; }
ok()   { printf '  OK   %s\n' "$*"; }
bad()  { printf '  FAIL %s\n' "$*"; fail=1; }

# ---------------------------------------------------------------- collectors

collect_view_names() {
    grep -rhoE 'return "(admin|morador|colaborador|auth)/[A-Za-z0-9/_-]+"' "$CONTROLLERS"/*.java \
        | sed -E 's/^return "//; s/"$//' | sort -u
}

collect_action_urls() {
    grep -rhoE 'action="[^"]*"' "${MARKUP[@]}" "$WEBAPP" | sed -E 's/^action="//; s/"$//' | sort | uniq -c \
        | sed -E 's/^ +//'
}

collect_counts() {
    printf 'multipart_forms=%s\n' "$(grep -rho 'enctype="multipart/form-data"' "${MARKUP[@]}" "$WEBAPP" | wc -l | tr -d ' ')"
    printf 'utf8_decls=%s\n'     "$(grep -rhoE 'charset=UTF-8|pageEncoding="UTF-8"' "${MARKUP[@]}" "$WEBAPP" | wc -l | tr -d ' ')"
    printf 'jacoco_includes=%s\n' "$(grep -c '<include>br/com/dunnastecnologia/chamados/\(domain\|infrastructure\)' pom.xml)"
    printf 'jacoco_min=%s\n'     "$(grep -A3 COVEREDRATIO pom.xml | grep -oE '<minimum>[0-9.]+' | grep -oE '[0-9.]+')"
}

collect_hooks() {
    local hook
    for hook in "${FROZEN_HOOKS[@]}"; do
        printf '%s\t%s\n' "$(grep -rho "$hook" "${MARKUP[@]}" "$WEBAPP" | wc -l | tr -d ' ')" "$hook"
    done
}

collect_calendar() {
    local sel
    for sel in "${FROZEN_CALENDAR[@]}"; do
        printf '%s\t%s\n' "$(grep -rhoF "$sel" "${MARKUP[@]}" "$WEBAPP" | wc -l | tr -d ' ')" "$sel"
    done
}

# ---------------------------------------------------------------- estrutura

# Contagem de forms/CSRF e um piso ruim: extrair um formulario repetido para um
# componente derruba o numero sem perder invariante nenhum. Estas checagens olham a
# ESTRUTURA — o que precisa ser verdade em qualquer arranjo:
#   1. todo <form> NAO-GET carrega o `csrf.jspf` (ou o input `${_csrf.*}`) no proprio corpo;
#   2. todo `name="_method"` vive dentro de um <form> nao-GET;
#   3. todo `data-confirm` esta dentro de um <form> (confirmacao de envio);
#   4. nenhum `<form method="get">` carrega `_method` (sobrescrita de metodo sem sentido).
# Comentarios JSP/HTML saem antes da leitura: os comentarios dos tags citam markup.
collect_form_contract() {
    python3 - "$WEBAPP" <<'PY'
import re
import sys
from pathlib import Path

raiz = Path(sys.argv[1])
arquivos = sorted(p for ext in ("*.jsp", "*.jspf", "*.tag") for p in raiz.rglob(ext))

comentario_jsp = re.compile(r"<%--.*?--%>", re.S)
comentario_html = re.compile(r"<!--.*?-->", re.S)
# Diretivas (`<%@ ... %>`) sao metadados: o `description` de um `attribute` pode citar um
# hook ("texto do data-confirm") e isso nao e markup. A checagem de CSRF, porem, precisa
# do `<%@ include file=".../csrf.jspf" %>`, entao as diretivas so saem na leitura de hooks.
diretiva = re.compile(r"<%@.*?%>", re.S)
form = re.compile(r"<form\b[^>]*>.*?</form>", re.S)

violacoes = []
nao_get = get = methods = 0
data_confirm = data_confirm_fora = 0

for arq in arquivos:
    bruto = comentario_html.sub("", comentario_jsp.sub("", arq.read_text(encoding="utf-8")))
    sem_diretiva = diretiva.sub("", bruto)
    sem_form = form.sub("", sem_diretiva)

    for bloco in form.findall(bruto):
        abertura = bloco[: bloco.index(">") + 1]
        proibido = re.findall(r'name="_method"', bloco)
        if re.search(r'method\s*=\s*"get"', abertura, re.I):
            get += 1
            if proibido:
                violacoes.append(f"{arq}: form GET com _method -> {abertura.strip()[:70]}")
            continue

        nao_get += 1
        if "fragments/csrf.jspf" not in bloco and "${_csrf.parameterName}" not in bloco:
            violacoes.append(f"{arq}: form nao-GET sem csrf.jspf -> {abertura.strip()[:70]}")
        methods += len(proibido)

    if re.search(r'name="_method"', sem_form):
        violacoes.append(f"{arq}: name=\"_method\" fora de <form>")

    data_confirm += sem_diretiva.count("data-confirm")
    fora = sem_form.count("data-confirm")
    data_confirm_fora += fora
    if fora:
        violacoes.append(f"{arq}: {fora} data-confirm fora de <form>")

for v in violacoes:
    print(f"VIOLACAO\t{v}")
print(f"forms_nao_get={nao_get}")
print(f"forms_get={get}")
print(f"method_inputs_em_form={methods}")
print(f"data_confirm_em_form={data_confirm - data_confirm_fora}")
PY
}

# Toda pagina JSP declara o marcador do <body> — hoje `data-page="..."`, e a partir do
# `ui:shell` o atributo `dataPagina` do proprio tag. O valor nao tem consumidor; o que a
# checagem protege e a presenca (a animacao de `base.css` depende dela).
check_page_markers() {
    local total=0 faltando=""
    while IFS= read -r jsp; do
        grep -q '<!DOCTYPE html>' "$jsp" || continue
        total=$((total + 1))
        grep -qE 'data-page=|dataPagina=' "$jsp" || faltando="$faltando $jsp"
    done < <(find "$WEBAPP/WEB-INF/jsp" -name '*.jsp' | sort)

    if [ -z "$faltando" ]; then
        ok "marcador do <body> (data-page/dataPagina) nas $total paginas"
    else
        bad "pagina(s) sem marcador do <body>:$faltando"
    fi
}

check_form_contract() {
    collect_form_contract > /tmp/ui-inv.form
    if grep -q '^VIOLACAO' /tmp/ui-inv.form; then
        bad "contrato dos formularios violado"
        grep '^VIOLACAO' /tmp/ui-inv.form | sed 's/^VIOLACAO\t/    /'
        return
    fi

    local nao_get get methods confirms
    nao_get="$(grep '^forms_nao_get=' /tmp/ui-inv.form | cut -d= -f2)"
    get="$(grep '^forms_get=' /tmp/ui-inv.form | cut -d= -f2)"
    methods="$(grep '^method_inputs_em_form=' /tmp/ui-inv.form | cut -d= -f2)"
    confirms="$(grep '^data_confirm_em_form=' /tmp/ui-inv.form | cut -d= -f2)"
    ok "todo form nao-GET tem csrf ($nao_get nao-GET, $get GET)"
    ok "todo _method dentro de form ($methods) e todo data-confirm em form ($confirms)"
}

# ---------------------------------------------------------------- modes

snapshot() {
    mkdir -p "$SNAP"
    collect_view_names  > "$SNAP/view-names.txt"
    collect_action_urls > "$SNAP/action-urls.txt"
    collect_counts      > "$SNAP/counts.txt"
    collect_hooks       > "$SNAP/hooks.txt"
    collect_calendar    > "$SNAP/calendar.txt"
    git rev-parse HEAD  > "$SNAP/baseline-commit.txt"
    echo "snapshot written to $SNAP/ ($(grep -c . "$SNAP/view-names.txt") view names, $(grep -c . "$SNAP/action-urls.txt") form actions)"
}

check_file() { # <label> <expected-file> <actual-file>
    if diff -u "$2" "$3" > /tmp/ui-inv.diff 2>&1; then
        ok "$1"
    else
        bad "$1"
        note "diff (expected vs actual):"
        sed 's/^/    /' /tmp/ui-inv.diff
    fi
}

check_floor() { # <label> <expected-min> <actual>
    if [ "$3" -ge "$2" ]; then
        ok "$1 = $3 (>= $2)"
    else
        bad "$1 = $3 (< $2) — invariant dropped"
    fi
}

check() {
    [ -f "$SNAP/counts.txt" ] || { echo "no snapshot; run: bash scripts/ui-invariants.sh snapshot"; exit 2; }

    echo "== view names =="
    collect_view_names > /tmp/ui-inv.views
    check_file "26 view names unchanged" "$SNAP/view-names.txt" /tmp/ui-inv.views

    echo "== form contract =="
    collect_action_urls > /tmp/ui-inv.actions
    check_file "form action URLs unchanged" "$SNAP/action-urls.txt" /tmp/ui-inv.actions
    check_form_contract
    check_page_markers

    echo "== contagens congeladas =="
    collect_counts > /tmp/ui-inv.counts
    while IFS='=' read -r key expected; do
        actual="$(grep "^$key=" /tmp/ui-inv.counts | cut -d= -f2)"
        if [ -z "$actual" ]; then
            bad "$key ausente do coletor (rode: bash scripts/ui-invariants.sh snapshot)"
            continue
        fi
        case "$key" in
            jacoco_min|jacoco_includes)
                if [ "$expected" = "$actual" ]; then ok "$key = $actual"; else bad "$key = $actual (expected $expected)"; fi ;;
            *)
                check_floor "$key" "$expected" "$actual" ;;
        esac
    done < "$SNAP/counts.txt"

    echo "== JS/CSS hooks =="
    collect_hooks > /tmp/ui-inv.hooks
    while IFS=$'\t' read -r expected hook; do
        actual="$(awk -F'\t' -v k="$hook" '$2==k{print $1}' /tmp/ui-inv.hooks)"
        if [ "${actual:-0}" -ge "$expected" ] 2>/dev/null; then
            ok "$hook = $actual (>= $expected)"
        else
            bad "$hook = ${actual:-0} (< $expected) — hook lost"
        fi
    done < "$SNAP/hooks.txt"

    echo "== calendar contract =="
    collect_calendar > /tmp/ui-inv.calendar
    while IFS=$'\t' read -r expected sel; do
        actual="$(awk -F'\t' -v k="$sel" '$2==k{print $1}' /tmp/ui-inv.calendar)"
        if [ "${actual:-0}" -ge "$expected" ] 2>/dev/null; then
            ok "$sel = $actual (>= $expected)"
        else
            bad "$sel = ${actual:-0} (< $expected) — calendar.js selector lost"
        fi
    done < "$SNAP/calendar.txt"

    echo "== backend scope =="
    base="$(cat "$SNAP/baseline-commit.txt")"
    drift="$(git diff --name-only "$base" -- src/main/java src/main/resources/db pom.xml | wc -l | tr -d ' ')"
    if [ "$drift" -eq 0 ]; then
        ok "no changes under src/main/java, src/main/resources/db, pom.xml"
    else
        bad "$drift backend file(s) changed since $base:"
        git diff --name-only "$base" -- src/main/java src/main/resources/db pom.xml | sed 's/^/    /'
    fi

    echo
    if [ "$fail" -eq 0 ]; then echo "INVARIANTS OK"; else echo "INVARIANTS VIOLATED"; fi
    return "$fail"
}

case "${1:-check}" in
    snapshot) snapshot ;;
    check)    check ;;
    *) echo "usage: $0 [snapshot|check]"; exit 2 ;;
esac
