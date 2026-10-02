<%--
    Componente: painel modal (S31) — a implementacao unica do `ui:drawer` e do `ui:dialog`.

    Os dois tags emitiam o mesmo esqueleto: backdrop irmao, `<aside role="dialog">` com topo
    (titulo, descricao, X), corpo (form com csrf + `_method` quando ha `acao`) e rodape. O que
    muda e a FORMA (classe do painel e do rodape) e o rodape em si: o drawer salva, o dialogo
    confirma. Aqui isso e decidido por `forma`; `drawer.tag` e `dialog.tag` viraram cascas
    finas que so encaminham os atributos, para nao mexer nas telas.

    Nao e um <dialog> do HTML: sao dois elementos irmaos (backdrop + painel) animados por
    `translate`/fade. Motivo em baseline/EVIDENCE.md > S23.

    POR ISSO PRECISA SER RENDERIZADO FORA DE `.page-content` — como filho direto do <body>.
    Dentro de `.page-content` o legado aplica `width: min(100%, 1360px)` e `margin-inline:
    auto`, que nao estao em cascade layer e venceriam qualquer utilitario.

    O comportamento e o do `static/js/drawer.js`: `data-drawer-abrir`, `data-drawer-editar`,
    `data-drawer-fechar`, `data-drawer-backdrop`, `data-drawer-form`, `data-drawer-titulo`,
    `data-drawer-travar` e o evento `drawer:fechado`.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="ui" tagdir="/WEB-INF/tags" %>
<%@ attribute name="forma" required="true" description="drawer (desliza da borda) ou dialog (centralizado)" %>
<%@ attribute name="id" required="true" description="id do painel; tambem nomeia o form interno" %>
<%@ attribute name="titulo" required="true" %>
<%@ attribute name="descricao" required="false" %>
<%@ attribute name="acao" required="false" description="action do form; sem ela o painel e informativo" %>
<%@ attribute name="metodo" required="false" description="method do form (padrao: post)" %>
<%@ attribute name="tamanho" required="false" description="drawer: sm (padrao)/md/lg; dialog: sm/md (padrao)/lg" %>
<%@ attribute name="lado" required="false" description="so no drawer: end (padrao) ou start" %>
<%@ attribute name="aberto" required="false" description="true abre no carregamento" %>
<%@ attribute name="travar" required="false" description="so no drawer: campos que a EDICAO nao pode mudar" %>
<%@ attribute name="rotuloSalvar" required="false" description="so no drawer de formulario (padrao: Salvar)" %>
<%@ attribute name="rotuloFechar" required="false" description="aria-label do X e rotulo do Fechar informativo" %>
<%@ attribute name="rotuloAcao" required="false" description="so no drawer informativo: segundo botao do rodape" %>
<%@ attribute name="iconeAcao" required="false" description="alias de ui:icone para o botao da acao" %>
<%@ attribute name="varianteAcao" required="false" description="primary (padrao) ou error" %>
<%@ attribute name="painelAcao" required="false" description="id do painel que a acao abre (protocolo data-drawer-editar)" %>
<%@ attribute name="metodoAcao" required="false" description="valor de _method que o painel aberto recebe (ex.: delete)" %>
<%@ attribute name="rotuloConfirmar" required="false" description="so no dialogo (padrao: Confirmar)" %>
<%@ attribute name="varianteConfirmar" required="false" description="primary (padrao) ou error" %>
<%@ attribute name="iconeConfirmar" required="false" description="alias de ui:icone do botao de confirmar" %>
<%@ attribute name="rotuloCancelar" required="false" description="so no dialogo: botao esmaecido que fecha" %>

<c:set var="ehDialogo" value="${forma eq 'dialog'}" />
<c:set var="painelMetodo" value="${empty metodo ? 'post' : metodo}" />
<c:set var="painelTamanho" value="${empty tamanho ? (ehDialogo ? 'md' : 'sm') : tamanho}" />
<c:set var="painelLado" value="${empty lado ? 'end' : lado}" />
<c:set var="painelFormId" value="${id}-form" />
<c:set var="painelAbertoAttr" value="${aberto eq 'true' ? 'data-drawer-aberto' : ''}" />
<c:set var="painelFechar" value="${empty rotuloFechar ? 'Fechar' : rotuloFechar}" />
<c:set var="painelSalvar" value="${empty rotuloSalvar ? 'Salvar' : rotuloSalvar}" />
<c:set var="painelConfirmar" value="${empty rotuloConfirmar ? 'Confirmar' : rotuloConfirmar}" />
<c:set var="painelVarianteAcao" value="${varianteAcao eq 'error' ? 'btn-error' : 'btn-primary'}" />
<c:set var="painelVarianteConfirmar" value="${varianteConfirmar eq 'error' ? 'btn-error' : 'btn-primary'}" />

<c:choose>
    <c:when test="${ehDialogo}">
        <c:set var="painelClasse" value="app-dialog app-dialog--${painelTamanho}" />
        <c:set var="painelTopoClasse" value="app-dialog-topo" />
        <c:set var="painelRodapeClasse" value="app-dialog-rodape" />
    </c:when>
    <c:otherwise>
        <c:set var="painelClasse" value="app-drawer app-drawer--${painelTamanho} app-drawer--${painelLado}" />
        <c:set var="painelTopoClasse" value="app-drawer-topo" />
        <c:set var="painelRodapeClasse" value="app-drawer-rodape" />
    </c:otherwise>
</c:choose>

<%-- O corpo e capturado para dois usos: emitido depois (o form fica em volta dele) e, no
     dialogo, para saber se ha conteudo — uma confirmacao pura nao pode renderizar a faixa
     do corpo vazia. --%>
<jsp:doBody var="painelCorpo" />
<c:set var="painelTemCorpo" value="${not empty fn:trim(painelCorpo)}" />

<%-- Backdrop IRMAO do painel, nunca filho: o painel tem `translate` (drawer) e cria
     containing block; um backdrop `fixed` dentro dele se posicionaria pelo painel. --%>
<div id="${id}-backdrop" class="app-drawer-backdrop" data-drawer-backdrop="${id}" ${painelAbertoAttr}></div>

<aside id="${id}"
       class="${painelClasse}"
       role="dialog" aria-modal="true" aria-labelledby="${id}-titulo"
       data-drawer ${painelAbertoAttr}>
    <header class="${painelTopoClasse}">
        <div class="grid gap-1">
            <h2 id="${id}-titulo" data-drawer-titulo class="font-display text-lg font-semibold">${titulo}</h2>
            <c:if test="${not empty descricao}">
                <p class="text-sm opacity-70">${descricao}</p>
            </c:if>
        </div>

        <button type="button" class="btn btn-sm btn-circle btn-ghost -mt-1 -mr-1"
                aria-label="${painelFechar}" data-drawer-fechar>
            <ui:icone nome="fechar" />
        </button>
    </header>

    <c:choose>
        <c:when test="${not empty acao}">
            <form id="${painelFormId}" data-drawer-form method="${painelMetodo}" action="${acao}"
                  class="${ehDialogo ? 'app-dialog-corpo' : 'app-drawer-corpo'}${ehDialogo and not painelTemCorpo ? ' app-dialog-corpo--vazio' : ''}"<c:if test="${not ehDialogo and not empty travar}"> data-drawer-travar="${travar}"</c:if>>
                <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                <%-- Sobrescrita de metodo para o caso de edicao: o drawer.js preenche a
                     partir de `data-campo-_method` do gatilho. Vazio = POST (o
                     HiddenHttpMethodFilter ignora parametro sem valor). --%>
                <input type="hidden" name="_method" value="">
                <%-- Espelho de cada campo travado. Os dois nascem no HTML com o MESMO `name`
                     e so um fica habilitado por vez: na criacao o espelho esta `disabled` (o
                     controle visivel e que envia); na edicao o drawer.js desabilita o
                     controle visivel e habilita o espelho, porque campo `disabled` nao e
                     enviado. Ver drawer.js > alternarTravados. --%>
                <c:if test="${not ehDialogo}">
                    <c:forEach items="${fn:split(travar, ',')}" var="campoTravado">
                        <c:if test="${not empty campoTravado}">
                            <input type="hidden" name="${campoTravado}" data-drawer-espelho="${campoTravado}" disabled>
                        </c:if>
                    </c:forEach>
                </c:if>
                ${painelCorpo}
            </form>
        </c:when>
        <c:when test="${ehDialogo}">
            <c:if test="${painelTemCorpo}">
                <div class="app-dialog-corpo">${painelCorpo}</div>
            </c:if>
        </c:when>
        <c:otherwise>
            <div class="app-drawer-corpo">${painelCorpo}</div>
        </c:otherwise>
    </c:choose>

    <%-- Rodape. No DRAWER de formulario e so o Salvar (fechar e o X, o Esc e o clique fora);
         no DRAWER informativo vem o Fechar e, com `rotuloAcao`, um segundo botao a esquerda
         que pode abrir outro painel pelo protocolo `data-drawer-editar`. No DIALOGO o rodape
         confirma: Cancelar (esmaecido) + Confirmar. --%>
    <c:choose>
        <c:when test="${ehDialogo}">
            <c:if test="${not empty acao}">
                <footer class="${painelRodapeClasse}">
                    <c:if test="${not empty rotuloCancelar}">
                        <button type="button" class="btn btn-ghost" data-drawer-fechar>${rotuloCancelar}</button>
                    </c:if>
                    <button type="submit" form="${painelFormId}" class="btn ${painelVarianteConfirmar}">
                        <c:if test="${not empty iconeConfirmar}">
                            <ui:icone nome="${iconeConfirmar}" />
                        </c:if>
                        ${painelConfirmar}
                    </button>
                </footer>
            </c:if>
        </c:when>
        <c:when test="${not empty acao}">
            <footer class="${painelRodapeClasse}">
                <button type="submit" form="${painelFormId}" class="btn btn-primary">
                    <ui:icone nome="salvar" />
                    ${painelSalvar}
                </button>
            </footer>
        </c:when>
        <c:otherwise>
            <footer class="${painelRodapeClasse}">
                <c:if test="${not empty rotuloAcao}">
                    <button type="button" class="btn ${painelVarianteAcao}"<c:if test="${not empty painelAcao}"> data-drawer-editar="${painelAcao}"</c:if><c:if test="${not empty metodoAcao}"> data-campo-_method="${metodoAcao}"</c:if>>
                        <c:if test="${not empty iconeAcao}">
                            <ui:icone nome="${iconeAcao}" />
                        </c:if>
                        ${rotuloAcao}
                    </button>
                </c:if>
                <button type="button" class="btn" data-drawer-fechar>${painelFechar}</button>
            </footer>
        </c:otherwise>
    </c:choose>
</aside>
