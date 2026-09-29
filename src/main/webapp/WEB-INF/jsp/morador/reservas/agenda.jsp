<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="morador-reservas-agenda">
<div class="app-shell">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="app-main">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main class="page-content">
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
