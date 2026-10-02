<%--
    Componente: fechamento da pagina (S31) — o par do `ui:shell`.

    Carrega os scripts (`fragments/scripts.jspf`) e fecha o documento. Vem DEPOIS dos
    paineis: eles nascem fora de `.page-content` e antes do fim do <body>.

    Uso:
        <ui:shell-fim />

    `${ctx}` e definido aqui pelo mesmo motivo do `ui:shell`: o fragmento incluido nao ve o
    `ctx` da pagina.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<c:set var="ctx" value="${request.contextPath}" />
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
