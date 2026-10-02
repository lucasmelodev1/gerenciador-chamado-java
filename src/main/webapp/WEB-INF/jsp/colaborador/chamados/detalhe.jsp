<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="colaborador-chamado-detalhe">

            <ui:detalhe-chamado base="${ctx}/colaborador/chamados"
                                eyebrow="Atendimento"
                                eyebrowComentarios="Historico"
                                avisoFinal="Em andamento"
                                modo="gestao"
                                dicaAnexo="Opcional. O arquivo fica vinculado a este comentario do colaborador. Tamanho maximo: 5 MB." />
</ui:shell>
<ui:shell-fim />
