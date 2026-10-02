<%--
    Componente: acao de linha que ABRE UM PAINEL ja preenchido (S25, tag em S26; renomeado
    na S32).

    Chama-se `acao-painel` porque o protocolo e o do gatilho de editar (`data-drawer-editar`
    + `data-drawer-acao` + campos), nao o "editar": em reservas ele abre o dialogo de negacao
    e o de cancelamento, que nao sao edicao de registro nenhum.

    Uso (editar registro no drawer):
        <ui:acao-painel painel="drawer-area" titulo="Editar area"
                        acao="${ctx}/admin/areas/${area.id}">
            <input type="hidden" data-campo="nome" value="${fn:escapeXml(area.nome)}">
            <input type="hidden" data-campo="status" value="${fn:escapeXml(area.status)}">
        </ui:acao-painel>

    Uso (abrir o dialogo de negacao de uma reserva):
        <ui:acao-painel painel="dialog-negacao" titulo="Negar reserva"
                        acao="${ctx}/admin/reservas/${reserva.id}/negacao"
                        icone="negar" rotulo="Negar" />

    O corpo lista os campos do painel na forma `<input data-campo="<name>" value="...">`.
    Isso substitui o formato antigo (`data-campo-<name>` no proprio botao): os valores sao
    dados de usuario — um nome com `;` ou `|` corromperia qualquer codificacao em string — e
    como `value` de um input eles passam pelo escape normal do HTML, com quantos campos forem
    necessarios. O `drawer.js` le as duas formas.

    O `_method` e implicito: o painel renderiza o campo vazio (POST) e este gatilho o
    preenche com `metodo` (padrao `patch`).
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="ui" tagdir="/WEB-INF/tags" %>
<%@ attribute name="painel" required="true" description="id do ui:drawer/ui:dialog que este gatilho abre" %>
<%@ attribute name="titulo" required="true" description="titulo que o painel assume quando abre" %>
<%@ attribute name="acao" required="true" description="action do form do painel" %>
<%@ attribute name="metodo" required="false" description="valor de _method (padrao: patch)" %>
<%@ attribute name="rotulo" required="false" description="tooltip e nome acessivel (padrao: Editar)" %>
<%@ attribute name="icone" required="false" description="alias do icone (padrao: editar)" %>

<c:set var="painelRotulo" value="${empty rotulo ? 'Editar' : rotulo}" />
<c:set var="painelMetodo" value="${empty metodo ? 'patch' : metodo}" />
<c:set var="painelIcone" value="${empty icone ? 'editar' : icone}" />

<button type="button" class="btn btn-ghost btn-sm btn-square tooltip"
        data-tip="${painelRotulo}" aria-label="${painelRotulo}"
        data-drawer-editar="${painel}"
        data-drawer-titulo="${titulo}"
        data-drawer-acao="${acao}">
    <input type="hidden" data-campo="_method" value="${painelMetodo}">
    <jsp:doBody />
    <ui:icone nome="${painelIcone}" />
</button>
