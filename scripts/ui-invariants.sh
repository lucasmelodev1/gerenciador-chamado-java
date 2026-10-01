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
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

WEBAPP="src/main/webapp"
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
    data-alert data-dismiss-alert
    data-page
    data-view data-referencia data-base-url data-modo
    data-id data-area-id data-start data-end data-area data-morador data-unidade data-status
    data-inicio-formatado data-fim-formatado data-motivo
)

# Calendar contract consumed by calendar.js (ids and classes inside reservas-agenda.jspf / agenda JSPs).
FROZEN_CALENDAR=(
    'id="calendar"' 'id="reservas-data"' 'reserva-data' 'id="reserva-detalhe"'
    'reserva-titulo' 'reserva-meta' 'reserva-motivo'
    'id="form-aprovar"' 'id="form-negar"' 'id="form-cancelar"'
    'id="filtro-area"' 'id="reserva-fechar"'
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
    grep -rhoE 'action="[^"]*"' "$WEBAPP" | sed -E 's/^action="//; s/"$//' | sort | uniq -c \
        | sed -E 's/^ +//'
}

collect_counts() {
    printf 'method_inputs=%s\n'  "$(grep -rho 'name="_method"' "$WEBAPP" | wc -l | tr -d ' ')"
    printf 'csrf_includes=%s\n'  "$(grep -rho 'fragments/csrf.jspf' "$WEBAPP" | wc -l | tr -d ' ')"
    printf 'multipart_forms=%s\n' "$(grep -rho 'enctype="multipart/form-data"' "$WEBAPP" | wc -l | tr -d ' ')"
    printf 'confirmations=%s\n'  "$(( $(grep -rho 'data-confirm' "$WEBAPP" | wc -l) + $(grep -rho 'onsubmit="return confirm' "$WEBAPP" | wc -l) ))"
    printf 'utf8_decls=%s\n'     "$(grep -rhoE 'charset=UTF-8|pageEncoding="UTF-8"' "$WEBAPP" | wc -l | tr -d ' ')"
    printf 'jacoco_includes=%s\n' "$(grep -c '<include>br/com/dunnastecnologia/chamados/\(domain\|infrastructure\)' pom.xml)"
    printf 'jacoco_min=%s\n'     "$(grep -A3 COVEREDRATIO pom.xml | grep -oE '<minimum>[0-9.]+' | grep -oE '[0-9.]+')"
}

collect_hooks() {
    local hook
    for hook in "${FROZEN_HOOKS[@]}"; do
        printf '%s\t%s\n' "$(grep -rho "$hook" "$WEBAPP" | wc -l | tr -d ' ')" "$hook"
    done
}

collect_calendar() {
    local sel
    for sel in "${FROZEN_CALENDAR[@]}"; do
        printf '%s\t%s\n' "$(grep -rhoF "$sel" "$WEBAPP" | wc -l | tr -d ' ')" "$sel"
    done
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
    collect_counts > /tmp/ui-inv.counts
    while IFS='=' read -r key expected; do
        actual="$(grep "^$key=" /tmp/ui-inv.counts | cut -d= -f2)"
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
