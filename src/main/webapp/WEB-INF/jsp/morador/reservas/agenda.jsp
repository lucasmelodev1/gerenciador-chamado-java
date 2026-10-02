<%@ page pageEncoding="UTF-8" %>
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
            <c:set var="agendaEyebrow" value="Áreas comuns" />
            <c:set var="agendaTitulo" value="Minha agenda" />
            <%@ include file="/WEB-INF/jsp/fragments/reservas-agenda.jspf" %>
        </main>
    </div>
</div>

<%-- Fora de `.page-content`: o detalhe e o dialogo sao `position: fixed`. --%>
<%@ include file="/WEB-INF/jsp/fragments/reservas-agenda-paineis.jspf" %>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
