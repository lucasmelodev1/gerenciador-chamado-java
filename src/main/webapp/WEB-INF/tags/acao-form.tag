<%--
    Componente: acao que ENVIA um formulario (S25, tag em S26; modo texto em S31).

    Uso (acao de linha, so icone + tooltip — o formato das tabelas):
        <ui:acao-form acao="${ctx}/admin/areas/${area.id}" icone="remover" rotulo="Remover"
                      perigo="true"
                      confirmacao="Remover esta area? As reservas existentes serao preservadas." />

    Uso (acao neutra que nao e remocao, ex.: definir status inicial padrao):
        <ui:acao-form acao="${ctx}/admin/status-chamado/${status.id}/inicial-padrao"
                      metodo="patch" icone="padrao" rotulo="Tornar padrao"
                      confirmacao="Definir este status como inicial padrao?" />

    Uso (botao com texto visivel, o formato que as telas escreviam a mao):
        <ui:acao-form acao="${ctx}/morador/reservas/${reserva.id}" texto="Cancelar"
                      variante="link" confirmacao="Cancelar esta reserva?" />
        <ui:acao-form acao="${ctx}/admin/usuarios/${usuario.id}" texto="Remover usuario"
                      variante="error" classe="flex flex-wrap items-center gap-3 mt-5"
                      confirmacao="Remover este usuario? A acao nao pode ser desfeita." />

    Atributos:
        acao        action do form
        texto       rotulo visivel; ativa o modo texto (sem ele, sai o icone + tooltip)
        variante    classe do botao no modo texto: link (padrao), error ou primary
        classe      classe extra do <form> (ex.: `inline-form`, `danger-zone`)
        rotulo      texto do tooltip e nome acessivel (modo icone)
        icone       alias de ui:icone (modo icone)
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
<%@ taglib prefix="ui" tagdir="/WEB-INF/tags" %>
<%@ attribute name="acao" required="true" %>
<%@ attribute name="texto" required="false" description="rotulo visivel; ativa o modo texto" %>
<%@ attribute name="variante" required="false" description="link (padrao), error ou primary — so no modo texto" %>
<%@ attribute name="classe" required="false" description="classe extra do form" %>
<%@ attribute name="rotulo" required="false" description="texto do tooltip e nome acessivel (modo icone)" %>
<%@ attribute name="icone" required="false" description="alias de ui:icone (modo icone)" %>
<%@ attribute name="metodo" required="false" description="valor de _method (padrao: delete)" %>
<%@ attribute name="confirmacao" required="false" description="texto do data-confirm; sem ela nao ha confirmacao" %>
<%@ attribute name="perigo" required="false" description="true pinta o icone com a cor de erro" %>

<c:set var="acaoFormMetodo" value="${empty metodo ? 'delete' : metodo}" />
<c:set var="acaoFormClasse" value="btn btn-ghost btn-sm btn-square${perigo eq 'true' ? ' app-btn-perigo' : ''} tooltip" />
<c:set var="acaoFormTextoClasse" value="btn ${variante eq 'error' ? 'btn-error' : variante eq 'primary' ? 'btn-primary' : 'btn-link'}" />

<form method="post" action="${acao}"<c:if test="${not empty classe}"> class="${classe}"</c:if><c:if test="${not empty confirmacao}"> data-confirm="${confirmacao}"</c:if>>
    <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
    <input type="hidden" name="_method" value="${acaoFormMetodo}">
    <jsp:doBody />
    <c:choose>
        <c:when test="${not empty texto}">
            <button type="submit" class="${acaoFormTextoClasse}">${texto}</button>
        </c:when>
        <c:otherwise>
            <button type="submit" class="${acaoFormClasse}" data-tip="${rotulo}" aria-label="${rotulo}">
                <ui:icone nome="${icone}" />
            </button>
        </c:otherwise>
    </c:choose>
</form>
