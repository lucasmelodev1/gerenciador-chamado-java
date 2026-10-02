#!/usr/bin/env bash
# S30 — Verificacao da agenda de reservas (admin e morador): o detalhe no drawer e o
# cancelamento no dialogo central.
#
# Pre-requisitos:
#   docker compose up -d app
#   bash scripts/ui-seed.sh          (cria baseline/{admin,morador}.jar e a area "Piscina")
#
#   bash scripts/ui-agenda.sh
#
# Exit code: 0 = contrato e fluxo OK, 1 = divergencia.
#
# Cobre cinco camadas:
#   A. markup renderizado das DUAS agendas (o detalhe virou drawer, o painel do fim da
#      pagina sumiu, a lista tem os 7 campos rotulados e o rodape tem Cancelar + Fechar)
#   B. as regras do `custom.css` que fazem a lista ser "rotulo a esquerda, valor em negrito
#      a direita", com self-test negativo
#   C. o `calendar.js` EXECUTADO num DOM minimo em Node (com um FullCalendar de mentira),
#      mais o `drawer.js` (paineis empilhados), com self-test negativo
#   D. fluxo real: uma reserva criada pelo formulario do morador e cancelada pelo MESMO
#      contrato que o dialogo submete (`POST {base}/{id}` + `_method=delete`, `_csrf` lido
#      da propria agenda), e a recusa do servidor depois disso
#   E. fonte: nao sobrou nada do painel antigo e o rodape informativo e do `ui:drawer`
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
BASE="${BASE:-http://localhost:8080}"
DB="${DB:-gerenciador_chamados}"
JAR="${JAR:-baseline/morador.jar}"
WORK="baseline/agenda"
mkdir -p "$WORK"

fail=0
ok()  { printf '  OK   %s\n' "$*"; }
bad() { printf '  FAIL %s\n' "$*"; fail=1; }

q()  { docker exec postgres_condominio psql -U postgres -d "$DB" -tAc "$1" | tr -d '[:space:]'; }
qv() { docker exec postgres_condominio psql -U postgres -d "$DB" -tAc "$1"; }

# Token lido de um formulario ja renderizado (o cookie e mascarado e limpo no login).
csrf_de() { # <jar> <url>
    curl -s -b "$1" -c "$1" "$2" \
        | grep -o 'name="_csrf" value="[^"]*"' | head -n1 | sed 's/.*value="//; s/"$//'
}

# ------------------------------------------------------------------ A. contrato

echo "== A. contrato do markup (as duas agendas) =="
DIR="${HTML_DIR:-$WORK}"
if [ -z "${HTML_DIR:-}" ]; then
    curl -s -b baseline/admin.jar -c baseline/admin.jar "$BASE/admin/reservas/agenda" -o "$WORK/admin-agenda.html"
    curl -s -b "$JAR" -c "$JAR" "$BASE/morador/reservas/agenda" -o "$WORK/morador-agenda.html"
fi

if python3 - "$DIR" <<'PY'
import pathlib, re, sys

DIR = pathlib.Path(sys.argv[1])
# O glifo de bloqueio (circulo cortado) vendorizado em fragments/icone.jspf, e o fallback
# do alias desconhecido — que nao pode aparecer.
BLOQUEIO = '<path d="M12 12m-9 0a9 9 0 1 0 18 0a9 9 0 1 0 -18 0" /><path d="M5.7 5.7l12.6 12.6" />'
FALLBACK = '<circle cx="12" cy="12" r="9" />'

CAMPOS = ["area", "morador", "unidade", "inicio", "fim", "status", "motivo"]
ROTULOS = ["Área", "Morador", "Unidade", "Início", "Fim", "Status", "Motivo"]

AGENDAS = {
    "admin-agenda.html": "/admin/reservas",
    "morador-agenda.html": "/morador/reservas",
}

falhas = []
def bad(arq, msg):
    falhas.append(f"{arq}: {msg}")

for arq, base in AGENDAS.items():
    h = (DIR / arq).read_text(encoding="utf-8")
    fim_main = h.find("</main>")
    if fim_main == -1:
        bad(arq, "sem </main>")
        continue

    # --- nada de JSP pode chegar ao HTML ---
    for marca in ("<%--", "--%>", "<%@", "${"):
        if marca in h:
            bad(arq, f"marcador JSP vazou para o HTML renderizado: {marca!r}")
    if FALLBACK in h:
        bad(arq, "icone de fallback emitido (alias desconhecido em icone.jspf)")

    # --- o calendario continua no lugar ---
    for gancho in ('id="calendar"', 'id="reservas-data"', 'class="reserva-data"', 'id="filtro-area"'):
        if gancho not in h:
            bad(arq, f"o calendario perdeu {gancho!r}")

    # --- o painel antigo do fim da pagina nao pode ter sobrado ---
    # Sempre com o atributo junto: `reserva-titulo` sozinho casaria com o `id` do drawer novo
    # (`drawer-reserva-titulo`), e o verificador reprovaria a propria mudanca.
    for antigo in ('id="reserva-detalhe"', 'class="reserva-titulo"', 'class="reserva-meta"',
                   'class="reserva-motivo"', 'class="reserva-detalhe"',
                   'id="form-aprovar"', 'id="form-negar"', 'id="form-cancelar"',
                   'id="reserva-fechar"', 'data-confirm'):
        if antigo in h:
            bad(arq, f"o painel antigo de detalhe ainda esta na pagina ({antigo!r})")

    # --- o detalhe e um `ui:drawer` INFORMATIVO, depois de </main> ---
    painel = re.search(r'<aside id="drawer-reserva".*?</aside>', h, re.S)
    if not painel:
        bad(arq, "o drawer de detalhe nao foi renderizado")
        continue
    d = painel.group(0)
    if painel.start() < fim_main:
        bad(arq, "o drawer precisa ser renderizado fora de .page-content (depois de </main>)")
    if not re.search(r'<aside id="drawer-reserva"\s+class="app-drawer app-drawer--sm app-drawer--end"\s+'
                     r'role="dialog" aria-modal="true" aria-labelledby="drawer-reserva-titulo"', d):
        bad(arq, "o drawer perdeu as classes/semantica do componente")
    if '<h2 id="drawer-reserva-titulo" data-drawer-titulo' not in d:
        bad(arq, "o drawer perdeu o titulo")
    if 'class="app-drawer-corpo"' not in d:
        bad(arq, "o drawer perdeu o corpo")
    if 'data-drawer-form' in d:
        bad(arq, "este drawer e informativo: nao pode ter formulario")
    if 'data-drawer-aberto' in d:
        bad(arq, "o drawer nao pode vir aberto do servidor")

    # --- a lista de detalhes: 7 linhas, na ordem, com os rotulos acentuados ---
    campos = re.findall(r'<dd class="app-detalhe-valor" data-detalhe="([^"]+)">', d)
    if campos != CAMPOS:
        bad(arq, f"a lista de detalhes deveria ter {CAMPOS}, veio {campos}")
    rotulos = re.findall(r'<dt class="app-detalhe-rotulo">([^<]+)</dt>', d)
    if rotulos != ROTULOS:
        bad(arq, f"os rotulos deveriam ser {ROTULOS}, vieram {rotulos}")

    # --- rodape: Cancelar (vermelho, com icone de bloqueio) + Fechar ---
    rodape = re.search(r'<footer class="app-drawer-rodape">(.*?)</footer>', d, re.S)
    if not rodape:
        bad(arq, "o drawer informativo perdeu o rodape")
    else:
        r = rodape.group(1)
        botoes = re.findall(r'<button[^>]*>', r)
        if len(botoes) != 2:
            bad(arq, f"o rodape deveria ter 2 botoes (Cancelar e Fechar), achou {len(botoes)}")
        if 'class="btn btn-error"' not in r:
            bad(arq, "o botao Cancelar deveria ser vermelho (btn-error)")
        if 'data-drawer-editar="dialog-cancelamento"' not in r:
            bad(arq, "o botao Cancelar deveria abrir o dialogo de cancelamento")
        if 'data-campo-_method="delete"' not in r:
            bad(arq, "o botao Cancelar deveria mandar _method=delete")
        if BLOQUEIO not in r:
            bad(arq, "o botao Cancelar esta sem o icone de bloqueio")
        if re.search(r'>\s*Cancelar\s*<', r) is None:
            bad(arq, "o botao deveria se chamar Cancelar")
        if 'data-drawer-fechar>Fechar</button>' not in r:
            bad(arq, "falta o botao Fechar no rodape")

    # --- o cancelamento e um dialogo CENTRAL, sem campo e sem filete ---
    dialogo = re.search(r'<aside id="dialog-cancelamento".*?</aside>', h, re.S)
    if not dialogo:
        bad(arq, "o dialogo de cancelamento nao foi renderizado")
    else:
        g = dialogo.group(0)
        if dialogo.start() < fim_main:
            bad(arq, "o dialogo precisa ser renderizado fora de .page-content")
        if painel.start() > dialogo.start():
            bad(arq, "o dialogo precisa vir DEPOIS do drawer no DOM (e o que o poe por cima)")
        if not re.search(r'<aside id="dialog-cancelamento"\s+class="app-dialog app-dialog--md"\s+'
                         r'role="dialog" aria-modal="true"', g):
            bad(arq, "o dialogo perdeu as classes/semantica do componente")
        if 'data-drawer-aberto' in g:
            bad(arq, "o dialogo nao pode vir aberto do servidor")
        if 'app-dialog-corpo--vazio' not in g:
            bad(arq, "dialogo sem campos: o corpo deveria sair vazio (sem faixa em branco)")
        if f'action="{base}"' not in g:
            bad(arq, f"o form do dialogo deveria apontar para {base!r} (o gatilho troca pelo id)")
        if re.search(r'<input type="hidden" name="_method" value="">', g) is None:
            bad(arq, "falta o _method vazio para o gatilho de cancelamento preencher")
        if '<input type="hidden" name="_csrf"' not in g:
            bad(arq, "o form do dialogo perdeu o _csrf")
        if re.search(r'<(input(?![^>]*type="hidden")|select|textarea)[^>]*>', g):
            bad(arq, "o dialogo de cancelamento nao tem campo visivel")
        if 'btn-error' not in g:
            bad(arq, "o botao de confirmar deveria ser vermelho")
        if 'Cancelar reserva</button>' not in g:
            bad(arq, "o botao de confirmar deveria se chamar 'Cancelar reserva'")
        if 'data-drawer-fechar>Voltar</button>' not in g:
            bad(arq, "falta o botao esmaecido (Voltar) do dialogo")

if falhas:
    for f in falhas:
        print("  FAIL " + f)
    sys.exit(1)
print("  OK   as duas agendas: detalhe no drawer, lista rotulada, Cancelar + Fechar e dialogo central")
PY
then :; else fail=1; fi

# Self-test negativo: cada sabotagem quebra uma agenda e o verificador tem de reprovar.
if [ -z "${HTML_DIR:-}" ]; then
    if python3 - "$WORK" "$WORK/sab" <<'FIM'
import pathlib, os, shutil, subprocess, sys

WORK, SAB = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])

CASOS = [
    ("admin-agenda.html", 'data-detalhe="status"', 'data-detalhe="situacao"',
     "campo da lista de detalhes renomeado (o JS nao acharia mais)"),
    ("admin-agenda.html", '<dt class="app-detalhe-rotulo">Área</dt>', '<dt class="app-detalhe-rotulo">Area</dt>',
     "rotulo sem acento"),
    ("admin-agenda.html", 'class="btn btn-error"', 'class="btn"',
     "botao Cancelar sem a cor de perigo"),
    ("admin-agenda.html", 'data-drawer-editar="dialog-cancelamento"', 'data-drawer-editar="outro"',
     "Cancelar apontando para outro dialogo"),
    ("admin-agenda.html", 'data-drawer-fechar>Fechar</button>', '</footer>',
     "rodape sem o botao Fechar"),
    ("admin-agenda.html", 'class="app-dialog app-dialog--md"', 'class="app-drawer app-drawer--md"',
     "dialogo de cancelamento renderizado como drawer lateral"),
    ("admin-agenda.html", 'app-dialog-corpo--vazio">',
     'app-dialog-corpo--vazio"><input type="text" name="x">',
     "campo visivel dentro do dialogo de confirmacao"),
    ("morador-agenda.html", 'action="/morador/reservas"', 'action="/admin/reservas"',
     "dialogo do morador apontando para o endpoint do admin"),
    ("morador-agenda.html", 'app-dialog-corpo app-dialog-corpo--vazio', 'app-dialog-corpo',
     "faixa do corpo de volta num dialogo sem campos"),
    ("morador-agenda.html", 'id="reserva-detalhe"', 'id="reserva-detalhe"',
     "sentinela: o painel antigo nao esta mais na pagina"),
]

if SAB.exists():
    shutil.rmtree(SAB)
SAB.mkdir(parents=True)

reprovadas = 0
for arq, antigo, novo, nome in CASOS:
    for origem in WORK.glob("*.html"):
        shutil.copy(origem, SAB / origem.name)
    alvo = SAB / arq
    html = alvo.read_text(encoding="utf-8")

    if nome.startswith("sentinela"):
        # Prova que a checagem do painel antigo nao esta medindo nada: injeta o painel e o
        # verificador TEM de reprovar. Sem isso, um `for antigo in (...)` com nome errado
        # passaria sempre.
        if antigo in html:
            print(f"  FAIL sentinela: {antigo!r} ja esta em {arq}")
            continue
        html = html.replace("</body>", f'<section id="reserva-detalhe"></section></body>', 1)
    else:
        if antigo not in html:
            print("  FAIL sabotagem '" + nome + "' nao alterou " + arq + " (nao mediu nada)")
            continue
        html = html.replace(antigo, novo, 1)
    alvo.write_text(html, encoding="utf-8")

    p = subprocess.run(["bash", "scripts/ui-agenda.sh"], capture_output=True, text=True,
                       env=dict(os.environ, HTML_DIR=str(SAB)))
    if p.returncode == 0:
        print("  FAIL sabotagem '" + nome + "' passou — o verificador nao detecta essa quebra")
    elif ("FAIL " + arq + ":") not in p.stdout:
        print("  FAIL sabotagem '" + nome + "' reprovou por outro motivo, nao por " + arq)
    else:
        reprovadas += 1

if reprovadas != len(CASOS):
    raise SystemExit(1)
print("  OK   self-test negativo do markup: " + str(reprovadas) + "/" + str(len(CASOS)) + " sabotagens reprovadas")
FIM
    then :; else fail=1; fi
fi

# ------------------------------------------------------------------ B. CSS

echo "== B. contrato do CSS =="
if python3 - <<'PY'
import os, pathlib, re

def bloco(css, seletor):
    """Corpo da regra cujo seletor bate exatamente (comentarios fora)."""
    sem_comentarios = re.sub(r'/\*.*?\*/', '', css, flags=re.S)
    for m in re.finditer(r'([^{}]*)\{([^{}]*)\}', sem_comentarios):
        if m.group(1).strip() == seletor:
            return m.group(2)
    return None

def verificar(custom):
    problemas = []
    def check(cond, msg):
        if not cond:
            problemas.append(msg)

    lista = bloco(custom, ".app-detalhe-lista")
    if lista is None:
        problemas.append("custom.css sem a regra .app-detalhe-lista")
    else:
        check(re.search(r'display\s*:\s*grid', lista) is not None,
              ".app-detalhe-lista deveria ser um grid (as linhas espacadas)")
        check(re.search(r'margin\s*:\s*0', lista) is not None,
              ".app-detalhe-lista deveria zerar o margin do <dl>")

    linha = bloco(custom, ".app-detalhe-linha")
    if linha is None:
        problemas.append("custom.css sem a regra .app-detalhe-linha")
    else:
        check(re.search(r'display\s*:\s*flex', linha) is not None,
              ".app-detalhe-linha deveria ser flex (rotulo e valor na mesma linha)")
        check(re.search(r'justify-content\s*:\s*space-between', linha) is not None,
              ".app-detalhe-linha deveria empurrar o valor para a direita (space-between)")

    rotulo = bloco(custom, ".app-detalhe-rotulo")
    if rotulo is None:
        problemas.append("custom.css sem a regra .app-detalhe-rotulo")
    else:
        check(re.search(r'flex-shrink\s*:\s*0', rotulo) is not None,
              ".app-detalhe-rotulo nao pode encolher (o rotulo e o lado fixo da linha)")

    valor = bloco(custom, ".app-detalhe-valor")
    if valor is None:
        problemas.append("custom.css sem a regra .app-detalhe-valor")
    else:
        check(re.search(r'font-weight\s*:\s*(700|bold)', valor) is not None,
              "o valor da lista de detalhes deveria ser negrito")
        check(re.search(r'text-align\s*:\s*end', valor) is not None,
              "o valor deveria alinhar pela direita (text-align: end)")
        check(re.search(r'margin\s*:\s*0', valor) is not None,
              "falta zerar o recuo padrao do <dd>")
        check(re.search(r'min-width\s*:\s*0', valor) is not None,
              "sem min-width: 0 um valor longo estoura o painel")

    rodape = bloco(custom, ".app-drawer-rodape")
    check(rodape is not None and re.search(r'justify-content\s*:\s*flex-end', rodape or "") is not None,
          ".app-drawer-rodape deveria alinhar os botoes pela direita")
    return problemas

custom = pathlib.Path(os.environ.get("CUSTOM_CSS", "src/main/resources/static/css/custom.css")).read_text(encoding="utf-8")

problemas = verificar(custom)
if problemas:
    for p in problemas:
        print("  FAIL " + p)
    raise SystemExit(1)
print("  OK   lista de detalhes: rotulo a esquerda, valor em negrito a direita")

SABOTAGENS = [
    ("lista de detalhes removida",
     lambda c: re.sub(r'\.app-detalhe-lista \{[^}]*\}', '', c, count=1)),
    ("linha deixa de ser flex",
     lambda c: c.replace("    display: flex;\n    align-items: baseline;\n    justify-content: space-between;",
                         "    display: block;\n    align-items: baseline;\n    justify-content: space-between;", 1)),
    ("valor deixa de ir para a direita",
     lambda c: re.sub(r'(\.app-detalhe-linha \{[^}]*justify-content:\s*)space-between',
                      r'\1flex-start', c, count=1)),
    ("valor perde o negrito",
     lambda c: c.replace("    font-weight: 700;\n    text-align: end;", "    text-align: end;", 1)),
    ("valor perde o alinhamento a direita",
     lambda c: c.replace("    font-weight: 700;\n    text-align: end;", "    font-weight: 700;", 1)),
    ("recuo padrao do <dd> de volta",
     lambda c: c.replace("    min-width: 0;\n    margin: 0;", "    min-width: 0;", 1)),
    ("rotulo pode encolher",
     lambda c: re.sub(r'\.app-detalhe-rotulo \{[^}]*\}', '', c, count=1)),
    ("min-width do valor removido",
     lambda c: c.replace("    min-width: 0;\n    margin: 0;", "    margin: 0;", 1)),
]
passou = 0
for nome, sabotar in SABOTAGENS:
    alterado = sabotar(custom)
    if alterado == custom:
        print(f"  FAIL sabotagem '{nome}' nao alterou o CSS (o self-test nao mediu nada)")
        continue
    if verificar(alterado):
        passou += 1
    else:
        print(f"  FAIL sabotagem '{nome}' passou — o verificador nao detecta essa quebra")
if passou != len(SABOTAGENS):
    raise SystemExit(1)
print(f"  OK   self-test negativo: {passou}/{len(SABOTAGENS)} sabotagens reprovadas")
PY
then :; else fail=1; fi

# ------------------------------------------------------------------ C. JS

echo "== C. comportamento do JS =="
if node scripts/ui-calendar-js.mjs > "$WORK/calendar-js.txt" 2>&1; then
    ok "calendar.js: $(grep -c '^  OK' "$WORK/calendar-js.txt") casos executados (evento, detalhe, Cancelar e filtro local)"
else
    bad "comportamento do calendar.js"
    sed 's/^/       /' "$WORK/calendar-js.txt"
fi
if node scripts/ui-drawer-js.mjs > "$WORK/drawer-js.txt" 2>&1; then
    ok "drawer.js: $(grep -c '^  OK' "$WORK/drawer-js.txt") casos executados (inclui os paineis empilhados)"
else
    bad "comportamento do drawer.js"
    sed 's/^/       /' "$WORK/drawer-js.txt"
fi

# O harness so vale se falhar quando o cenario quebra.
SABH="baseline/agenda/sabotagem.mjs"
# Separador `@@`: uma das expressoes tem `||` no meio, e `|` como separador a truncaria.
sabotagens=(
    's/"data-drawer-editar": "dialog-cancelamento"/"data-drawer-editar": "outro-painel"/@@gatilho de cancelar apontando para outro painel'
    's/"data-detalhe": campo/"data-detalhe": "outro"/@@lista de detalhes sem o gancho data-detalhe'
    's/"data-status": dados.status || "Solicitado"/"data-status": "Aprovado"/@@status fixo no cenario'
    's/^\( *\)ambiente\.document\._disparar("DOMContentLoaded".*$/\1;/@@calendar.js nao inicializado'
)
n_sab=0
for entrada in "${sabotagens[@]}"; do
    cp scripts/ui-calendar-js.mjs "$SABH"
    sed -i "${entrada%%@@*}" "$SABH"
    if node "$SABH" > /dev/null 2>&1; then
        bad "o harness passou numa sabotagem (${entrada##*@@}) — teste nao esta medindo"
    else
        n_sab=$((n_sab + 1))
    fi
    rm -f "$SABH"
done
[ "$n_sab" = "${#sabotagens[@]}" ] \
    && ok "self-test negativo do calendar.js: $n_sab/${#sabotagens[@]} sabotagens reprovadas" \
    || bad "self-test negativo incompleto: $n_sab/${#sabotagens[@]}"

# ------------------------------------------------------------------ D. fluxo

# Fora do self-test negativo (`HTML_DIR`): as secoes D e E nao dependem do HTML gravado, e
# repeti-las a cada sabotagem criaria dez reservas para cancelar na mesma execucao.
if [ -z "${HTML_DIR:-}" ]; then

echo "== D. fluxo real: cancelar pela agenda =="
AREA_ID="$(q "select id from areas where nome = 'Piscina'")"
MORADOR_ID="$(q "select id from usuarios where email = 'morador@condominio.local'")"
UNIDADE_ID="$(q "select u.id from unidades u join blocos b on b.id = u.bloco_id where b.identificacao = 'Bloco A' order by u.identificacao limit 1")"
INICIO="$(date -d '+10 days 09:00' +%Y-%m-%dT09:00)"
FIM="$(date -d '+10 days 11:00' +%Y-%m-%dT11:00)"

if [ -z "$AREA_ID" ] || [ -z "$MORADOR_ID" ] || [ -z "$UNIDADE_ID" ]; then
    bad "fixture incompleta (area/morador/unidade) — rode scripts/ui-seed.sh"
else
    T="$(csrf_de "$JAR" "$BASE/morador/reservas/nova")"
    if [ -z "$T" ]; then
        bad "nao foi possivel ler o _csrf do formulario de reserva"
    else
        ST="$(curl -s -b "$JAR" -c "$JAR" -X POST "$BASE/morador/reservas" \
            --data-urlencode "_csrf=$T" --data-urlencode "areaId=$AREA_ID" \
            --data-urlencode "unidadeId=$UNIDADE_ID" \
            --data-urlencode "inicio=$INICIO" --data-urlencode "fim=$FIM" \
            -o /dev/null -w '%{http_code}')"
        NOVA_ID="$(q "select id from solicitacoes_area where morador_id = '$MORADOR_ID' and inicio = '$INICIO' and deleted_at is null")"
        if [ "$ST" = "302" ] && [ -n "$NOVA_ID" ]; then
            ok "reserva criada pelo formulario do morador (302) e existe no banco"
        else
            bad "criar reserva: status=$ST id='${NOVA_ID:-}'"
        fi

        if [ -n "$NOVA_ID" ]; then
            # O `_csrf` sai da PROPRIA agenda: e o token que o form do dialogo carrega.
            T2="$(csrf_de "$JAR" "$BASE/morador/reservas/agenda")"
            if [ -z "$T2" ]; then
                bad "nao foi possivel ler o _csrf do form do dialogo na agenda"
            fi
            ST="$(curl -s -b "$JAR" -c "$JAR" -X POST "$BASE/morador/reservas/$NOVA_ID" \
                -H "Referer: $BASE/morador/reservas/agenda" \
                --data-urlencode "_csrf=$T2" --data-urlencode "_method=delete" \
                -o /dev/null -w '%{http_code}')"
            STATUS="$(q "select status from solicitacoes_area where id = '$NOVA_ID'")"
            if [ "$ST" = "302" ] && [ "$STATUS" = "Cancelado" ]; then
                ok "cancelar: o contrato do dialogo (POST {base}/{id} + _method=delete) cancela de verdade"
            else
                bad "cancelar: status=$ST banco='${STATUS:-}'"
            fi

            # O servidor recusa cancelar de novo — e a regra que o `calendar.js` espelha
            # escondendo o botao para status que nao sejam Solicitado/Aprovado.
            ST="$(curl -s -b "$JAR" -c "$JAR" -X POST "$BASE/morador/reservas/$NOVA_ID" \
                -H "Referer: $BASE/morador/reservas/agenda" \
                --data-urlencode "_csrf=$T2" --data-urlencode "_method=delete" \
                -o /dev/null -w '%{http_code}')"
            curl -s -b "$JAR" -c "$JAR" "$BASE/morador/reservas/agenda" -o "$WORK/agenda-recusa.html"
            if grep -q "Somente reservas solicitadas ou aprovadas podem ser canceladas" "$WORK/agenda-recusa.html"; then
                ok "cancelar de novo e recusado com aviso na propria agenda (302 + flash)"
            else
                bad "o servidor nao avisou a recusa do segundo cancelamento (status=$ST)"
            fi

            # O alerta de flash traz o `×` do alerts.jspf: aqui se prova, no HTML servido, que
            # o fragmento nao esta sendo lido como ISO-8859-1 (o "Ã" que aparecia antes).
            if grep -q 'data-dismiss-alert aria-label="Fechar">×</button>' "$WORK/agenda-recusa.html"; then
                ok "o × do alerta sai em UTF-8 (fragmento incluido nao esta em ISO-8859-1)"
            else
                bad "o × do alerta saiu corrompido — fragmento lido como ISO-8859-1?"
            fi

            # limpeza: nao deixar residuo para as proximas execucoes
            q "DELETE FROM solicitacoes_area WHERE id = '$NOVA_ID';" > /dev/null
            if [ "$(q "select count(*) from solicitacoes_area where id = '$NOVA_ID'")" = "0" ]; then
                ok "residuo removido"
            else
                bad "sobrou residuo da verificacao"
            fi
        fi
    fi
fi

# ------------------------------------------------------------------ E. fonte

echo "== E. fonte =="
# O painel antigo nao pode existir em NENHUM arquivo de markup (o HTML de A so cobre as duas
# agendas; um fragmento reaproveitado em outra tela passaria despercebido).
if grep -rqE 'id="reserva-detalhe"|reserva-titulo|id="form-cancelar"' src/main/webapp --include='*.jsp' --include='*.jspf' --include='*.tag'; then
    bad "ainda ha markup do painel antigo de detalhe"
    grep -rnE 'id="reserva-detalhe"|reserva-titulo|id="form-cancelar"' src/main/webapp --include='*.jsp' --include='*.jspf' --include='*.tag' | sed 's/^/       /'
else
    ok "nenhum markup do painel antigo de detalhe"
fi
# O rodape informativo e do componente, nao da tela: a tela so declara o rotulo e a acao.
grep -q 'data-drawer-fechar>${drawerFechar}</button>' src/main/webapp/WEB-INF/tags/drawer.tag \
    && ok "o rodape do drawer informativo vive em tags/drawer.tag" \
    || bad "drawer.tag nao renderiza o botao Fechar do drawer informativo"
grep -q 'data-drawer-editar="${painelAcao}"' src/main/webapp/WEB-INF/tags/drawer.tag \
    && ok "o botao da acao usa o protocolo data-drawer-editar do gatilho" \
    || bad "drawer.tag nao liga painelAcao ao data-drawer-editar"
grep -q 'app-detalhe-valor' src/main/webapp/WEB-INF/tags/detalhe-linha.tag \
    && ok "a linha de detalhe vive em tags/detalhe-linha.tag" \
    || bad "tags/detalhe-linha.tag nao renderiza a linha de detalhe"
# O CSV/encoding: as duas agendas incluem os paineis FORA de .page-content.
for pagina in src/main/webapp/WEB-INF/jsp/admin/reservas/agenda.jsp src/main/webapp/WEB-INF/jsp/morador/reservas/agenda.jsp; do
    grep -q 'fragments/reservas-agenda-paineis.jspf' "$pagina" \
        && ok "$(basename "$(dirname "$pagina")")/$(basename "$pagina") inclui os paineis" \
        || bad "$pagina nao inclui reservas-agenda-paineis.jspf"
done

fi   # fim do bloco que so roda na execucao de verdade

echo
if [ "$fail" = 0 ]; then
    echo "AGENDA OK"
else
    echo "AGENDA COM FALHAS"
fi
exit "$fail"
