<%--
    Componente: drawer lateral (S23).

    Painel que desliza da borda, em tres faixas:
        topo   -> titulo + descricao (+ botao X)
        meio   -> <jsp:doBody/>, o slot livre
        rodape -> Salvar (drawer de formulario) ou Fechar + a acao declarada (informativo)

    Duas formas, decididas por `acao`:

      - COM `acao`: e um formulario. O corpo fica dentro do <form> e o rodape so tem o
        Salvar. Fechar e o X do topo, o Esc e o clique fora (nao ha botao "Fechar").
      - SEM `acao`: e um painel INFORMATIVO (um detalhe, por exemplo). Nao ha formulario e
        o rodape passa a ter o botao **Fechar**; `rotuloAcao` acrescenta um segundo botao a
        esquerda, que pode abrir outro painel (ver `painelAcao`/`metodoAcao` abaixo).

    Uso:
        <ui:drawer id="drawer-area" titulo="Nova area"
                   descricao="Cadastre um espaco do condominio."
                   acao="${ctx}/admin/areas" rotuloSalvar="Cadastrar">
            <label class="field">
                <span>Nome</span>
                <input class="input w-full" name="nome" required>
            </label>
        </ui:drawer>

    NAO e um <dialog>: sao dois <div> irmaos (backdrop + painel) animados por
    `translate`. Motivo em baseline/EVIDENCE.md > S23, resumo:

      1. `<dialog class="modal">` da daisyUI nao tem `::backdrop` (a daisyUI usa
         `display:none` nele e pinta o proprio elemento) e o legado
         `.page-content > * { width: min(100%, 1360px) }` espremia o escurecimento,
         deixando as bordas da tela claras;
      2. aqui o backdrop e um elemento proprio, `position: fixed; inset: 0`.

    POR ISSO O COMPONENTE PRECISA SER RENDERIZADO FORA DE `.page-content` — como
    filho direto do <body>. Dentro de `.page-content` ele herda aquele
    `width: min(100%, 1360px)` e o `margin-inline: auto` do legado, que nao estao em
    cascade layer e portanto vencem qualquer utilitario.

    Abrir e fechar (ver static/js/drawer.js):
        <button data-drawer-abrir="drawer-area">Nova area</button>
        AppDrawer.abrir("drawer-area") / AppDrawer.fechar("drawer-area")
        atributo `aberto="true"` abre assim que a pagina carrega (render do servidor)

    Ao fechar (X, Fechar, Esc ou clique fora) o painel reemite `drawer:fechado` no
    proprio elemento, com `detail = { id, valor }`:
        document.addEventListener("drawer:fechado", function (e) { ... e.detail.id ... });

    O corpo fica DENTRO do <form> e o botao Salvar do rodape fica FORA, referenciando-o
    por `form="<id>-form"` — mesma tecnica do logout na lateral.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="ui" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ attribute name="id" required="true" description="id do painel; tambem nomeia o form interno" %>
<%@ attribute name="titulo" required="true" %>
<%@ attribute name="descricao" required="false" %>
<%@ attribute name="acao" required="false" description="action do form; sem ela o drawer e informativo e nao mostra Salvar" %>
<%@ attribute name="metodo" required="false" description="method do form (padrao: post)" %>
<%@ attribute name="tamanho" required="false" description="sm (padrao, estreito), md ou lg" %>
<%@ attribute name="lado" required="false" description="end (padrao, direita) ou start (esquerda)" %>
<%@ attribute name="rotuloSalvar" required="false" %>
<%@ attribute name="rotuloFechar" required="false" %>
<%@ attribute name="aberto" required="false" description="true abre o drawer no carregamento" %>
<%@ attribute name="travar" required="false" description="campos separados por virgula que a EDICAO nao pode mudar; a criacao pode" %>
<%@ attribute name="rotuloAcao" required="false" description="segundo botao do rodape do drawer informativo (a esquerda do Fechar)" %>
<%@ attribute name="iconeAcao" required="false" description="alias de ui:icone para o botao da acao" %>
<%@ attribute name="varianteAcao" required="false" description="primary (padrao) ou error (vermelho)" %>
<%@ attribute name="painelAcao" required="false" description="id do painel que a acao abre (protocolo data-drawer-editar)" %>
<%@ attribute name="metodoAcao" required="false" description="valor de _method que o painel aberto recebe (ex.: delete)" %>

<c:set var="drawerMetodo" value="${empty metodo ? 'post' : metodo}" />
<c:set var="drawerTamanho" value="${empty tamanho ? 'sm' : tamanho}" />
<c:set var="drawerLado" value="${empty lado ? 'end' : lado}" />
<c:set var="drawerSalvar" value="${empty rotuloSalvar ? 'Salvar' : rotuloSalvar}" />
<c:set var="drawerFechar" value="${empty rotuloFechar ? 'Fechar' : rotuloFechar}" />
<c:set var="drawerVarianteAcao" value="${varianteAcao eq 'error' ? 'btn-error' : 'btn-primary'}" />
<c:set var="drawerFormId" value="${id}-form" />
<c:set var="drawerAberto" value="${aberto eq 'true' ? 'data-drawer-aberto' : ''}" />

<%-- Backdrop IRMAO do painel, nunca filho: o painel tem `translate`, ou seja cria
     containing block, e um backdrop `fixed` dentro dele se posicionaria pelo painel. --%>
<div id="${id}-backdrop" class="app-drawer-backdrop" data-drawer-backdrop="${id}" ${drawerAberto}></div>

<aside id="${id}"
       class="app-drawer app-drawer--${drawerTamanho} app-drawer--${drawerLado}"
       role="dialog" aria-modal="true" aria-labelledby="${id}-titulo"
       data-drawer ${drawerAberto}>
    <header class="app-drawer-topo">
        <div class="grid gap-1">
            <h2 id="${id}-titulo" data-drawer-titulo class="font-display text-lg font-semibold">${titulo}</h2>
            <c:if test="${not empty descricao}">
                <p class="text-sm opacity-70">${descricao}</p>
            </c:if>
        </div>

        <button type="button" class="btn btn-sm btn-circle btn-ghost -mt-1 -mr-1"
                aria-label="${drawerFechar}" data-drawer-fechar>
            <ui:icone nome="fechar" />
        </button>
    </header>

    <c:choose>
        <c:when test="${not empty acao}">
            <form id="${drawerFormId}" data-drawer-form method="${drawerMetodo}" action="${acao}"
                  class="app-drawer-corpo"<c:if test="${not empty travar}"> data-drawer-travar="${travar}"</c:if>>
                <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                <%-- Sobrescrita de metodo para o caso de edicao: o drawer.js preenche a
                     partir de `data-campo-_method` do gatilho. Vazio = POST (o
                     HiddenHttpMethodFilter ignora parametro sem valor). --%>
                <input type="hidden" name="_method" value="">
                <%-- Espelho de cada campo travado. Os dois nascem no HTML com o MESMO
                     `name` e so um fica habilitado por vez: no modo criacao o espelho
                     esta `disabled` (e o controle visivel e que envia); no modo edicao o
                     drawer.js desabilita o controle visivel e habilita o espelho, porque
                     campo `disabled` nao e enviado. Ver drawer.js > alternarTravados. --%>
                <c:forEach items="${fn:split(travar, ',')}" var="campoTravado">
                    <c:if test="${not empty campoTravado}">
                        <input type="hidden" name="${campoTravado}" data-drawer-espelho="${campoTravado}" disabled>
                    </c:if>
                </c:forEach>
                <jsp:doBody />
            </form>
        </c:when>
        <c:otherwise>
            <div class="app-drawer-corpo">
                <jsp:doBody />
            </div>
        </c:otherwise>
    </c:choose>

    <%-- Rodape. No drawer de FORMULARIO e so o Salvar: fechar fica por conta do X no topo,
         do Esc e do clique fora. No drawer INFORMATIVO (sem `acao`) o rodape traz o Fechar
         — e, quando `rotuloAcao` e informado, um segundo botao a esquerda, que pode abrir
         outro painel pelo mesmo protocolo do gatilho de editar (`data-drawer-editar`). --%>
    <c:choose>
        <c:when test="${not empty acao}">
            <footer class="app-drawer-rodape">
                <button type="submit" form="${drawerFormId}" class="btn btn-primary">
                    <ui:icone nome="salvar" />
                    ${drawerSalvar}
                </button>
            </footer>
        </c:when>
        <c:otherwise>
            <footer class="app-drawer-rodape">
                <c:if test="${not empty rotuloAcao}">
                    <button type="button" class="btn ${drawerVarianteAcao}"<c:if test="${not empty painelAcao}"> data-drawer-editar="${painelAcao}"</c:if><c:if test="${not empty metodoAcao}"> data-campo-_method="${metodoAcao}"</c:if>>
                        <c:if test="${not empty iconeAcao}">
                            <ui:icone nome="${iconeAcao}" />
                        </c:if>
                        ${rotuloAcao}
                    </button>
                </c:if>
                <button type="button" class="btn" data-drawer-fechar>${drawerFechar}</button>
            </footer>
        </c:otherwise>
    </c:choose>
</aside>
