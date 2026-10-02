<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="colaborador-chamado-detalhe">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <ui:detalhe-chamado base="${ctx}/colaborador/chamados"
                                eyebrow="Atendimento"
                                eyebrowComentarios="Historico"
                                avisoFinal="Em andamento"
                                modo="gestao"
                                dicaAnexo="Opcional. O arquivo fica vinculado a este comentario do colaborador. Tamanho maximo: 5 MB." />
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
