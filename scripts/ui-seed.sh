#!/usr/bin/env bash
# S2 — Fixture idempotente para a matriz de rotas (UI-REWRITE-PLAN.md §3 / S2).
#
# Cria dados via os MESMOS endpoints de formulario que os JSPs usam (sessao + CSRF),
# nunca pela API JSON: nao existe /api/auth/** implementado e o cookie `jwt` nunca e
# escrito, logo a API stateless nao e utilizavel. Ver baseline/EVIDENCE.md.
#
# Leituras de verificacao/idempotencia usam psql (determinismo); as ESCRITAS passam pelo app.
# Idempotente: reexecutar nao duplica registros.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
BASE="${BASE:-http://localhost:8080}"
DB="${DB:-gerenciador_chamados}"
OUT="baseline"
mkdir -p "$OUT"

ADMIN_EMAIL="${ADMIN_EMAIL:-admin@condominio.local}"
ADMIN_SENHA="${ADMIN_SENHA:-admin123}"
MORADOR_EMAIL="morador@condominio.local"
COLABORADOR_EMAIL="colaborador@condominio.local"
SENHA_FIXTURE="$ADMIN_SENHA"

qs() { docker exec postgres_condominio psql -U postgres -d "$DB" -tAc "$1" | tr -d '[:space:]'; }
log() { printf '[S2] %s\n' "$*"; }

login() { # <jar> <email> <senha>
    local jar="$1" email="$2" senha="$3" tok
    rm -f "$jar"
    tok="$(curl -s -c "$jar" "$BASE/login" | grep -o 'name="_csrf" value="[^"]*"' | sed 's/.*value="//; s/"//')"
    curl -s -b "$jar" -c "$jar" -o /dev/null -w '%{http_code}' -X POST "$BASE/login" \
        --data-urlencode "username=$email" --data-urlencode "password=$senha" --data-urlencode "_csrf=$tok"
}

# O token CSRF e mascarado (BREACH) no HTML e o cookie XSRF-TOKEN e LIMPO no login,
# entao cada POST precisa reler o `_csrf` de um formulario recem-renderizado da sessao.
token_page() { # <jar> -> pagina com formulario POST daquele perfil
    case "$1" in
        *admin.jar)   echo /admin/usuarios ;;
        *morador.jar) echo /morador/chamados/novo ;;
        *)            echo /login ;;
    esac
}

fresh_token() { # <jar>
    curl -s -b "$1" -c "$1" "$BASE$(token_page "$1")" \
        | grep -o 'name="_csrf" value="[^"]*"' | head -n1 | sed 's/.*value="//; s/"//'
}

post() { # <jar> <path> <--data-urlencode args...>
    local jar="$1" path="$2"; shift 2
    local tok
    tok="$(fresh_token "$jar")"
    [ -n "$tok" ] || { log "FAIL nao foi possivel obter _csrf para $jar"; exit 1; }
    curl -s -b "$jar" -c "$jar" -o /dev/null -w '%{http_code}' -X POST "$BASE$path" \
        --data-urlencode "_csrf=$tok" "$@"
}

post_multipart() { # <jar> <path> <-F args...>
    local jar="$1" path="$2"; shift 2
    local tok
    tok="$(fresh_token "$jar")"
    [ -n "$tok" ] || { log "FAIL nao foi possivel obter _csrf para $jar"; exit 1; }
    curl -s -b "$jar" -c "$jar" -o /dev/null -w '%{http_code}' -X POST "$BASE$path" \
        -F "_csrf=$tok" "$@"
}

expect_302() { # <label> <status>
    if [ "$2" = "302" ]; then log "ok   $1 (302)"; else log "FAIL $1 -> HTTP $2"; exit 1; fi
}

# ------------------------------------------------------------------ login admin
expect_302 "admin login" "$(login "$OUT/admin.jar" "$ADMIN_EMAIL" "$ADMIN_SENHA")"

# ------------------------------------------------------------------ estrutura
if [ "$(qs "select count(*) from blocos where identificacao = 'Bloco A'")" = "0" ]; then
    expect_302 "bloco 'Bloco A' criado" \
        "$(post "$OUT/admin.jar" /admin/blocos \
            --data-urlencode "identificacao=Bloco A" \
            --data-urlencode "quantidadeAndares=2" \
            --data-urlencode "apartamentosPorAndar=3")"
else
    log "skip bloco 'Bloco A' (ja existe)"
fi

if [ "$(qs "select count(*) from areas where nome = 'Piscina'")" = "0" ]; then
    expect_302 "area 'Piscina' criada" \
        "$(post "$OUT/admin.jar" /admin/areas \
            --data-urlencode "nome=Piscina" \
            --data-urlencode "status=Ativo")"
else
    log "skip area 'Piscina' (ja existe)"
fi

if [ "$(qs "select count(*) from tipos_chamado where titulo = 'Vazamento'")" = "0" ]; then
    expect_302 "tipo 'Vazamento' criado" \
        "$(post "$OUT/admin.jar" /admin/tipos-chamado \
            --data-urlencode "titulo=Vazamento" \
            --data-urlencode "prazoHoras=48")"
else
    log "skip tipo 'Vazamento' (ja existe)"
fi

for spec in "$MORADOR_EMAIL|Maria Moradora|MORADOR" "$COLABORADOR_EMAIL|Carlos Colaborador|COLABORADOR"; do
    email="${spec%%|*}"; rest="${spec#*|}"; nome="${rest%%|*}"; tipo="${rest##*|}"
    if [ "$(qs "select count(*) from usuarios where email = '$email'")" = "0" ]; then
        expect_302 "usuario $email ($tipo) criado" \
            "$(post "$OUT/admin.jar" /admin/usuarios \
                --data-urlencode "nome=$nome" \
                --data-urlencode "email=$email" \
                --data-urlencode "senha=$SENHA_FIXTURE" \
                --data-urlencode "tipo=$tipo")"
    else
        log "skip usuario $email (ja existe)"
    fi
done

# ------------------------------------------------------------------ ids
BLOCO_ID="$(qs "select id from blocos where identificacao = 'Bloco A'")"
UNIDADE_ID="$(qs "select u.id from unidades u join blocos b on b.id = u.bloco_id where b.id = '$BLOCO_ID' order by u.identificacao limit 1")"
AREA_ID="$(qs "select id from areas where nome = 'Piscina'")"
TIPO_ID="$(qs "select id from tipos_chamado where titulo = 'Vazamento'")"
MORADOR_ID="$(qs "select id from usuarios where email = '$MORADOR_EMAIL'")"
COLABORADOR_ID="$(qs "select id from usuarios where email = '$COLABORADOR_EMAIL'")"

[ -n "$UNIDADE_ID" ] && [ -n "$AREA_ID" ] && [ -n "$TIPO_ID" ] || { log "FAIL fixture incompleta (ids vazios)"; exit 1; }
log "ids bloco=$BLOCO_ID unidade=$UNIDADE_ID area=$AREA_ID tipo=$TIPO_ID"

# ------------------------------------------------------------------ vinculos
if [ "$(qs "select count(*) from morador_unidade where morador_id = '$MORADOR_ID'")" = "0" ]; then
    expect_302 "morador vinculado a unidade" \
        "$(post "$OUT/admin.jar" "/admin/moradores/$MORADOR_ID/unidades" \
            --data-urlencode "_method=put" \
            --data-urlencode "blocoId=$BLOCO_ID" \
            --data-urlencode "unidadeId=$UNIDADE_ID")"
else
    log "skip vinculo morador->unidade (ja existe)"
fi

if [ "$(qs "select count(*) from colaborador_tipo_chamado where colaborador_id = '$COLABORADOR_ID' and tipo_chamado_id = '$TIPO_ID'")" = "0" ]; then
    expect_302 "colaborador vinculado ao tipo de chamado" \
        "$(post "$OUT/admin.jar" "/admin/colaboradores/$COLABORADOR_ID/tipos-chamado" \
            --data-urlencode "_method=put" \
            --data-urlencode "tipoChamadoId=$TIPO_ID")"
else
    log "skip vinculo colaborador->tipo (ja existe)"
fi

# ------------------------------------------------------------------ chamado do morador
if [ "$(qs "select count(*) from chamados where morador_id = '$MORADOR_ID'")" = "0" ]; then
    morador_login="$(login "$OUT/morador.jar" "$MORADOR_EMAIL" "$SENHA_FIXTURE")"
    expect_302 "morador login" "$morador_login"
    expect_302 "chamado do morador criado" \
        "$(post_multipart "$OUT/morador.jar" /morador/chamados \
            -F "unidadeId=$UNIDADE_ID" \
            -F "tipoChamadoId=$TIPO_ID" \
            -F "descricao=Vazamento no teto da garagem, fixture de baseline do rewrite de UI.")"
else
    log "skip chamado do morador (ja existe)"
fi

# ------------------------------------------------------------------ comentario
# Necessario para que a timeline de interacoes apareca nas 3 telas de detalhe de
# chamado; sem comentario elas rendem empty-state em vez de timeline.
CHAMADO_ID="$(qs "select id from chamados where morador_id = '$MORADOR_ID' order by data_abertura limit 1")"
if [ -n "$CHAMADO_ID" ] && [ "$(qs "select count(*) from comentarios where chamado_id = '$CHAMADO_ID'")" = "0" ]; then
    login "$OUT/morador.jar" "$MORADOR_EMAIL" "$SENHA_FIXTURE" >/dev/null
    expect_302 "comentario do morador criado" \
        "$(post_multipart "$OUT/morador.jar" "/morador/chamados/$CHAMADO_ID/comentarios" \
            -F "mensagem=Comentario da fixture, criado para exercitar a timeline de interacoes.")"
else
    log "skip comentario do morador (ja existe)"
fi

# ------------------------------------------------------------------ reservas
INICIO_1="$(date -d '+2 days 10:00' +%Y-%m-%dT10:00)"
FIM_1="$(date -d '+2 days 12:00' +%Y-%m-%dT12:00)"
INICIO_2="$(date -d '+3 days 14:00' +%Y-%m-%dT14:00)"
FIM_2="$(date -d '+3 days 16:00' +%Y-%m-%dT16:00)"

if [ "$(qs "select count(*) from solicitacoes_area where morador_id = '$MORADOR_ID'")" = "0" ]; then
    login "$OUT/morador.jar" "$MORADOR_EMAIL" "$SENHA_FIXTURE" >/dev/null
    for par in "$INICIO_1|$FIM_1" "$INICIO_2|$FIM_2"; do
        ini="${par%%|*}"; fim="${par##*|}"
        expect_302 "reserva solicitada ($ini)" \
            "$(post "$OUT/morador.jar" /morador/reservas \
                --data-urlencode "unidadeId=$UNIDADE_ID" \
                --data-urlencode "areaId=$AREA_ID" \
                --data-urlencode "inicio=$ini" \
                --data-urlencode "fim=$fim")"
    done
else
    log "skip reservas (ja existem)"
fi

# aprova somente a PRIMEIRA: a segunda fica pendente de proposito, para que a
# disponibilidade mostre CA-01-02 (aprovado x pendente) com estados distintos.
RESERVA_APROVADA="$(qs "select id from solicitacoes_area where morador_id = '$MORADOR_ID' order by inicio limit 1")"
if [ -n "$RESERVA_APROVADA" ] && [ "$(qs "select status from solicitacoes_area where id = '$RESERVA_APROVADA'")" = "Solicitado" ]; then
    login "$OUT/admin.jar" "$ADMIN_EMAIL" "$ADMIN_SENHA" >/dev/null
    expect_302 "reserva aprovada pelo admin" \
        "$(post "$OUT/admin.jar" "/admin/reservas/$RESERVA_APROVADA/aprovacao" --data-urlencode "_method=patch")"
else
    log "skip aprovacao (reserva inexistente ou ja decidida)"
fi

# sessoes finais para a matriz de rotas
login "$OUT/admin.jar" "$ADMIN_EMAIL" "$ADMIN_SENHA" >/dev/null
login "$OUT/morador.jar" "$MORADOR_EMAIL" "$SENHA_FIXTURE" >/dev/null
login "$OUT/colaborador.jar" "$COLABORADOR_EMAIL" "$SENHA_FIXTURE" >/dev/null

# ------------------------------------------------------------------ resumo
{
    echo "blocos=$(qs "select count(*) from blocos")"
    echo "unidades=$(qs "select count(*) from unidades")"
    echo "areas=$(qs "select count(*) from areas")"
    echo "tipos_chamado=$(qs "select count(*) from tipos_chamado")"
    echo "usuarios=$(qs "select count(*) from usuarios")"
    echo "chamados=$(qs "select count(*) from chamados")"
    echo "reservas=$(qs "select count(*) from solicitacoes_area")"
    echo "reservas_aprovadas=$(qs "select count(*) from solicitacoes_area where status='Aprovado'")"
    echo "reservas_pendentes=$(qs "select count(*) from solicitacoes_area where status='Solicitado'")"
} | tee "$OUT/fixture.txt"

log "fixture pronta — sessoes em $OUT/{admin,morador,colaborador}.jar"
