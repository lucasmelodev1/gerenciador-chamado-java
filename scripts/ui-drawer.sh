#!/usr/bin/env bash
# S23 — Verificacao do componente `ui:drawer` e do seu uso na tela de areas.
#
# Pre-requisitos:
#   docker compose up -d app
#   bash scripts/ui-seed.sh          (cria baseline/admin.jar e a area "Piscina")
#
#   bash scripts/ui-drawer.sh
#
# Exit code: 0 = contrato e fluxo OK, 1 = divergencia.
#
# Cobre quatro camadas:
#   A. contrato do markup renderizado (cadastro e edicao) + posicao fora de .page-content
#   B. escopo — o componente e usado em UMA tela, como pedido
#   C. fluxo real criar -> editar -> remover pelo formulario do drawer
#   D. contrato do JS, incluindo a execucao dos casos de comportamento
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
BASE="${BASE:-http://localhost:8080}"
DB="${DB:-gerenciador_chamados}"
JAR="${JAR:-baseline/admin.jar}"
WORK="baseline/drawer"
mkdir -p "$WORK"

fail=0
ok()  { printf '  OK   %s\n' "$*"; }
bad() { printf '  FAIL %s\n' "$*"; fail=1; }

q() { docker exec postgres_condominio psql -U postgres -d "$DB" -tAc "$1" | tr -d '[:space:]'; }
# Igual a `q`, mas preserva os espacos internos do valor (para comparar nomes).
qv() { docker exec postgres_condominio psql -U postgres -d "$DB" -tAc "$1"; }

# Token lido do MESMO form que o drawer renderiza (o CSRF e mascarado e por requisicao).
csrf_do_drawer() { # <url>
    curl -s -b "$JAR" -c "$JAR" "$1" | python3 -c "
import re, sys
m = re.search(r'<form id=\"drawer-area-form\"[^>]*>\s*<input type=\"hidden\" name=\"_csrf\" value=\"([^\"]+)\"', sys.stdin.read())
print(m.group(1) if m else '')"
}

# ------------------------------------------------------------------ A. contrato

echo "== A. contrato do markup =="
curl -s -b "$JAR" -c "$JAR" "$BASE/admin/areas" -o "$WORK/novo.html"
AREA_ID="$(q "SELECT id FROM areas WHERE deleted_at IS NULL ORDER BY nome LIMIT 1;")"
curl -s -b "$JAR" -c "$JAR" "$BASE/admin/areas?areaId=$AREA_ID" -o "$WORK/edicao.html"

if python3 - "$WORK" <<'PY'
import re, sys, pathlib
work = pathlib.Path(sys.argv[1])
falhas = []
def check(cond, msg):
    if not cond:
        falhas.append(msg)

for estado, arq in (("cadastro", "novo.html"), ("edicao", "edicao.html")):
    h = (work / arq).read_text(encoding="utf-8")
    painel = re.search(r'<aside id="drawer-area".*?</aside>', h, re.S)
    if not painel:
        falhas.append(f"{estado}: <aside> do drawer ausente")
        continue
    d = painel.group(0)

    # topo: titulo + descricao
    check(re.search(r'<h2 id="drawer-area-titulo" class="font-display text-lg font-semibold">[^<]+</h2>', d),
          f"{estado}: titulo ausente ou fora da tipografia")
    check(re.search(r'<p class="text-sm opacity-70">[^<]+</p>', d), f"{estado}: descricao ausente")
    # X no topo direito
    check(re.search(r'<button[^>]*class="btn btn-sm btn-circle btn-ghost[^"]*"[^>]*aria-label="Fechar"[^>]*data-drawer-fechar', d),
          f"{estado}: botao X ausente")
    # painel: containers e semantica
    check(re.search(r'<aside id="drawer-area"\s+class="app-drawer app-drawer--sm app-drawer--end"\s+role="dialog" aria-modal="true" aria-labelledby="drawer-area-titulo"', d),
          f"{estado}: <aside> sem classes/semantica do componente")
    check('class="app-drawer-topo"' in d, f"{estado}: falta .app-drawer-topo")
    check('class="app-drawer-corpo"' in d, f"{estado}: falta .app-drawer-corpo")
    check('class="app-drawer-rodape"' in d, f"{estado}: falta .app-drawer-rodape")
    # slot livre
    check('<label class="field">' in d and 'name="nome"' in d and 'name="status"' in d,
          f"{estado}: slot livre nao renderizou os campos")
    # rodape
    check(re.search(r'<button type="submit" form="drawer-area-form" class="btn btn-primary">', d),
          f"{estado}: botao Salvar ausente ou nao referencia o form")
    check(d.count("data-drawer-fechar") >= 2, f"{estado}: faltam botoes de fechar (X + rodape)")
    # csrf dentro do form do drawer
    check(re.search(r'<form id="drawer-area-form"[^>]*>\s*<input type="hidden" name="_csrf"', d),
          f"{estado}: form do drawer sem _csrf")
    # NAO pode ser <dialog>
    check("<dialog" not in h, f"{estado}: a pagina ainda tem <dialog>")

    # backdrop irmao, fora do painel
    bd = re.search(r'<div id="drawer-area-backdrop" class="app-drawer-backdrop" data-drawer-backdrop="drawer-area"', h)
    check(bd is not None, f"{estado}: backdrop ausente")
    if bd and painel:
        check(bd.start() < painel.start(), f"{estado}: o backdrop deveria vir antes do painel")

    # POSICAO: fora de .page-content, senao o legado espreme o backdrop
    fim_main = h.find("</main>")
    check(fim_main != -1, f"{estado}: </main> nao encontrado")
    if fim_main != -1 and painel:
        check(painel.start() > fim_main,
              f"{estado}: o drawer precisa ser renderizado FORA de .page-content (depois de </main>)")
    if fim_main != -1 and bd:
        check(bd.start() > fim_main,
              f"{estado}: o backdrop precisa ficar FORA de .page-content (depois de </main>)")

    if estado == "cadastro":
        check('data-drawer-aberto' not in d, "cadastro: o drawer nao deveria abrir sozinho")
        check('action="/admin/areas"' in d, "cadastro: action errada")
        check('_method' not in d, "cadastro: _method indevido")
    else:
        check('data-drawer-aberto' in d, "edicao: o drawer deveria abrir sozinho")
        check('action="/admin/areas/' in d, "edicao: action nao aponta para a area")
        check('name="_method" value="patch"' in d, "edicao: falta _method=patch")

if falhas:
    for f in falhas:
        print("  FAIL " + f)
    sys.exit(1)
print("  OK   markup correto nos dois estados, fora de .page-content (topo, slot, rodape, X, backdrop, csrf)")
PY
then :; else fail=1; fi

# ------------------------------------------------------------------ B. escopo

echo "== B. escopo: usado em uma unica tela =="
USOS="$(grep -rl '<ui:drawer' src/main/webapp --include='*.jsp' | sort | tr '\n' ' ')"
ESPERADO="src/main/webapp/WEB-INF/jsp/admin/areas/lista.jsp "
if [ "$USOS" = "$ESPERADO" ]; then
    ok "o componente e usado so em admin/areas/lista.jsp"
else
    bad "uso inesperado: '$USOS' (esperado '$ESPERADO')"
fi
grep -q 'data-drawer' src/main/webapp/WEB-INF/tags/drawer.tag \
    && ok "a definicao vive em WEB-INF/tags/drawer.tag" \
    || bad "drawer.tag nao define os hooks data-drawer"
[ -e src/main/webapp/WEB-INF/tags/modal.tag ] && bad "modal.tag ainda existe" || ok "modal.tag removido"

# ------------------------------------------------------------------ C. fluxo

echo "== C. fluxo criar -> editar -> remover (pelo form do drawer) =="
NOME="Area Drawer Verificacao $$"
NOME_EDITADO="$NOME Editada"

if ! T="$(csrf_do_drawer "$BASE/admin/areas")" || [ -z "$T" ]; then
    bad "nao foi possivel ler o _csrf do form do drawer"
else
    ST="$(curl -s -b "$JAR" -c "$JAR" -X POST "$BASE/admin/areas" \
        --data-urlencode "_csrf=$T" --data-urlencode "nome=$NOME" --data-urlencode "status=Ativo" \
        -o /dev/null -w '%{http_code}')"
    NOVO_ID="$(q "SELECT id FROM areas WHERE nome='$NOME';")"
    if [ "$ST" = "302" ] && [ -n "$NOVO_ID" ]; then
        ok "criar: POST 302 e a area existe no banco"
    else
        bad "criar: status=$ST id='${NOVO_ID:-}'"
    fi

    T="$(csrf_do_drawer "$BASE/admin/areas?areaId=$NOVO_ID")"
    curl -s -b "$JAR" -c "$JAR" "$BASE/admin/areas?areaId=$NOVO_ID" -o "$WORK/editar.html"
    grep -q "value=\"$NOME\"" "$WORK/editar.html" \
        && ok "editar: o drawer ja vem com os valores da area" \
        || bad "editar: valores nao chegaram ao drawer"

    ST="$(curl -s -b "$JAR" -c "$JAR" -X POST "$BASE/admin/areas/$NOVO_ID" \
        --data-urlencode "_csrf=$T" --data-urlencode "_method=patch" \
        --data-urlencode "nome=$NOME_EDITADO" --data-urlencode "status=Inativo" \
        -o /dev/null -w '%{http_code}')"
    ATUAL="$(qv "SELECT nome||'|'||status FROM areas WHERE id='$NOVO_ID';")"
    if [ "$ST" = "302" ] && [ "$ATUAL" = "$NOME_EDITADO|Inativo" ]; then
        ok "editar: PATCH 302 e o banco reflete a mudanca"
    else
        bad "editar: status=$ST banco='$ATUAL'"
    fi

    T="$(csrf_do_drawer "$BASE/admin/areas")"
    ST="$(curl -s -b "$JAR" -c "$JAR" -X POST "$BASE/admin/areas/$NOVO_ID" \
        --data-urlencode "_csrf=$T" --data-urlencode "_method=delete" \
        -o /dev/null -w '%{http_code}')"
    VIVO="$(q "SELECT count(*) FROM areas WHERE id='$NOVO_ID' AND deleted_at IS NULL;")"
    if [ "$ST" = "302" ] && [ "$VIVO" = "0" ]; then
        ok "remover: 302 e a area sai da listagem (soft delete)"
    else
        bad "remover: status=$ST ativo='$VIVO'"
    fi

    # limpeza: nao deixar residuo para as proximas execucoes
    q "DELETE FROM areas WHERE nome LIKE 'Area Drawer Verificacao%';" > /dev/null
    if [ "$(q "SELECT count(*) FROM areas WHERE nome LIKE 'Area Drawer Verificacao%';")" = "0" ]; then
        ok "residuo removido"
    else
        bad "sobrou residuo da verificacao"
    fi
fi

# ------------------------------------------------------------------ D. JS

echo "== D. contrato do JS =="
JS=src/main/resources/static/js/drawer.js
[ -f "$JS" ] && ok "drawer.js existe" || bad "drawer.js ausente"
[ -e src/main/resources/static/js/modal.js ] && bad "modal.js ainda existe" || ok "modal.js removido"
grep -q 'drawer:fechado'          "$JS" && ok "dispara o evento de fechamento" || bad "sem evento de fechamento"
grep -q 'new CustomEvent'         "$JS" && ok "usa CustomEvent" || bad "nao usa CustomEvent"
grep -q 'window.AppDrawer'        "$JS" && ok "expoe window.AppDrawer" || bad "nao expoe AppDrawer"
grep -q 'data-drawer-aberto'      "$JS" && ok "estado por atributo (sem <dialog>)" || bad "sem estado por atributo"
grep -q '"Escape"'                "$JS" && ok "fecha com Esc" || bad "sem tratamento de Esc"
grep -q 'evento.key !== "Tab"'    "$JS" && ok "prende o foco (Tab)" || bad "sem focus trap"
grep -q 'app-drawer-trava-scroll' "$JS" && ok "trava o scroll da pagina" || bad "sem trava de scroll"
grep -q 'js/drawer.js' src/main/webapp/WEB-INF/jsp/fragments/scripts.jspf \
    && ok "carregado por scripts.jspf" || bad "nao e carregado nas paginas"

# Executa de verdade a logica de abrir/fechar/evento/foco num DOM minimo em Node — e a
# unica forma de testar o JS sem navegador. Ver o cabecalho de ui-drawer-js.mjs.
if node scripts/ui-drawer-js.mjs > "$WORK/drawer-js.txt" 2>&1; then
    ok "comportamento do JS: $(grep -c '^  OK' "$WORK/drawer-js.txt") casos executados"
else
    bad "comportamento do JS"
    sed 's/^/       /' "$WORK/drawer-js.txt"
fi

echo
if [ "$fail" = 0 ]; then
    echo "DRAWER OK"
else
    echo "DRAWER COM FALHAS"
fi
exit "$fail"
