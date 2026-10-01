<%--
    Componente: acao de linha que ENVIA um formulario, so com icone + tooltip
    (S25, tag em S26).

    Uso (remocao, o caso comum):
        <ui:acao-form acao="${ctx}/admin/areas/${area.id}" icone="remover" rotulo="Remover"
                      perigo="true"
                      confirmacao="Remover esta area? As reservas existentes serao preservadas." />

    Uso (acao neutra que nao e remocao, ex.: definir status inicial padrao):
        <ui:acao-form acao="${ctx}/admin/status-chamado/${status.id}/inicial-padrao"
                      metodo="patch" icone="padrao" rotulo="Tornar padrao"
                      confirmacao="Definir este status como inicial padrao?" />

    Atributos:
        acao        action do form
        rotulo      texto do tooltip e nome acessivel
        icone       alias de fragments/icone.jspf
        metodo      valor de `_method` (padrao: delete)
        confirmacao texto do `data-confirm`; sem ela o envio nao pede confirmacao
        perigo      `true` pinta o icone com a cor de erro (padrao: false)

    O corpo (opcional) entra no form antes do botao — e onde vao campos escondidos
    extras, como o `blocoId` de algumas remocoes.

    `data-confirm` e tratado por `static/js/forms.js`; `_method` por
    `HiddenHttpMethodFilter` (o prefixo `_` e o que marca o campo como sobrescrita de
    metodo, e nao um campo do formulario).
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ attribute name="acao" required="true" %>
<%@ attribute name="rotulo" required="true" description="texto do tooltip e nome acessivel" %>
<%@ attribute name="icone" required="true" description="alias de fragments/icone.jspf" %>
<%@ attribute name="metodo" required="false" description="valor de _method (padrao: delete)" %>
<%@ attribute name="confirmacao" required="false" description="texto do data-confirm; sem ela nao ha confirmacao" %>
<%@ attribute name="perigo" required="false" description="true pinta o icone com a cor de erro" %>

<c:set var="acaoFormMetodo" value="${empty metodo ? 'delete' : metodo}" />
<c:set var="acaoFormClasse" value="btn btn-ghost btn-sm btn-square${perigo eq 'true' ? ' app-btn-perigo' : ''} tooltip" />

<form method="post" action="${acao}"<c:if test="${not empty confirmacao}"> data-confirm="${confirmacao}"</c:if>>
    <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
    <input type="hidden" name="_method" value="${acaoFormMetodo}">
    <jsp:doBody />
    <button type="submit" class="${acaoFormClasse}" data-tip="${rotulo}" aria-label="${rotulo}">
        <c:set var="iconeClasse" value="size-4" />
        <%@ include file="/WEB-INF/jsp/fragments/icone.jspf" %>
    </button>
</form>
