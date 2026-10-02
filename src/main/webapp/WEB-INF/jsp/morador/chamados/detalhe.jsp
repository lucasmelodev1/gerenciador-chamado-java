<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="morador-chamado-detalhe">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <ui:detalhe-chamado base="${ctx}/morador/chamados"
                                eyebrow="Acompanhamento"
                                eyebrowComentarios="Interacoes"
                                avisoFinal="Em andamento"
                                modo="morador"
                                podeAnexarAvulso="true"
                                dicaAnexo="Opcional. Disponivel apenas no comentario enviado pelo morador. Tamanho maximo: 5 MB." />
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
