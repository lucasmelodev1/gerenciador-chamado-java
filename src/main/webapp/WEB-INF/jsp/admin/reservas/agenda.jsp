<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="admin-reservas-agenda">

            <c:set var="agendaModo" value="admin" />
            <c:set var="agendaBase" value="${ctx}/admin/reservas" />
            <c:set var="agendaEyebrow" value="Agenda única" />
            <c:set var="agendaTitulo" value="Calendário de reservas" />
            <%@ include file="/WEB-INF/jsp/fragments/reservas-agenda.jspf" %>
</ui:shell>

<%-- Fora de `.app-page`: o detalhe e o dialogo sao `position: fixed`. --%>
<%@ include file="/WEB-INF/jsp/fragments/reservas-agenda-paineis.jspf" %>
<ui:shell-fim />
