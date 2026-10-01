#!/usr/bin/env bash
# S2 — Matriz de 26 rotas, por perfil (UI-REWRITE-PLAN.md §3 / S2 e §4).
#
#   bash scripts/ui-routes.sh baseline [outdir]   # marcadores pre-rewrite (legado)
#   bash scripts/ui-routes.sh shell    [outdir]   # marcadores do shell daisyUI (P2 / S7)
#   bash scripts/ui-routes.sh new      [outdir]   # marcadores pos-rewrite (P3..P6)
#
# Para cada rota: faz login no perfil correto (cookie jar do baseline/ui-seed.sh),
# busca a pagina, salva o HTML e casa o marcador esperado.
# Saida: baseline/routes.tsv  (rota, perfil, status, marcador, encontrado)
# Sai != 0 se qualquer rota nao retornar 200 ou o marcador nao for encontrado.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
BASE="${BASE:-http://localhost:8080}"
DB="${DB:-gerenciador_chamados}"
MODE="${1:-baseline}"
OUTDIR="${2:-baseline/html-$MODE}"
OUT="baseline"
mkdir -p "$OUTDIR"

qs() { docker exec postgres_condominio psql -U postgres -d "$DB" -tAc "$1" | tr -d '[:space:]'; }

# ---------------------------------------------------------------- ids da fixture
MORADOR_ID="$(qs "select id from usuarios where email = 'morador@condominio.local'")"
BLOCO_ID="$(qs "select id from blocos where identificacao = 'Bloco A'")"
UNIDADE_ID="$(qs "select u.id from unidades u where u.bloco_id = '$BLOCO_ID' order by u.identificacao limit 1")"
AREA_ID="$(qs "select id from areas where nome = 'Piscina'")"
CHAMADO_ID="$(qs "select id from chamados order by data_abertura limit 1")"
DATA_RESERVA="$(qs "select to_char(inicio, 'YYYY-MM-DD') from solicitacoes_area order by inicio limit 1")"

for v in MORADOR_ID UNIDADE_ID AREA_ID CHAMADO_ID DATA_RESERVA; do
    [ -n "${!v}" ] || { echo "[routes] FAIL fixture incompleta: $v vazio — rode scripts/ui-seed.sh"; exit 1; }
done

# ---------------------------------------------------------------- tabela
# rota|perfil|marcador baseline|marcador shell (S7)|marcador pos-rewrite
# A coluna "shell" existe porque o rewrite e incremental: entre S7 e S16 apenas o shell
# esta em daisyUI, e usar os marcadores finais nessas fases daria falso negativo.
ROWS="
/login|public|auth-layout|auth-layout|card-body
/admin|admin|stats-grid|drawer-side|stats
/morador|morador|stats-grid|drawer-side|stats
/colaborador|colaborador|stats-grid|drawer-side|stats
/admin/blocos|admin|two-column-grid|drawer-side|fieldset
/admin/blocos/$BLOCO_ID|admin|hero-card|drawer-side|stats
/admin/areas|admin|two-column-grid|drawer-side|table
/admin/tipos-chamado|admin|two-column-grid|drawer-side|fieldset
/admin/status-chamado|admin|status-row|drawer-side|btn-disabled
/admin/usuarios|admin|two-column-grid|drawer-side|table
/admin/usuarios/$MORADOR_ID|admin|two-column-grid|drawer-side|divider
/admin/vinculos-morador|admin|pagination|drawer-side|join
/admin/escopo-colaborador|admin|two-column-grid|drawer-side|fieldset
/admin/chamados|admin|data-table|drawer-side|table-zebra
/admin/chamados/$CHAMADO_ID|admin|timeline|drawer-side|timeline-box
/admin/reservas|admin|status-pill|drawer-side|badge
/admin/reservas/agenda|admin|id=\"calendar\"|drawer-side|join
/morador/chamados|morador|filter-grid|drawer-side|select
/morador/chamados/novo|morador|narrow-content|drawer-side|file-input
/morador/chamados/$CHAMADO_ID|morador|timeline|drawer-side|timeline-box
/morador/reservas|morador|status-pill|drawer-side|badge
/morador/reservas/nova|morador|datetime-local|drawer-side|validator
/morador/reservas/disponibilidade?areaId=$AREA_ID&data=$DATA_RESERVA|morador|inline-panel|drawer-side|badge-success
/morador/reservas/agenda|morador|id=\"calendar\"|drawer-side|join
/colaborador/chamados|colaborador|data-table|drawer-side|table-zebra
/colaborador/chamados/$CHAMADO_ID|colaborador|timeline|drawer-side|timeline-box
"

jar_for() { case "$1" in public) echo "" ;; *) echo "$OUT/$1.jar" ;; esac; }
slug_for() { printf '%s' "$1" | sed 's/?.*//; s|^/||; s|/|-|g' | sed 's/^-*//' ; }

: > "$OUT/routes.tsv"
fails=0
count=0

while IFS='|' read -r route role marker_base marker_shell marker_new; do
    [ -n "$route" ] || continue
    count=$((count + 1))
    case "$MODE" in
        baseline) marker="$marker_base" ;;
        shell)    marker="$marker_shell" ;;
        new)      marker="$marker_new" ;;
        *) echo "[routes] modo invalido: $MODE (use baseline|shell|new)"; exit 2 ;;
    esac
    jar="$(jar_for "$role")"
    file="$OUTDIR/$(slug_for "$route").html"

    if [ -n "$jar" ] && [ ! -f "$jar" ]; then
        echo "[routes] FAIL sessao ausente: $jar — rode scripts/ui-seed.sh"; exit 1
    fi

    if [ -n "$jar" ]; then
        status="$(curl -s -b "$jar" -o "$file" -w '%{http_code}' "$BASE$route")"
    else
        status="$(curl -s -o "$file" -w '%{http_code}' "$BASE$route")"
    fi

    found=0
    grep -qF -- "$marker" "$file" 2>/dev/null && found=1

    flag="ok  "
    if [ "$status" != "200" ] || [ "$found" != "1" ]; then flag="FAIL"; fails=$((fails + 1)); fi
    printf '%s %-3s %-58s %-12s %-18s %s\n' "$flag" "$status" "$route" "$role" "$marker" "$([ "$found" = 1 ] && echo found || echo MISSING)"

    printf '%s\t%s\t%s\t%s\t%s\n' "$route" "$role" "$status" "$marker" "$found" >> "$OUT/routes.tsv"
done <<< "$ROWS"

echo
echo "[routes] $((count - fails))/$count rotas OK (modo=$MODE, html em $OUTDIR/)"
[ "$fails" -eq 0 ] || { echo "[routes] $fails rota(s) falharam"; exit 1; }
