<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-reservas-agenda">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <c:set var="agendaModo" value="admin" />
            <c:set var="agendaBase" value="${ctx}/admin/reservas" />
            <c:set var="agendaEyebrow" value="Agenda unica" />
            <c:set var="agendaTitulo" value="Calendario de reservas" />
            <%@ include file="/WEB-INF/jsp/fragments/reservas-agenda.jspf" %>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
