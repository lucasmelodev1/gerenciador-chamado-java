<%--
    Componente: paginacao de listagem (S31).

    Uma listagem por vez: "Anterior | Pagina X de Y | Proxima", com os links carregando os
    filtros da tela. Substitui os treze blocos escritos a mao, que repetiam o ternario
    `totalPages == 0 ? 1 : totalPages` e, em duas telas, os mesmos cinco parametros de filtro
    em cada link.

    Uso (sem filtros):
        <ui:paginacao pagina="${areasPage}" url="${ctx}/admin/areas" />

    Uso (preservando os filtros do formulario GET):
        <ui:paginacao pagina="${chamadosPage}" url="${ctx}/admin/chamados"
                      parametros="&statusId=${filtroStatusId}&moradorNome=${filtroMoradorNome}" />

    Uso (paginacao com parametros proprios, como a tela de vinculos):
        <ui:paginacao pagina="${moradoresCadastradosPage}" url="${ctx}/admin/vinculos-morador"
                      paramPagina="cadastradosPage" paramTamanho="cadastradosSize"
                      parametros="${vinculosParametros}" />

    Atributos:
        pagina       obrigatorio — o Map de `WebControllerSupport.pageMetadata` (page, size,
                     totalPages, hasPrevious, hasNext)
        url          obrigatorio — URL base da listagem, sem query
        parametros   opcional — filtros extras no formato `&chave=valor`, ja concatenados;
                     o valor inteiro da URL passa por `fn:escapeXml`, que e o que impede um
                     filtro com `&`/`"` de quebrar o href (hoje os filtros entram crus)
        paramPagina  opcional — nome do parametro de pagina (padrao `page`)
        paramTamanho opcional — nome do parametro de tamanho (padrao `size`)

    Os dois botoes usam a classe `btn` do legado, como antes; a logica de mostrar/esconder
    continua sendo `hasPrevious`/`hasNext` do servidor (sem estado no cliente).
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ attribute name="pagina" required="true" type="java.lang.Object" description="Map do WebControllerSupport.pageMetadata" %>
<%@ attribute name="url" required="true" %>
<%@ attribute name="parametros" required="false" %>
<%@ attribute name="paramPagina" required="false" %>
<%@ attribute name="paramTamanho" required="false" %>

<c:set var="paginaParam" value="${empty paramPagina ? 'page' : paramPagina}" />
<c:set var="tamanhoParam" value="${empty paramTamanho ? 'size' : paramTamanho}" />
<c:set var="linkAnterior" value="${url}?${paginaParam}=${pagina.page - 1}&${tamanhoParam}=${pagina.size}${parametros}" />
<c:set var="linkSeguinte" value="${url}?${paginaParam}=${pagina.page + 1}&${tamanhoParam}=${pagina.size}${parametros}" />

<div class="mt-4.5 flex flex-wrap items-center justify-between gap-4 border-t border-base-content/10 pt-4.5">
    <c:if test="${pagina.hasPrevious}">
        <a class="btn" href="${fn:escapeXml(linkAnterior)}">Anterior</a>
    </c:if>
    <span>Página ${pagina.page + 1} de ${pagina.totalPages == 0 ? 1 : pagina.totalPages}</span>
    <c:if test="${pagina.hasNext}">
        <a class="btn" href="${fn:escapeXml(linkSeguinte)}">Próxima</a>
    </c:if>
</div>
