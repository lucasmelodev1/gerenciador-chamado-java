<%--
    Componente: acao de linha que abre o drawer de edicao ja preenchido (S25, tag em S26).

    Uso:
        <ui:acao-editar drawer="drawer-area" titulo="Editar area"
                        acao="${ctx}/admin/areas/${area.id}">
            <input type="hidden" data-campo="nome" value="${fn:escapeXml(area.nome)}">
            <input type="hidden" data-campo="status" value="${fn:escapeXml(area.status)}">
        </ui:acao-editar>

    O corpo lista os campos do drawer na forma `<input data-campo="<name>" value="...">`.
    Isso substitui o formato antigo (`data-campo-<name>` no proprio botao): os valores
    sao dados de usuario — um nome com `;` ou `|` corromperia qualquer codificacao em
    string — e como `value` de um input eles passam pelo escape normal do HTML, com
    quantos campos forem necessarios. O `drawer.js` le as duas formas.

    O `_method` e implicito: o drawer renderiza o campo vazio (POST) e este gatilho o
    preenche com `metodo` (padrao `patch`).
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ attribute name="drawer" required="true" description="id do ui:drawer que este gatilho abre" %>
<%@ attribute name="titulo" required="true" description="titulo que o drawer assume no modo edicao" %>
<%@ attribute name="acao" required="true" description="action do form no modo edicao" %>
<%@ attribute name="metodo" required="false" description="valor de _method (padrao: patch)" %>
<%@ attribute name="rotulo" required="false" description="tooltip e nome acessivel (padrao: Editar)" %>
<%@ attribute name="icone" required="false" description="alias do icone (padrao: editar)" %>

<c:set var="editarRotulo" value="${empty rotulo ? 'Editar' : rotulo}" />
<c:set var="editarMetodo" value="${empty metodo ? 'patch' : metodo}" />
<c:set var="editarIcone" value="${empty icone ? 'editar' : icone}" />

<button type="button" class="btn btn-ghost btn-sm btn-square tooltip"
        data-tip="${editarRotulo}" aria-label="${editarRotulo}"
        data-drawer-editar="${drawer}"
        data-drawer-titulo="${titulo}"
        data-drawer-acao="${acao}">
    <input type="hidden" data-campo="_method" value="${editarMetodo}">
    <jsp:doBody />
    <c:set var="icone" value="${editarIcone}" />
    <c:set var="iconeClasse" value="size-4" />
    <%@ include file="/WEB-INF/jsp/fragments/icone.jspf" %>
</button>
