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
#   A. contrato do markup renderizado (e a posicao fora de .page-content)
#   B. escopo — o componente e usado em UMA tela, como pedido
#   C. fluxo real criar -> editar -> remover, incluindo o DEPOIS de salvar
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
curl -s -b "$JAR" -c "$JAR" "$BASE/admin/areas" -o "$WORK/lista.html"
# `LISTA_HTML` permite apontar a checagem para um HTML ja gravado (usado no self-test
# negativo do proprio verificador, que roda fora do container).
LISTA="${LISTA_HTML:-$WORK/lista.html}"

if python3 - "$LISTA" <<'PY'
import re, sys, pathlib
h = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
falhas = []
def check(cond, msg):
    if not cond:
        falhas.append(msg)

check("<dialog" not in h, "a pagina tem <dialog> (o componente nao deve ser um dialog)")

painel = re.search(r'<aside id="drawer-area".*?</aside>', h, re.S)
if not painel:
    print("  FAIL <aside> do drawer ausente")
    sys.exit(1)
d = painel.group(0)

# topo: titulo + descricao + X
check(re.search(r'<h2 id="drawer-area-titulo" data-drawer-titulo class="font-display text-lg font-semibold">Nova area</h2>', d),
      "titulo ausente ou fora da tipografia")
check(re.search(r'<p class="text-sm opacity-70">[^<]+</p>', d), "descricao ausente")
check(re.search(r'<button[^>]*class="btn btn-sm btn-circle btn-ghost[^"]*"[^>]*aria-label="Fechar"[^>]*data-drawer-fechar', d),
      "botao X ausente")
check(re.search(r'<aside id="drawer-area"\s+class="app-drawer app-drawer--sm app-drawer--end"\s+role="dialog" aria-modal="true" aria-labelledby="drawer-area-titulo"', d),
      "<aside> sem classes/semantica do componente")
check('class="app-drawer-topo"' in d, "falta .app-drawer-topo")
check('class="app-drawer-corpo"' in d, "falta .app-drawer-corpo")
check('class="app-drawer-rodape"' in d, "falta .app-drawer-rodape")

# slot livre
check('<label class="field">' in d and 'name="nome"' in d and 'name="status"' in d, "slot livre nao renderizou os campos")

# rodape: SO o botao Salvar, com icone
rodape = re.search(r'<footer class="app-drawer-rodape">(.*?)</footer>', d, re.S)
if not rodape:
    falhas.append("rodape ausente")
else:
    r = rodape.group(1)
    botoes = re.findall(r'<button[^>]*>', r)
    check(len(botoes) == 1, f"o rodape deveria ter 1 botao (Salvar), achou {len(botoes)}")
    check('class="btn btn-primary"' in r, "o botao do rodape nao e o primario")
    check(re.search(r'Salvar', r) is not None, "o botao do rodape nao se chama Salvar")
    check('<svg' in r, "o botao Salvar esta sem icone")
    check('data-drawer-fechar' not in r, "o rodape ainda tem botao de Fechar")
    check('Fechar' not in r, "o rodape ainda mostra o rotulo Fechar")

# _method dentro do form, pronto para o gatilho de edicao preencher
check(re.search(r'<form id="drawer-area-form"[^>]*data-drawer-form[^>]*action="/admin/areas"[^>]*class="app-drawer-corpo"', d),
      "form do drawer sem id/data-hook/action de criacao")
check(re.search(r'<form id="drawer-area-form"[^>]*>\s*<input type="hidden" name="_csrf"', d), "form do drawer sem _csrf")
check(re.search(r'<input type="hidden" name="_method" value="">', d), "falta o _method vazio para o modo edicao")

# NAO pode vir aberto: era isso que deixava o drawer aberto depois de salvar
check('data-drawer-aberto' not in d, "o drawer nao deveria vir aberto do servidor")

# gatilhos
check('<button type="button" class="btn btn-primary btn-sm" data-drawer-abrir="drawer-area">' in h,
      "faltou o gatilho 'Nova area' (data-drawer-abrir)")
# S25: o gatilho de editar virou botao so com icone + tooltip, entao a checagem e por
# atributo (nao pela classe antiga `btn btn-link`) e o texto sai de cena.
editar = re.search(r'<button[^>]*data-drawer-editar="drawer-area".*?</button>', h, re.S)
if not editar:
    falhas.append("faltou o gatilho 'Editar' (data-drawer-editar)")
else:
    e = editar.group(0)
    # S26: os campos do gatilho viraram inputs escondidos dentro do botao, entao a
    # checagem e por `data-campo="<nome>"` (nao mais `data-campo-<nome>`).
    for atributo in ('data-drawer-titulo="Editar area"', 'data-drawer-acao="/admin/areas/',
                     'data-campo="_method" value="patch"', 'data-campo="nome"', 'data-campo="status"'):
        check(atributo in e, f"gatilho Editar sem {atributo}")
    check('class="btn btn-ghost btn-sm btn-square tooltip"' in e,
          "gatilho Editar sem as classes do botao de icone")
    check('data-tip="Editar"' in e, "gatilho Editar sem tooltip (data-tip)")
    check('aria-label="Editar"' in e, "gatilho Editar sem rotulo acessivel")
    check('<svg' in e, "gatilho Editar sem icone")
    check('>Editar</button>' not in e, "o gatilho Editar ainda mostra o texto")

# backdrop irmao, e os dois FORA de .page-content
bd = re.search(r'<div id="drawer-area-backdrop" class="app-drawer-backdrop" data-drawer-backdrop="drawer-area"', h)
check(bd is not None, "backdrop ausente")
fim_main = h.find("</main>")
check(fim_main != -1, "</main> nao encontrado")
if fim_main != -1:
    if bd:
        check(bd.start() > fim_main, "o backdrop precisa ficar FORA de .page-content (depois de </main>)")
    check(painel.start() > fim_main, "o drawer precisa ser renderizado FORA de .page-content (depois de </main>)")

if falhas:
    for f in falhas:
        print("  FAIL " + f)
    sys.exit(1)
print("  OK   markup correto: rodape so com Salvar (com icone), sem Fechar, nunca aberto no HTML")
PY
then :; else fail=1; fi

# ------------------------------------------------------------------ B. escopo

echo "== B. escopo: as telas de cadastro com tabela =="
# S23 exigia UMA tela; a S26 espalhou o componente pelas telas de tabela com criacao e
# edicao (a S27 somou tipos-chamado). Chamados do admin fica de fora: e so leitura. A lista abaixo e fechada de
# proposito — um `ui:drawer` numa tela nova tem de ser uma decisao, nao um efeito colateral.
USOS="$(grep -rl '<ui:drawer' src/main/webapp --include='*.jsp' | sort | tr '\n' ' ')"
ESPERADO="src/main/webapp/WEB-INF/jsp/admin/areas/lista.jsp src/main/webapp/WEB-INF/jsp/admin/blocos/lista.jsp src/main/webapp/WEB-INF/jsp/admin/status-chamado/lista.jsp src/main/webapp/WEB-INF/jsp/admin/tipos-chamado/lista.jsp src/main/webapp/WEB-INF/jsp/admin/usuarios/lista.jsp "
if [ "$USOS" = "$ESPERADO" ]; then
    ok "o componente e usado nas 5 telas de cadastro com tabela"
else
    bad "uso inesperado: '$USOS' (esperado '$ESPERADO')"
fi
grep -q 'data-drawer' src/main/webapp/WEB-INF/tags/drawer.tag \
    && ok "a definicao vive em WEB-INF/tags/drawer.tag" \
    || bad "drawer.tag nao define os hooks data-drawer"
[ -e src/main/webapp/WEB-INF/tags/modal.tag ] && bad "modal.tag ainda existe" || ok "modal.tag removido"
# A tela nao pode mais depender do estado de edicao vindo do servidor (era o `?areaId=`).
# O grep olha o USO (`areaEdicao`/`areaForm`), nao a palavra no comentario explicativo.
grep -qE 'areaEdicao|areaForm' src/main/webapp/WEB-INF/jsp/admin/areas/lista.jsp \
    && bad "a tela de areas ainda usa o estado de edicao do servidor" \
    || ok "a tela nao depende mais do estado de edicao via ?areaId (sem reload para abrir)"

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

    T="$(csrf_do_drawer "$BASE/admin/areas")"
    ST="$(curl -s -b "$JAR" -c "$JAR" -X POST "$BASE/admin/areas/$NOVO_ID" \
        --data-urlencode "_csrf=$T" --data-urlencode "_method=patch" \
        --data-urlencode "nome=$NOME_EDITADO" --data-urlencode "status=Inativo" \
        -D "$WORK/patch-head.txt" -o /dev/null -w '%{http_code}')"
    ATUAL="$(qv "SELECT nome||'|'||status FROM areas WHERE id='$NOVO_ID';")"
    if [ "$ST" = "302" ] && [ "$ATUAL" = "$NOME_EDITADO|Inativo" ]; then
        ok "editar: PATCH 302 e o banco reflete a mudanca"
    else
        bad "editar: status=$ST banco='$ATUAL'"
    fi

    # DEPOIS de salvar: a pagina para onde o servidor manda nao pode vir com o drawer
    # aberto. Era exatamente esse o bug relatado ("salvo e o drawer nao fecha").
    DESTINO="$(grep -i '^location:' "$WORK/patch-head.txt" | tr -d '\r' | sed 's/^[Ll]ocation: *//')"
    if [ -n "$DESTINO" ]; then
        curl -s -b "$JAR" -c "$JAR" "$DESTINO" -o "$WORK/pos-save.html"
        if grep -q 'data-drawer-aberto' "$WORK/pos-save.html"; then
            bad "depois de salvar o drawer volta aberto ($DESTINO)"
        else
            ok "depois de salvar a pagina vem com o drawer fechado ($DESTINO)"
        fi
    else
        bad "o PATCH nao devolveu Location"
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
grep -q 'data-drawer-editar'      "$JS" && ok "suporta conteudo dinamico (editar)" || bad "sem gatilho de editar"
grep -q 'form.reset()'            "$JS" && ok "devolve o form ao modo de criacao" || bad "sem reset do formulario"
grep -q 'data-campo="'            "$JS" && ok "le os campos declarados como input escondido" || bad "sem leitura dos campos do gatilho"
grep -q 'data-drawer-travar'      "$JS" && ok "trava os campos que a edicao nao muda" || bad "sem suporte a campo travado"
grep -q 'js/drawer.js' src/main/webapp/WEB-INF/jsp/fragments/scripts.jspf \
    && ok "carregado por scripts.jspf" || bad "nao e carregado nas paginas"

# Executa de verdade a logica de abrir/fechar/evento/foco/conteudo num DOM minimo em
# Node — e a unica forma de testar o JS sem navegador. Ver ui-drawer-js.mjs.
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
