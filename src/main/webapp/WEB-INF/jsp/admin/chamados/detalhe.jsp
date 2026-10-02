<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-chamado-detalhe">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <ui:detalhe-chamado base="${ctx}/admin/chamados"
                                eyebrow="Chamado"
                                eyebrowComentarios="Historico"
                                avisoFinal="Ainda nao finalizado"
                                modo="gestao"
                                mostrarMorador="true"
                                dicaAnexo="Opcional. O arquivo fica vinculado a este comentario do administrador. Tamanho maximo: 5 MB." />
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
