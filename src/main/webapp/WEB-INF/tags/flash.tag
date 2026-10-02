<%--
    Componente: mensagens de flash pos-redirect (S31).

    Substitui o include `fragments/alerts.jspf`. O include carregava um `<%@ page
    pageEncoding="UTF-8" %>` (por causa do `×` do botao de fechar) e a diretiva `page` NAO
    pode viver num arquivo incluido por um tag file — foi o que quebrou o `ui:shell` na
    primeira versao. Como tag, o encoding vem do `<%@ tag pageEncoding %>`.

    Variaveis lidas do model (RedirectAttributes): `successMessage` e `errorMessage`.
    Os hooks de `static/js/alerts.js` seguem os mesmos: `[data-alert]` e
    `[data-dismiss-alert]`.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<c:if test="${not empty successMessage}">
    <div role="alert" class="alert alert-success" data-alert>
        <span>${successMessage}</span>
        <button type="button" class="btn btn-sm btn-ghost" data-dismiss-alert aria-label="Fechar">×</button>
    </div>
</c:if>
<c:if test="${not empty errorMessage}">
    <div role="alert" class="alert alert-error" data-alert>
        <span>${errorMessage}</span>
        <button type="button" class="btn btn-sm btn-ghost" data-dismiss-alert aria-label="Fechar">×</button>
    </div>
</c:if>
