<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="morador-chamado-detalhe">

            <ui:detalhe-chamado base="${ctx}/morador/chamados"
                                eyebrow="Acompanhamento"
                                eyebrowComentarios="Interacoes"
                                avisoFinal="Em andamento"
                                modo="morador"
                                podeAnexarAvulso="true"
                                dicaAnexo="Opcional. Disponivel apenas no comentario enviado pelo morador. Tamanho maximo: 5 MB." />
</ui:shell>
<ui:shell-fim />
