<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="admin-chamado-detalhe">

            <ui:detalhe-chamado base="${ctx}/admin/chamados"
                                eyebrow="Chamado"
                                eyebrowComentarios="Historico"
                                avisoFinal="Ainda nao finalizado"
                                modo="gestao"
                                mostrarMorador="true"
                                dicaAnexo="Opcional. O arquivo fica vinculado a este comentario do administrador. Tamanho maximo: 5 MB." />
</ui:shell>
<ui:shell-fim />
