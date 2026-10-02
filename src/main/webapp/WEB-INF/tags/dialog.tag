<%--
    Componente: dialogo central (S28).

    Mesmo componente do `ui:drawer`, com a outra forma: em vez de deslizar da borda,
    aparece CENTRADO na tela, com leve fade e escala. As tres faixas sao as mesmas
    (topo / corpo / rodape); o que muda e o rodape, que aqui serve para CONFIRMAR:

        [ Cancelar (esmaecido) ]   [ Confirmar (primario ou vermelho) ]

    Uso (confirmacao com motivo):
        <ui:dialog id="dialog-negacao" titulo="Negar reserva"
                   descricao="Explique o motivo; ele fica visivel para o morador."
                   acao="${ctx}/admin/reservas" varianteConfirmar="error"
                   iconeConfirmar="negar" rotuloConfirmar="Negar"
                   rotuloCancelar="Voltar">
            <label class="field">
                <span>Motivo</span>
                <input class="input w-full" type="text" name="motivo" maxlength="255" required>
            </label>
        </ui:dialog>

    Uso (confirmacao simples, sem campos): so `titulo`, `descricao` e a acao.

    Atributos: `id` e `titulo` (obrigatorios); `descricao`, `acao`, `metodo` (padrao
    `post`), `tamanho` (`sm`, `md` padrao, `lg`), `rotuloConfirmar` (padrao
    "Confirmar"), `varianteConfirmar` (`primary` padrao, `error` pinta de vermelho),
    `iconeConfirmar` (alias opcional), `rotuloCancelar` (sem ela o rodape so tem o
    botao de confirmar), `aberto`.

    POR BAIXO E O MESMO PROTOCOLO DO `ui:drawer`: os atributos `data-drawer*` e o
    `drawer.js`. Backdrop, Esc, foco preso, trava de scroll, devolucao do foco e o
    conteudo dinamico (`data-drawer-editar` com `data-drawer-acao`) sao o mesmo
    codigo — a forma e so CSS (`.app-dialog`). Um dialogo e um drawer centralizado;
    duplicar o comportamento seria duplicar os bugs.

    Como no drawer, PRECISA ser renderizado fora de `.page-content` (filho direto do
    <body>): la o legado aplica um `width` que espremeria o backdrop.

    Um dialogo so e reaproveitado por varias linhas: o gatilho de cada linha traz a
    acao daquela reserva (`data-drawer-editar` + `data-drawer-acao`), e o
    `reporInicial` limpa o motivo digitado entre uma linha e outra.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ attribute name="id" required="true" description="id do dialogo; tambem nomeia o form interno" %>
<%@ attribute name="titulo" required="true" %>
<%@ attribute name="descricao" required="false" %>
<%@ attribute name="acao" required="false" description="action do form; sem ela o dialogo e so informativo" %>
<%@ attribute name="metodo" required="false" description="method do form (padrao: post)" %>
<%@ attribute name="tamanho" required="false" description="sm, md (padrao) ou lg" %>
<%@ attribute name="rotuloConfirmar" required="false" %>
<%@ attribute name="varianteConfirmar" required="false" description="primary (padrao) ou error" %>
<%@ attribute name="iconeConfirmar" required="false" description="alias de fragments/icone.jspf" %>
<%@ attribute name="rotuloCancelar" required="false" description="botao esmaecido que fecha; sem ele o rodape so confirma" %>
<%@ attribute name="aberto" required="false" description="true abre o dialogo no carregamento" %>

<c:set var="dialogMetodo" value="${empty metodo ? 'post' : metodo}" />
<c:set var="dialogTamanho" value="${empty tamanho ? 'md' : tamanho}" />
<c:set var="dialogConfirmar" value="${empty rotuloConfirmar ? 'Confirmar' : rotuloConfirmar}" />
<c:set var="dialogVariante" value="${varianteConfirmar eq 'error' ? 'btn-error' : 'btn-primary'}" />
<c:set var="dialogFormId" value="${id}-form" />
<c:set var="dialogAberto" value="${aberto eq 'true' ? 'data-drawer-aberto' : ''}" />

<%-- Backdrop IRMAO do painel, nunca filho: o painel cria containing block e um backdrop
     `fixed` dentro dele se posicionaria pelo painel. --%>
<div id="${id}-backdrop" class="app-drawer-backdrop" data-drawer-backdrop="${id}" ${dialogAberto}></div>

<aside id="${id}"
       class="app-dialog app-dialog--${dialogTamanho}"
       role="dialog" aria-modal="true" aria-labelledby="${id}-titulo"
       data-drawer ${dialogAberto}>
    <header class="app-dialog-topo">
        <div class="grid gap-1">
            <h2 id="${id}-titulo" data-drawer-titulo class="font-display text-lg font-semibold">${titulo}</h2>
            <c:if test="${not empty descricao}">
                <p class="text-sm opacity-70">${descricao}</p>
            </c:if>
        </div>

        <button type="button" class="btn btn-sm btn-circle btn-ghost -mt-1 -mr-1"
                aria-label="Fechar" data-drawer-fechar>
            <c:set var="icone" value="fechar" />
            <c:set var="iconeClasse" value="size-4" />
            <%@ include file="/WEB-INF/jsp/fragments/icone.jspf" %>
        </button>
    </header>

    <c:choose>
        <c:when test="${not empty acao}">
            <form id="${dialogFormId}" data-drawer-form method="${dialogMetodo}" action="${acao}" class="app-dialog-corpo">
                <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                <%-- Vazio = POST. O gatilho da linha troca por `patch`/`delete` conforme
                     a acao (negar e cancelar mandam `_method`). --%>
                <input type="hidden" name="_method" value="">
                <jsp:doBody />
            </form>
        </c:when>
        <c:otherwise>
            <div class="app-dialog-corpo">
                <jsp:doBody />
            </div>
        </c:otherwise>
    </c:choose>

    <%-- Rodape de confirmacao. Fechar sem decidir e o botao esmaecido, o X do topo, o Esc
         ou o clique fora — a decisao e sempre o botao da direita. --%>
    <c:if test="${not empty acao}">
        <footer class="app-dialog-rodape">
            <c:if test="${not empty rotuloCancelar}">
                <button type="button" class="btn btn-ghost" data-drawer-fechar>${rotuloCancelar}</button>
            </c:if>
            <button type="submit" form="${dialogFormId}" class="btn ${dialogVariante}">
                <c:if test="${not empty iconeConfirmar}">
                    <c:set var="icone" value="${iconeConfirmar}" />
                    <c:set var="iconeClasse" value="size-4" />
                    <%@ include file="/WEB-INF/jsp/fragments/icone.jspf" %>
                </c:if>
                ${dialogConfirmar}
            </button>
        </footer>
    </c:if>
</aside>
