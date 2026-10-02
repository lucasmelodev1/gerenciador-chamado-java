<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="morador-reservas-agenda">

            <c:set var="agendaModo" value="morador" />
            <c:set var="agendaBase" value="${ctx}/morador/reservas" />
            <c:set var="agendaEyebrow" value="Áreas comuns" />
            <c:set var="agendaTitulo" value="Minha agenda" />
            <%@ include file="/WEB-INF/jsp/fragments/reservas-agenda.jspf" %>
</ui:shell>

<%-- Fora de `.page-content`: o detalhe e o dialogo sao `position: fixed`. --%>
<%@ include file="/WEB-INF/jsp/fragments/reservas-agenda-paineis.jspf" %>
<ui:shell-fim />
