<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="morador-reservas-agenda">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <c:set var="agendaModo" value="morador" />
            <c:set var="agendaBase" value="${ctx}/morador/reservas" />
            <c:set var="agendaEyebrow" value="Areas comuns" />
            <c:set var="agendaTitulo" value="Minha agenda" />
            <%@ include file="/WEB-INF/jsp/fragments/reservas-agenda.jspf" %>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
