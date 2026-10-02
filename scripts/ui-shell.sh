#!/usr/bin/env bash
# S19 — Verificador do shell (lateral dashboard-01 + topbar) sobre o HTML ja renderizado.
#
# Nao faz requisicoes: le os arquivos que `scripts/ui-routes.sh shell` gravou em
# baseline/html-shell/. Rode aquele script antes deste.
#
#   bash scripts/ui-routes.sh shell
#   bash scripts/ui-shell.sh
#
# Exit code: 0 = shell conforme, 1 = divergencia.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
DIR="${DIR:-baseline/html-shell}"

[ -d "$DIR" ] || { echo "sem $DIR; rode: bash scripts/ui-routes.sh shell"; exit 2; }

python3 - "$DIR" <<'PY'
import re, sys, pathlib

DIR = pathlib.Path(sys.argv[1])

# Espelho da navegacao declarada em fragments/sidebar.jspf (href, rotulo, alias do icone).
NAV = {
 "admin": [("/admin","Inicio"),("/admin/chamados","Chamados"),
           ("/admin/reservas/agenda","Agenda"),("/admin/reservas","Reservas"),
           ("/admin/blocos","Blocos"),("/admin/areas","Areas"),
           ("/admin/tipos-chamado","Tipos de Chamado"),("/admin/status-chamado","Status"),
           ("/admin/usuarios","Usuarios"),("/admin/vinculos-morador","Vincular Morador"),
           ("/admin/escopo-colaborador","Escopo Colaborador")],
 "morador": [("/morador","Inicio"),("/morador/chamados/novo","Abrir Chamado"),
             ("/morador/chamados","Meus Chamados"),("/morador/reservas/agenda","Agenda"),
             ("/morador/reservas/nova","Reservar Area"),("/morador/reservas","Minhas Reservas")],
 "colaborador": [("/colaborador","Inicio"),("/colaborador/chamados","Fila de Atendimento")],
}
GRUPOS = {"admin":["Operacao","Cadastros","Acessos"],"morador":["Chamados","Reservas"],
          "colaborador":["Atendimento"]}
HOMES = {"/admin","/morador","/colaborador"}
REQ = {
 "admin":"/admin","admin-blocos":"/admin/blocos","admin-areas":"/admin/areas",
 "admin-tipos-chamado":"/admin/tipos-chamado","admin-status-chamado":"/admin/status-chamado",
 "admin-usuarios":"/admin/usuarios","admin-vinculos-morador":"/admin/vinculos-morador",
 "admin-escopo-colaborador":"/admin/escopo-colaborador","admin-chamados":"/admin/chamados",
 "admin-reservas":"/admin/reservas","admin-reservas-agenda":"/admin/reservas/agenda",
 "morador":"/morador","morador-chamados":"/morador/chamados","morador-chamados-novo":"/morador/chamados/novo",
 "morador-reservas":"/morador/reservas","morador-reservas-nova":"/morador/reservas/nova",
 "morador-reservas-agenda":"/morador/reservas/agenda",
 "morador-reservas-disponibilidade":"/morador/reservas/disponibilidade",
 "colaborador":"/colaborador","colaborador-chamados":"/colaborador/chamados",
}
SIDEBAR = 'class="app-sidebar flex h-full w-72 flex-col bg-base-200 lg:bg-transparent"'
TOPBAR = ['<label for="app-drawer" class="btn btn-square btn-sm btn-ghost lg:hidden"',
          'class="mx-2 hidden h-4 w-px shrink-0 bg-base-300 lg:block"',
          'class="font-display truncate text-lg font-semibold"',
          'class="badge badge-ghost badge-sm gap-1"']

falhas, paginas = [], 0
for arq in sorted(DIR.glob("*.html")):
    nome = arq.stem
    if nome == "login":            # pagina publica: sem shell
        continue
    chave = re.sub(r"-[0-9a-f]{8}-[0-9a-f-]{27,}$", "", nome)
    if chave not in REQ:
        falhas.append(f"{nome}: sem rota mapeada"); continue
    perfil = chave.split("-")[0]; req = REQ[chave]
    h = arq.read_text(encoding="utf-8"); paginas += 1
    bad = lambda m: falhas.append(f"{nome}: {m}")

    # ---- lateral --------------------------------------------------------
    m = re.search(r'<div class="drawer-side.*?</aside>', h, re.S)
    if not m: bad("lateral ausente"); continue
    sb = m.group(0)
    for frag in [SIDEBAR, 'drawer-side z-30 p-1.5 lg:p-2', 'avatar avatar-placeholder',
                 'dropdown dropdown-top', 'id="app-logout"', 'action="/logout"',
                 'aria-label="Navegacao principal"', '<li class="menu-title">',
                 '<button type="submit" form="app-logout" class="text-error">', '>Sair</span>']:
        if frag not in sb: bad(f"falta {frag[:46]!r}")
    if '<circle cx="12" cy="12" r="9" />' in sb:
        bad("icone de fallback emitido (alias desconhecido em icone.jspf)")
    # A lateral fica SOBRE o fundo da pagina (S21): se voltar a ser uma ilha com
    # superficie/borda/sombra proprias, isto falha.
    tag_aside = re.search(r'<aside[^>]*>', sb)
    cabecalho_aside = tag_aside.group(0) if tag_aside else ''
    if not cabecalho_aside:
        bad("tag <aside> da lateral nao encontrada")
    for ilha in ('bg-base-100', 'rounded-box', 'shadow-sm', 'border'):
        if ilha in cabecalho_aside:
            bad(f"lateral voltou a ser ilha: {ilha!r} no <aside>")
    if 'lg:bg-transparent' not in cabecalho_aside:
        bad("lateral sem `lg:bg-transparent` (nao esta sobre o fundo da pagina)")
    if f'href="{"/" + perfil}"' not in sb: bad("link da marca nao aponta para a home do perfil")
    if not re.search(r'<div class="h-8 w-8 bg-neutral text-xs font-semibold text-neutral-content">[A-Z0-9]{1,2}</div>', sb):
        bad("iniciais do avatar ausentes/malformadas")

    itens = re.findall(r'<li>\s*<a href="([^"]+)"\s*class="([^"]*)"([^>]*)>(.*?)</a>\s*</li>', sb, re.S)
    if [i[0] for i in itens] != [e[0] for e in NAV[perfil]]:
        bad(f"navegacao difere: {[i[0] for i in itens]}")
    else:
        for (href, _cls, _extra, body), (_eh, el) in zip(itens, NAV[perfil]):
            if f'<span class="min-w-0 truncate">{el}</span>' not in body:
                bad(f"rotulo {el!r} ausente em {href}")
            if 'class="size-4 shrink-0" aria-hidden="true"' not in body:
                bad(f"icone ausente em {href}")

    ativos = re.findall(r'<li>\s*<a href="([^"]+)"\s*class="menu-active" aria-current="page">', sb)
    if len(ativos) != 1:
        bad(f"{len(ativos)} itens ativos (esperado 1): {ativos}")
    else:
        cand = [x for x, _ in NAV[perfil] if (req == x if x in HOMES else req.startswith(x))]
        melhor = max(cand, key=len) if cand else None
        if ativos[0] != melhor:
            bad(f"ativo={ativos[0]} esperado={melhor} (requisicao={req})")
    if sb.count('aria-current="page"') != 1:
        bad("aria-current duplicado na navegacao")

    g = re.findall(r'<p class="px-2 text-xs font-semibold tracking-wider uppercase opacity-60">([^<]*)</p>', sb)
    if g != GRUPOS[perfil]: bad(f"grupos={g} esperado={GRUPOS[perfil]}")

    # ---- topbar ---------------------------------------------------------
    m = re.search(r'<header class="app-topbar navbar">.*?</header>', h, re.S)
    if not m: bad("topbar ausente"); continue
    tb = m.group(0)
    for frag in TOPBAR:
        if frag not in tb: bad(f"topbar sem {frag[:44]!r}")
    if '<svg' not in tb: bad("topbar sem icone")
    if not re.search(r'<h1 class="font-display truncate text-lg font-semibold">[^<]+</h1>', tb):
        bad("titulo da tela ausente na topbar")
    for proibido in ("/logout", "Sair", "app-logout"):
        if proibido in tb: bad(f"topbar ainda contem {proibido!r} (deveria estar so na lateral)")

print(f"paginas verificadas: {paginas}")
if falhas:
    print(f"FALHAS: {len(falhas)}")
    for f in falhas[:25]: print("  -", f)
    sys.exit(1)
PY

echo "  OK   lateral (dashboard-01), icones, grupos, estado ativo e cartao do usuario"

# ------------------------------------------------------- CSRF (checagem de fonte)
# A materializacao do token NAO aparece no HTML — `<c:set>` nao emite nada — entao so
# da para verifica-la na fonte. Sem ela o `Set-Cookie: XSRF-TOKEN` se perde quando a
# resposta passa do buffer de 8 KB do Tomcat, e ai TODO POST autenticado responde 403.
# Foi exatamente o que os icones inline causaram em S19. Ver baseline/EVIDENCE.md > S19.
fail=0
grep -q 'value="${_csrf.token}"' src/main/webapp/WEB-INF/jsp/fragments/head.jspf \
  || { echo "  FAIL head.jspf nao materializa \${_csrf.token} antes do corpo"; fail=1; }

n=0
for jsp in $(find src/main/webapp/WEB-INF/jsp -name '*.jsp' | sort); do
    n=$((n + 1))
    # O login tem shell proprio (`auth-body`, sem drawer) e nao usa o `ui:shell`.
    [ "$(basename "$jsp")" = "login.jsp" ] && continue

    # S31: a pagina nao emite mais doctype/head — quem emite e o `ui:shell`, que inclui o
    # `head.jspf` (e portanto a materializacao do token). A checagem passa a exigir o par
    # `ui:shell`/`ui:shell-fim` em toda tela e a inclusao do head dentro do tag.
    grep -q 'fragments/head.jspf' src/main/webapp/WEB-INF/tags/shell.tag \
      || { echo "  FAIL tags/shell.tag nao inclui head.jspf"; fail=1; }
    grep -q '<ui:shell ' "$jsp" \
      || { echo "  FAIL $jsp nao usa ui:shell"; fail=1; }
    grep -q '<ui:shell-fim />' "$jsp" \
      || { echo "  FAIL $jsp nao fecha com ui:shell-fim"; fail=1; }
done
echo "  OK   token CSRF no <head> e ui:shell presente nas $n paginas"

# ------------------------------------------------------- encoding do fonte
# A diretiva `pageEncoding` vale para o ARQUIVO em que ela aparece. Como ela vive em
# `taglibs.jspf` (que e INCLUIDO), ela nao vale para a pagina que inclui: sem a declaracao
# na propria pagina, o Jasper le o arquivo como ISO-8859-1 e TODO acento sai duplicado
# ("Ãº" no lugar de "u com acento"). Foi assim que a S29 descobriu que o projeto nunca
# tinha acentuado texto visivel em JSP.
n=0
for jsp in $(grep -rl 'fragments/taglibs.jspf' src/main/webapp/WEB-INF/jsp --include=*.jsp); do
    n=$((n + 1))
    head -1 "$jsp" | grep -q 'pageEncoding="UTF-8"' \
      || { echo "  FAIL $jsp nao declara pageEncoding=\"UTF-8\" na primeira linha"; fail=1; }
done
echo "  OK   $n paginas declaram pageEncoding na primeira linha"

# S30: a mesma armadilha vale para os FRAGMENTOS (`<%@ include %>`). O `pageEncoding` da
# pagina que inclui NAO vale para o arquivo incluido: o Jasper le o .jspf com o encoding
# padrao (ISO-8859-1), e todo byte nao-ASCII vira mojibake. Estava acontecendo em dois
# lugares reais: o `×` do `alerts.jspf` (saia "Ã") e os acentos que a S30 escreveu em
# `reservas-agenda.jspf`. A declaracao tem de vir ANTES do primeiro byte nao-ASCII: depois
# dele a troca de encoding nao vale mais, porque o arquivo ja foi lido.
#
# O que esta dentro de comentario JSP nao conta (o texto sai na traducao), e por isso a
# checagem tira os `<%-- ... --%>` antes de procurar.
if python3 - <<'PY'
import pathlib, re, sys

falhas = []
checados = 0
for arq in sorted(pathlib.Path("src/main/webapp").rglob("*")):
    if arq.suffix not in (".jsp", ".jspf", ".tag"):
        continue
    try:
        bruto = arq.read_text(encoding="utf-8")
    except UnicodeDecodeError as erro:
        falhas.append(f"{arq} nao esta em UTF-8 ({erro})")
        continue

    def sem_comentarios(texto):
        return re.sub(r"<%--.*?--%>", "", texto, flags=re.S)

    if sem_comentarios(bruto).isascii():
        continue                      # ASCII puro: o encoding nao muda nada
    checados += 1

    pos = bruto.find('pageEncoding="UTF-8"')
    if pos == -1:
        falhas.append(f"{arq} tem texto nao-ASCII visivel e nao declara pageEncoding=\"UTF-8\"")
    elif not sem_comentarios(bruto[:pos]).isascii():
        falhas.append(f"{arq} declara o encoding DEPOIS de texto nao-ASCII (a troca so vale se vier antes)")

if falhas:
    for f in falhas:
        print(f"  FAIL {f}")
    sys.exit(1)
print(f"  OK   {checados} arquivos com texto nao-ASCII declaram o encoding antes dele")
PY
then :; else fail=1; fi
[ "$fail" = 0 ] && echo "SHELL OK"
exit "$fail"
