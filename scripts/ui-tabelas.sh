#!/usr/bin/env bash
# S26/S27 — Verificacao das telas de tabela do admin: areas, blocos, chamados,
# status-chamado, tipos-chamado e usuarios.
#
# Pre-requisitos:
#   docker compose up -d app
#   bash scripts/ui-seed.sh          (cria baseline/admin.jar)
#
#   bash scripts/ui-tabelas.sh
#
# Exit code: 0 = contrato OK, 1 = divergencia.
#
# Substitui o antigo `ui-tabelas.sh`: o contrato deixou de ser "da tela de areas" e
# passou a ser o das telas de tabela, que compartilham os tags `ui:card-head`,
# `ui:busca`, `ui:badge`, `ui:acao-link`, `ui:acao-editar` e `ui:acao-form`.
#
# Cobre quatro camadas:
#   A. markup renderizado pelo servidor das 5 telas (contrato comum + o que e de cada uma)
#   B. CSS — as regras do padrao e as classes do bundle que ele pressupoe
#   C. comportamento do JS (drawer.js e tables.js EXECUTADOS num DOM minimo em Node)
#   D. o filtro local continua local: nao existe requery no servidor
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
BASE="${BASE:-http://localhost:8080}"
JAR="${JAR:-baseline/admin.jar}"
WORK="baseline/tabelas"
mkdir -p "$WORK"

fail=0
ok()  { printf '  OK   %s\n' "$*"; }
bad() { printf '  FAIL %s\n' "$*"; fail=1; }

echo "== A. contrato do markup (telas de tabela) =="
# `HTML_DIR` aponta a checagem para um diretorio ja gravado (usado no self-test negativo
# do proprio verificador, que roda fora do container). Sem ela, busca as telas no ar.
DIR="${HTML_DIR:-$WORK}"
if [ -z "${HTML_DIR:-}" ]; then
    for rota in reservas areas blocos usuarios status-chamado tipos-chamado chamados; do
        curl -s -b "$JAR" -c "$JAR" "$BASE/admin/$rota" -o "$WORK/$rota.html"
    done
fi

if python3 - "$DIR" <<'PY'
import re, sys, pathlib

DIR = pathlib.Path(sys.argv[1])
# A lupa Tabler `search` 3.31.0, o lapis, a lixeira, o olho e a estrela (o conjunto
# vendorizado em fragments/icone.jspf), usados para provar que o alias resolveu.
OLHO = '<path d="M10 10m-7 0a7 7 0 1 0 14 0a7 7 0 1 0 -14 0" /><path d="M21 21l-6 -6" />'
FALLBACK = '<circle cx="12" cy="12" r="9" />'

# tela -> (alvo do filtro local | None, id do drawer | None, conjunto de acoes esperado)
TELAS = {
    "reservas":       {"alvo": None,             "drawer": None,             "busca": False, "filtros": False},
    "areas":          {"alvo": "areas-table",    "drawer": "drawer-area",    "busca": True},
    "blocos":         {"alvo": "blocos-table",   "drawer": "drawer-bloco",   "busca": True},
    "usuarios":       {"alvo": "usuarios-table", "drawer": "drawer-usuario", "busca": True},
    "status-chamado": {"alvo": "status-table",   "drawer": "drawer-status",  "busca": True},
    "tipos-chamado":  {"alvo": "tipos-table",    "drawer": "drawer-tipo",    "busca": True},
    "chamados":       {"alvo": None,             "drawer": None,             "busca": False},
}

falhas = []
def bad(tela, msg):
    falhas.append(f"{tela}: {msg}")

html = {}
for tela in TELAS:
    html[tela] = (DIR / f"{tela}.html").read_text(encoding="utf-8")

# ---------------------------------------------------------------- contrato comum

for tela, cfg in TELAS.items():
    h = html[tela]

    # --- cabecalho + faixa de filtros, na ordem ---
    i_head = h.find('<div class="app-card-head">')
    i_filt = h.find('class="app-card-filtros')
    if i_head == -1:
        bad(tela, "sem .app-card-head (ui:card-head)")
    if cfg.get("filtros", True):
        if i_filt == -1:
            bad(tela, "sem faixa de filtros (.app-card-filtros)")
        if i_head != -1 and i_filt != -1 and i_filt < i_head:
            bad(tela, "a faixa de filtros tem de vir depois do cabecalho")
    if i_head != -1:
        fim_head = i_filt if i_filt != -1 else h.find('<div class="overflow-x-auto"')
        head = h[i_head:fim_head]
        if not re.search(r'<div class="app-card-head__texto">\s*(<p class="eyebrow">[^<]*</p>\s*)?<h2>[^<]+</h2>', head):
            bad(tela, "cabecalho sem descricao/.eyebrow e <h2> no agrupamento")
        if head.count('<div class="app-card-head__texto">') != 1:
            bad(tela, "mais de um agrupamento de titulo no cabecalho")

    # --- nada de JSP pode chegar ao HTML ---
    # Um comentario JSP DENTRO de outro termina no primeiro fechamento e o resto do
    # texto vira conteudo da pagina: foi assim que o comentario do `ui:badge` saiu
    # impresso dentro do badge na primeira versao da S26. Marcador de diretiva e
    # expressao nao resolvida entram na mesma checagem.
    for marca in ("<%--", "--%>", "<%@", "${"):
        if marca in h:
            bad(tela, f"marcador JSP vazou para o HTML renderizado: {marca!r}")

    # --- a composicao legada saiu de todas ---
    if 'class="section-header"' in h:
        bad(tela, "ainda usa .section-header")
    if 'class="toolbar-inline"' in h:
        bad(tela, "ainda usa .toolbar-inline")
    if FALLBACK in h:
        bad(tela, "icone de fallback emitido (alias desconhecido em icone.jspf)")

    # --- coluna de acoes: rotulo acessivel, todas as linhas migradas ---
    if '<th><span class="sr-only">Acoes</span></th>' not in h:
        bad(tela, "coluna de acoes sem <span class=\"sr-only\">Acoes</span> no <th>")
    acoes = h.count('<td class="cell-actions app-tabela-acoes">')
    todas = len(re.findall(r'<td class="cell-actions[^"]*">', h))
    if acoes == 0:
        bad(tela, "nenhuma celula de acoes com .app-tabela-acoes")
    if todas != acoes:
        bad(tela, f"{todas} celulas .cell-actions, mas so {acoes} com .app-tabela-acoes")
    if 'cell-actions' in h and acoes != todas:
        bad(tela, "sobrou celula de acoes sem o alinhamento a direita")

    # --- todo botao de acao e icone + tooltip ---
    for botao in re.findall(r'<button[^>]*class="[^"]*app-btn[^"]*"[^>]*>', h) + \
                 re.findall(r'<button[^>]*class="btn btn-ghost btn-sm btn-square[^"]*"[^>]*>', h):
        if 'tooltip' not in botao or 'data-tip=' not in botao or 'aria-label=' not in botao:
            bad(tela, f"botao de acao sem tooltip/aria-label: {botao[:70]}...")
    for botao in re.findall(r'<a [^>]*class="btn btn-ghost[^"]*"[^>]*>', h):
        if 'data-tip=' not in botao or 'aria-label=' not in botao:
            bad(tela, f"acao de link sem tooltip/aria-label: {botao[:70]}...")

    # --- busca local: um campo, com a lupa dentro da moldura, ligado a tabela ---
    if cfg["busca"]:
        if h.count('data-filter-input') != 1:
            bad(tela, f"deveria haver exatamente 1 campo de busca local, ha {h.count('data-filter-input')}")
        if f'data-filter-target="{cfg["alvo"]}"' not in h:
            bad(tela, f"a busca nao aponta para {cfg['alvo']!r}")
        if h.count(f'data-filter-table="{cfg["alvo"]}"') != 1:
            bad(tela, f"a tabela nao tem data-filter-table={cfg['alvo']!r}")
        if '<label class="input input-sm">' not in h:
            bad(tela, "a busca nao e um `label.input` da daisyUI")
        if OLHO not in h:
            bad(tela, "falta o icone de lupa na busca")
        else:
            i_lupa, i_campo = h.find(OLHO), h.find('<input type="search"')
            if i_campo != -1 and i_lupa > i_campo:
                bad(tela, "a lupa tem de vir ANTES do campo (fica a esquerda)")
    else:
        if 'data-filter-input' in h:
            bad(tela, "nao deveria ter busca local (os filtros desta tela vao ao servidor)")

    # --- drawer: gatilho no cabecalho e painel FORA de .page-content ---
    if cfg["drawer"]:
        if f'data-drawer-abrir="{cfg["drawer"]}"' not in h:
            bad(tela, f"faltou o gatilho data-drawer-abrir={cfg['drawer']!r}")
        painel = re.search(r'<aside id="' + cfg["drawer"] + r'"[^>]*data-drawer[^>]*>', h)
        if not painel:
            bad(tela, f"painel {cfg['drawer']!r} ausente")
        fim_main = h.find("</main>")
        if painel and fim_main != -1 and painel.start() < fim_main:
            bad(tela, "o drawer precisa ser renderizado fora de .page-content (depois de </main>)")
        if 'data-drawer-aberto' in h:
            bad(tela, "o drawer nao pode vir aberto do servidor")

# ---------------------------------------------------------------- o que e de cada tela

# reservas: tres acoes de decisao (aprovar / negar / cancelar) e dois dialogos centrais
h = html["reservas"]
fim_main = h.find("</main>")
for dlg in ("dialog-negacao", "dialog-cancelamento"):
    painel = re.search(r'<aside id="' + dlg + r'"[^>]*class="app-dialog[^"]*"[^>]*data-drawer', h)
    if not painel:
        bad("reservas", f"dialogo {dlg!r} ausente, ou sem a classe .app-dialog (virou drawer?)")
    else:
        if fim_main != -1 and painel.start() < fim_main:
            bad("reservas", f"{dlg!r} precisa ser renderizado fora de .page-content")
        if 'role="dialog" aria-modal="true"' not in painel.group(0):
            bad("reservas", f"{dlg!r} sem role=dialog/aria-modal")
if 'name="motivo"' not in h:
    bad("reservas", "o dialogo de negacao perdeu o campo motivo")
negacao = re.search(r'<aside id="dialog-negacao".*?</aside>', h, re.S)
cancelamento = re.search(r'<aside id="dialog-cancelamento".*?</aside>', h, re.S)
if negacao and cancelamento:
    neg, can = negacao.group(0), cancelamento.group(0)
    # O corpo existe sempre (e ele que carrega o <form>); o que nao pode e sobrar a faixa
    # em branco quando o dialogo nao tem campo nenhum.
    if "app-dialog-corpo--vazio" in neg:
        bad("reservas", "o dialogo de negacao tem campo: nao pode ser marcado como vazio")
    if "app-dialog-corpo--vazio" not in can:
        bad("reservas", "o dialogo de cancelamento nao tem campos: o corpo deveria sair vazio")
    # O titulo do campo vive no placeholder + aria-label, sem rotulo visivel.
    if 'placeholder="Motivo da negacao"' not in neg:
        bad("reservas", "o campo de motivo deveria usar o proprio titulo como placeholder")
    if 'aria-label="Motivo da negacao"' not in neg:
        bad("reservas", "campo sem rotulo visivel precisa de aria-label")
    if '<span>Motivo da negacao</span>' in h:
        bad("reservas", "o campo de motivo ainda tem rotulo visivel")
if 'btn-error' not in h:
    bad("reservas", "o botao de confirmar dos dialogos deveria ser vermelho (btn-error)")
if 'data-confirm' in h:
    bad("reservas", "a confirmacao nativa ainda esta na tela (o cancelamento tem de usar o dialogo)")
for rotulo in ("Aprovar", "Negar", "Cancelar"):
    if f'data-tip="{rotulo}"' not in h:
        bad("reservas", f"falta a acao {rotulo!r}")
# A celula de acoes TEM inputs escondidos por natureza (csrf e _method, do
# ui:acao-form); o que nao pode e campo VISIVEL — era o caso do motivo da negacao.
for celula in re.findall(r'<td class="cell-actions app-tabela-acoes">(.*?)</td>', h, re.S):
    if re.search(r'<(input(?![^>]*type="hidden")|select|textarea)[^>]*>', celula):
        bad("reservas", "a celula de acoes nao pode conter campo visivel (o motivo vive no dialogo)")

# areas: status em badge com o mapeamento fechado, editar + remover
h = html["areas"]
for variante, texto in re.findall(r'<span class="badge (badge-[a-z]+)">([^<]*)</span>', h):
    esperado = {"Ativo": "badge-success", "Inativo": "badge-neutral"}.get(texto)
    if esperado is None:
        bad("areas", f"status inesperado: {texto!r}")
    elif variante != esperado:
        bad("areas", f"status {texto!r} deveria usar {esperado}, usou {variante}")
if 'data-drawer-editar="drawer-area"' not in h:
    bad("areas", "sem gatilho de editar")
if 'data-tip="Remover"' not in h or 'app-btn-perigo' not in h:
    bad("areas", "sem acao de remover (com cor de perigo)")

# blocos: sem endpoint de edicao/remocao, so o link para as unidades
h = html["blocos"]
# O badge do rodape da lateral (papel do usuario logado) nao conta: a checagem olha so o
# corpo da tabela, porque bloco nao tem coluna de status.
corpo = re.search(r'<tbody>(.*?)</tbody>', h, re.S)
if corpo and re.search(r'<span class="badge ', corpo.group(1)):
    bad("blocos", "bloco nao tem coluna de status")
if 'data-tip="Ver unidades"' not in h or 'data-drawer-editar' in h:
    bad("blocos", "a unica acao deveria ser o link 'Ver unidades'")
if h.count('class="btn btn-ghost btn-sm btn-square tooltip"') < 1:
    bad("blocos", "o link de acao nao saiu como botao de icone")

# usuarios: perfil em badge, editar (tipo travado), gerenciar e desativar
h = html["usuarios"]
if not re.search(r'<span class="badge badge-neutral">(Administrador|Colaborador|Morador)</span>', h):
    bad("usuarios", "o perfil deveria ser um badge com o rotulo do tipo")
if 'data-campo="tipo" value="ADMINISTRADOR"' not in h:
    bad("usuarios", "o gatilho de editar deveria mandar a CHAVE do tipo (extraida do role)")
form = re.search(r'<form id="drawer-usuario-form".*?</form>', h, re.S)
if not form:
    bad("usuarios", "form do drawer ausente")
else:
    if 'data-drawer-travar="tipo"' not in form.group(0):
        bad("usuarios", "o perfil precisa ser travado na edicao (data-drawer-travar)")
    if 'data-drawer-espelho="tipo"' not in form.group(0):
        bad("usuarios", "falta o campo espelho do perfil travado")
    if 'name="senha"' not in form.group(0):
        bad("usuarios", "a senha e obrigatoria tambem na edicao")
if 'data-tip="Gerenciar"' not in h or 'data-tip="Desativar"' not in h:
    bad("usuarios", "faltam as acoes Gerenciar/Desativar")

# status-chamado: badges de situacao, editar so no editavel, tornar padrao
h = html["status-chamado"]
for variante in re.findall(r'<span class="badge (badge-[a-z]+)">', h):
    if variante not in ("badge-success", "badge-neutral", "badge-ghost"):
        bad("status-chamado", f"variante de badge inesperada: {variante}")
if h.count('<span class="badge badge-ghost">Reservado</span>') != 3:
    bad("status-chamado", "os 3 status reservados deveriam ser marcados como Reservado")
# Todo status NAO reservado tem de oferecer o gatilho de edicao — e nenhum reservado
# pode oferecer. Como isso depende dos dados, a checagem e a relacao entre as contagens.
linhas = h.count('<td class="cell-actions app-tabela-acoes">')
reservados = h.count('<span class="badge badge-ghost">Reservado</span>')
editaveis = h.count('data-drawer-editar="drawer-status"')
if editaveis != linhas - reservados:
    bad("status-chamado",
        f"{linhas} status, {reservados} reservados: esperava {linhas - reservados} gatilhos de editar, ha {editaveis}")
if 'data-tip="Tornar padrao"' not in h:
    bad("status-chamado", "falta a acao de definir o inicial padrao")
if '/inicial-padrao"' in h and 'value="patch"' not in h:
    bad("status-chamado", "definir padrao precisa de _method=patch")

# tipos-chamado: sem remocao, edicao no drawer; nenhuma coluna de status
h = html["tipos-chamado"]
corpo = re.search(r'<tbody>(.*?)</tbody>', h, re.S)
if corpo and re.search(r'<span class="badge ', corpo.group(1)):
    bad("tipos-chamado", "tipo de chamado nao tem coluna de status")
linhas = h.count('<td class="cell-actions app-tabela-acoes">')
if h.count('data-drawer-editar="drawer-tipo"') != linhas:
    bad("tipos-chamado", f"{linhas} linhas, mas nao ha um gatilho de editar por linha")
if 'app-btn-perigo' in h or 'data-tip="Remover"' in h:
    bad("tipos-chamado", "esta tela nao tem endpoint de remocao")
if 'data-campo="titulo"' not in h or 'data-campo="prazoHoras"' not in h:
    bad("tipos-chamado", "o gatilho de editar deveria levar titulo e prazoHoras")

# chamados: so leitura, filtros no servidor
h = html["chamados"]
if not re.search(r'<form method="get" action="/admin/chamados" class="app-card-filtros app-card-filtros--campos">', h):
    bad("chamados", "os filtros deveriam ser o proprio formulario GET na faixa")
for campo in ('name="statusId"', 'name="moradorNome"', 'name="dataAbertura"'):
    if campo not in h:
        bad("chamados", f"filtro {campo} ausente")
if 'data-tip="Detalhar"' not in h:
    bad("chamados", "falta a acao Detalhar")
if 'data-drawer-abrir' in h:
    bad("chamados", "esta tela nao cria nem edita: nao deveria ter drawer")
for variante, _ in re.findall(r'<span class="badge (badge-[a-z]+)">([^<]*)</span>', h):
    if variante != "badge-ghost":
        bad("chamados", f"o status do chamado e configuravel: deveria ser badge-ghost, veio {variante}")

if falhas:
    for f in falhas:
        print("  FAIL " + f)
    sys.exit(1)
print(f"  OK   {len(TELAS)} telas: cabecalho, filtros, tabela, badges e acoes no padrao")
PY
then :; else fail=1; fi

# Self-test negativo: cada sabotagem quebra UMA tela e o verificador tem de reprovar
# apontando aquela tela. Roda so na execucao "de verdade" (sem `HTML_DIR`), senao
# recursaria.
if [ -z "${HTML_DIR:-}" ]; then
    if python3 - "$WORK" "$WORK/sab" <<'FIM'
import pathlib, shutil, subprocess, sys, os

WORK, SAB = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])

CASOS = [
    ("areas", 'class="cell-actions app-tabela-acoes"', 'class="cell-actions"',
     "celula de acoes fora do padrao"),
    ("areas", '<span class="sr-only">Acoes</span>', '',
     "coluna de acoes sem rotulo acessivel"),
    ("areas", 'data-tip="Remover"', '', "acao sem tooltip"),
    ("areas", '<path d="M21 21l-6 -6" />', '', "busca sem a lupa"),
    ("areas", 'data-filter-target="areas-table"', 'data-filter-target="x"',
     "busca apontando para outra tabela"),
    ("areas", '<h2>Areas cadastradas</h2>', '', "cabecalho sem titulo"),
    ("areas", '<input type="search"', '<span>--%></span><input type="search"',
     "marcador de comentario JSP vazando para o HTML"),
    ("blocos", '<tbody>', '<tbody><tr><td><span class="badge badge-neutral">x</span></td></tr>',
     "badge onde nao ha coluna de status"),
    ("usuarios", 'data-drawer-espelho="tipo"', '', "perfil travado sem campo espelho"),
    ("chamados", 'class="app-card-filtros app-card-filtros--campos"', 'class="app-card-filtros"',
     "faixa de filtros sem a variante de campos"),
    ("tipos-chamado", 'data-drawer-editar="drawer-tipo"', 'data-drawer-editar="outro"',
     "gatilho de editar de tipos apontando para outro drawer"),
    ("reservas", 'class="app-dialog app-dialog--md"', 'class="app-drawer app-drawer--md"',
     "dialogo de negacao renderizado como drawer lateral"),
    ("reservas", 'name="motivo"', 'name="semMotivo"',
     "dialogo de negacao sem o campo de motivo"),
    ("reservas", 'placeholder="Motivo da negacao"', 'placeholder="Ex.: manutencao da piscina"',
     "campo de motivo volta ao placeholder de exemplo, sem titulo"),
    ("reservas", 'class="app-dialog-corpo app-dialog-corpo--vazio"', 'class="app-dialog-corpo"',
     "dialogo de confirmacao volta a renderizar a faixa do corpo"),
]

if SAB.exists():
    shutil.rmtree(SAB)
SAB.mkdir(parents=True)

reprovadas = 0
for tela, antigo, novo, nome in CASOS:
    for arq in WORK.glob("*.html"):
        shutil.copy(arq, SAB / arq.name)
    alvo = SAB / (tela + ".html")
    html = alvo.read_text(encoding="utf-8")
    if antigo not in html:
        print("  FAIL sabotagem '" + nome + "' nao alterou " + tela + ".html (nao mediu nada)")
        continue
    alvo.write_text(html.replace(antigo, novo, 1), encoding="utf-8")

    p = subprocess.run(["bash", "scripts/ui-tabelas.sh"], capture_output=True, text=True,
                       env=dict(os.environ, HTML_DIR=str(SAB)))
    if p.returncode == 0:
        print("  FAIL sabotagem '" + nome + "' passou — o verificador nao detecta essa quebra")
    elif ("FAIL " + tela + ":") not in p.stdout:
        print("  FAIL sabotagem '" + nome + "' reprovou por outro motivo, nao por " + tela)
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
import os, re, pathlib

problemas = []
def check(cond, msg):
    if not cond:
        problemas.append(msg)

def bloco(css, seletor):
    """Corpo da regra cujo seletor bate exatamente (funciona dentro de @media).
    Os comentarios saem antes: um `/* ... */` entre a regra anterior e esta entraria
    no grupo do seletor, porque o grupo comeca logo depois do `}` anterior."""
    sem_comentarios = re.sub(r'/\*.*?\*/', '', css, flags=re.S)
    for m in re.finditer(r'([^{}]*)\{([^{}]*)\}', sem_comentarios):
        if m.group(1).strip() == seletor:
            return m.group(2)
    return None

def regra(css, seletor):
    """Corpo da primeira regra minificada `seletor{...}` do bundle."""
    m = re.search(re.escape(seletor) + r'\{([^}]*)\}', css)
    return m.group(1) if m else None

def verificar(custom, build):
    problemas = []
    def check(cond, msg):
        if not cond:
            problemas.append(msg)

    cab = bloco(custom, ".app-card-head")
    if cab is None:
        problemas.append("custom.css sem a regra .app-card-head")
    else:
        for prop, valor in (("display", "flex"), ("flex-direction", "row"),
                            ("align-items", "center"), ("justify-content", "space-between")):
            check(re.search(rf'{prop}\s*:\s*{valor}\s*;', cab) is not None,
                  f".app-card-head deveria ter `{prop}: {valor}`")
        check(re.search(r'border-bottom\s*:\s*1px solid', cab) is not None,
              ".app-card-head deveria ter o filete que separa os filtros")
        check("column" not in cab, ".app-card-head nao pode empilhar")

    texto = bloco(custom, ".app-card-head__texto")
    if texto is None:
        problemas.append("custom.css sem a regra .app-card-head__texto")
    else:
        gap = re.search(r'gap\s*:\s*([0-9.]+)rem', texto)
        check(gap is not None and float(gap.group(1)) <= 0.25,
              "descricao e titulo deveriam ficar colados (gap <= 0.25rem)")
    check(bloco(custom, ".app-card-head__texto .eyebrow") is not None,
          "falta o reset do respiro do `.eyebrow`")
    titulo = bloco(custom, ".app-card-head h2")
    check(titulo is not None and re.search(r'font-size\s*:\s*1\.5rem', titulo or "") is not None,
          ".app-card-head h2 deveria repor a tipografia do titulo")

    filtros = bloco(custom, ".app-card-filtros")
    check(filtros is not None and "display: flex" in (filtros or ""),
          ".app-card-filtros deveria ser um container flexivel")
    campos = bloco(custom, ".app-card-filtros--campos")
    check(campos is not None and re.search(r'align-items\s*:\s*flex-end', campos or "") is not None,
          ".app-card-filtros--campos deveria alinhar as acoes pela base (formulario GET)")

    dialogo = bloco(custom, ".app-dialog")
    if dialogo is None:
        problemas.append("custom.css sem a regra .app-dialog")
    else:
        for prop, valor in (("position", "fixed"), ("inset", "0"), ("margin", "auto")):
            check(re.search(rf'{prop}\s*:\s*{valor}\s*;', dialogo) is not None,
                  f".app-dialog deveria ter `{prop}: {valor}` (e assim que centraliza)")
        check(re.search(r'max-height\s*:', dialogo) is not None,
              ".app-dialog deveria limitar a altura (senao estoura a viewport)")
        # Sem `height: fit-content` o `inset: 0` estica o painel entre top e bottom e o
        # dialogo vira uma coluna da altura da tela, com o corpo vazio no meio.
        check(re.search(r'height\s*:\s*fit-content', dialogo) is not None,
              ".app-dialog deveria ter `height: fit-content` (com `inset: 0` a altura automatica estica)")
        check(re.search(r'visibility\s*:\s*hidden', dialogo) is not None,
              ".app-dialog deveria nascer escondido")
    topo = bloco(custom, ".app-dialog-topo")
    check(topo is not None and re.search(r'border(?:-(?:top|bottom|inline|block))?\s*:', topo or "") is None,
          ".app-dialog-topo nao pode ter filete (o corpo e opcional; a linha ficaria solta)")
    rodape = bloco(custom, ".app-dialog-rodape")
    check(rodape is not None and re.search(r'border(?:-(?:top|bottom|inline|block))?\s*:', rodape or "") is None,
          ".app-dialog-rodape nao pode ter filete")
    vazio = bloco(custom, ".app-dialog-corpo--vazio")
    check(vazio is not None and re.search(r'padding\s*:\s*0', vazio or "") is not None,
          "falta `.app-dialog-corpo--vazio` com padding 0 (dialogo sem campos ficaria com faixa em branco)")
    check(bloco(custom, ".app-dialog[data-drawer-aberto]") is not None,
          "falta o estado aberto do dialogo")
    check(bloco(custom, ".app-dialog-rodape") is not None, "falta o rodape do dialogo")
    check(bloco(custom, ".app-dialog-corpo") is not None, "falta o corpo do dialogo")

    acoes = bloco(custom, ".app-tabela-acoes")
    if acoes is None:
        problemas.append("custom.css sem a regra .app-tabela-acoes")
    else:
        check(re.search(r'justify-content\s*:\s*flex-end', acoes) is not None,
              ".app-tabela-acoes deveria empurrar as acoes para a direita")
        check(re.search(r'padding-inline-end\s*:\s*0', acoes) is not None,
              ".app-tabela-acoes deveria encostar na borda da tabela")
    check(bloco(custom, ".app-tabela-acoes form") is not None, "falta o `form { display: flex }` das acoes")
    check(bloco(custom, ".app-tabela-acoes .btn:hover") is not None, "falta o hover proprio das acoes")
    perigo = bloco(custom, ".app-btn-perigo")
    check(perigo is not None and "var(--color-error)" in (perigo or ""),
          ".app-btn-perigo deveria pintar o icone com --color-error")
    check(bloco(custom, ".app-tabela-acoes .app-btn-perigo:hover") is not None,
          "falta o hover proprio da acao destrutiva")
    balao = bloco(custom, ".app-tabela-acoes .tooltip[data-tip]:before")
    check(balao is not None and re.search(r'right\s*:\s*0', balao or "") is not None,
          "o tooltip das acoes deveria alinhar pela direita do botao")

    # classes do bundle que o padrao pressupoe (somem em silencio se ninguem as usar)
    check("display:inline-flex" in (regra(build, ".input") or ""),
          "o bundle perdeu `.input{display:inline-flex}`")
    for classe in (".input-sm", ".size-4", ".shrink-0", ".opacity-60", ".tooltip",
                   ".btn-ghost", ".btn-sm", ".btn-square", ".sr-only", ".flex", ".items-center",
                   ".badge-success", ".badge-warning", ".badge-error", ".badge-neutral", ".badge-ghost",
                   ".btn-error", ".btn-primary", ".btn-circle"):
        check(regra(build, classe) is not None,
              f"a classe {classe} sumiu de app.build.css (rode `npm run build:css`)")
    return problemas

custom = pathlib.Path(os.environ.get("CUSTOM_CSS", "src/main/resources/static/css/custom.css")).read_text(encoding="utf-8")
build = pathlib.Path(os.environ.get("BUILD_CSS", "src/main/resources/static/css/app.build.css")).read_text(encoding="utf-8")

problemas = verificar(custom, build)
if problemas:
    for p in problemas:
        print("  FAIL " + p)
    raise SystemExit(1)
print("  OK   cabecalho, faixa de filtros e coluna de acoes; classes do bundle presentes")

# self-test negativo: o verificador so vale se reprovar o contrato quebrado
SABOTAGENS = [
    ("filete do cabecalho removido",
     lambda c: c.replace("    /* O filete que separa o cabecalho da faixa de filtros logo abaixo. */\n    border-bottom: 1px solid var(--color-base-300);", "", 1)),
    ("cabecalho empilhado",
     lambda c: c.replace("    flex-direction: row;\n    flex-wrap: wrap;", "    flex-direction: column;", 1)),
    ("espaco do titulo aumentado",
     lambda c: c.replace("    gap: 0.125rem;", "    gap: 1rem;", 1)),
    ("tipografia do h2 removida",
     lambda c: re.sub(r'\.app-card-head h2 \{[^}]*\}', '', c, count=1)),
    ("acoes alinhadas a esquerda",
     lambda c: c.replace("    justify-content: flex-end;\n    gap: 0.25rem;", "    justify-content: flex-start;\n    gap: 0.25rem;", 1)),
    ("padding da ultima celula de volta",
     lambda c: c.replace("    gap: 0.25rem;\n    padding-inline-end: 0;", "    gap: 0.25rem;", 1)),
    ("hover da acao destrutiva removido",
     lambda c: re.sub(r'\.app-tabela-acoes \.app-btn-perigo:hover \{[^}]*\}', '', c, count=1)),
    ("cor da acao destrutiva removida",
     lambda c: re.sub(r'\.app-btn-perigo \{[^}]*\}', '', c, count=1)),
    ("balao do tooltip volta ao centro",
     lambda c: c.replace("    left: auto;\n    right: 0;\n    transform: translateY(var(--tt-pos, 0.25rem));",
                         "    transform: translateY(var(--tt-pos, 0.25rem));", 1)),
    ("variante de faixa de filtros removida",
     lambda c: re.sub(r'\.app-card-filtros--campos \{[^}]*\}', '', c, count=1)),
    ("dialogo deixa de ser centralizado",
     lambda c: c.replace("    margin: auto;\n    border-radius: var(--radius-box);", "    border-radius: var(--radius-box);", 1)),
    ("filete de volta no topo do dialogo",
     lambda c: c.replace("    padding: 1rem 1.25rem;\n}\n\n/* Unica regiao com scroll",
                         "    padding: 1rem 1.25rem;\n    border-bottom: 1px solid var(--color-base-300);\n}\n\n/* Unica regiao com scroll", 1)),
    ("filete de volta no rodape do dialogo",
     lambda c: c.replace("    gap: 0.5rem;\n    padding: 1rem 1.25rem;\n}\n\n/* Dialogo sem campos",
                         "    gap: 0.5rem;\n    padding: 1rem 1.25rem;\n    border-top: 1px solid var(--color-base-300);\n}\n\n/* Dialogo sem campos", 1)),
    ("corpo vazio volta a ter padding",
     lambda c: re.sub(r'\.app-dialog-corpo--vazio \{[^}]*\}', '', c, count=1)),
    ("dialogo deixa de ter altura de conteudo",
     lambda c: c.replace("    height: fit-content;\n", "", 1)),
    ("dialogo nasce visivel",
     lambda c: c.replace("    visibility: hidden;\n    opacity: 0;\n    scale: 0.96;", "    opacity: 0;\n    scale: 0.96;", 1)),
]
passou = 0
for nome, sabotar in SABOTAGENS:
    alterado = sabotar(custom)
    if alterado == custom:
        print(f"  FAIL sabotagem '{nome}' nao alterou o CSS (o self-test nao mediu nada)")
        continue
    if verificar(alterado, build):
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
if node scripts/ui-drawer-js.mjs > "$WORK/drawer-js.txt" 2>&1; then
    ok "drawer.js: $(grep -c '^  OK' "$WORK/drawer-js.txt") casos executados (inclui os campos do gatilho e o campo travado)"
else
    bad "comportamento do drawer.js"
    sed 's/^/       /' "$WORK/drawer-js.txt"
fi
if node scripts/ui-tables-js.mjs > "$WORK/tables-js.txt" 2>&1; then
    ok "tables.js: $(grep -c '^  OK' "$WORK/tables-js.txt") casos executados (busca dentro do label.input e roteamento por alvo)"
else
    bad "comportamento do tables.js"
    sed 's/^/       /' "$WORK/tables-js.txt"
fi

# O harness so vale se falhar quando o contrato quebra.
SAB="baseline/tabelas/sabotagem.mjs"
sabotagens=(
    's/"data-filter-input": "",//|sem o hook data-filter-input'
    's/const alvo = busca("areas-table");/const alvo = busca("outra-tabela");/|alvo data-filter-target trocado'
    's/^\( *\)document\._disparar("DOMContentLoaded".*$/\1;/|tables.js nao inicializado'
)
n_sab=0
for entrada in "${sabotagens[@]}"; do
    cp scripts/ui-tables-js.mjs "$SAB"
    sed -i "${entrada%%|*}" "$SAB"
    if node "$SAB" > /dev/null 2>&1; then
        bad "o harness passou numa sabotagem (${entrada##*|}) — teste nao esta medindo"
    else
        n_sab=$((n_sab + 1))
    fi
    rm -f "$SAB"
done
[ "$n_sab" = "${#sabotagens[@]}" ] \
    && ok "self-test negativo do tables.js: $n_sab/${#sabotagens[@]} sabotagens reprovadas" \
    || bad "self-test negativo incompleto: $n_sab/${#sabotagens[@]}"

# ------------------------------------------------------------------ D. sem requery

echo "== D. o filtro local continua local (sem requery) =="
if python3 - <<'PY'
import re, pathlib

problemas = []

# As listagens de cadastro nao tem parametro de busca: o filtro da faixa e uma
# travessia de DOM. Se aparecer um, o filtro passou a bater no banco.
ctrl = pathlib.Path("src/main/java/br/com/dunnastecnologia/chamados/infrastructure/controller/web/AdminWebController.java").read_text(encoding="utf-8")
for metodo, extra in (("listarAreas", {"authentication", "page", "size", "areaId", "model"}),
                      ("listarBlocos", {"page", "size", "model"}),
                      ("listarUsuarios", {"page", "size", "model"}),
                      ("listarStatusChamado", {"page", "size", "statusId", "model"}),
                      ("listarTiposChamado", {"page", "size", "tipoId", "model"})):
    m = re.search(r'public String ' + metodo + r'\((.*?)\)\s*\{', ctrl, re.S)
    if not m:
        problemas.append(f"nao achei a assinatura de {metodo}")
        continue
    params = {p.strip().split()[-1] for p in m.group(1).split(",") if p.strip()}
    sobrando = params - extra
    if sobrando:
        problemas.append(f"{metodo} ganhou parametro(s) de busca: {sorted(sobrando)}")

js = pathlib.Path("src/main/resources/static/js/tables.js").read_text(encoding="utf-8")
for proibido in ("fetch(", "XMLHttpRequest", "URLSearchParams", "location."):
    if proibido in js:
        problemas.append(f"tables.js usa {proibido!r} — o filtro deixou de ser local")

if problemas:
    for p in problemas:
        print("  FAIL " + p)
    raise SystemExit(1)
print("  OK   nenhuma listagem de cadastro ganhou parametro de busca; tables.js nao faz requisicao")
PY
then :; else fail=1; fi

echo
if [ "$fail" = 0 ]; then
    echo "TABELAS OK"
else
    echo "TABELAS COM FALHAS"
fi
exit "$fail"
