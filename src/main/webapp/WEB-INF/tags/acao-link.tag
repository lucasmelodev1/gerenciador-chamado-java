<%--
    Componente: acao de linha que NAVEGA, so com icone + tooltip (S25, tag em S26).

    Uso:
        <ui:acao-link href="${ctx}/admin/chamados/${chamado.id}" icone="ver" rotulo="Detalhar" />

    `rotulo` e o texto do tooltip E o nome acessivel: o botao nao tem texto visivel.
    O icone sai em `size-4`, o mesmo tamanho dos icones da lateral.

    Para acoes que ENVIAM algo, use `ui:acao-form`; para abrir o drawer de edicao,
    `ui:acao-editar`. As tres saem com a mesma moldura (`btn btn-ghost btn-sm
    btn-square tooltip`), e o estilo da coluna esta em `custom.css` > `.app-tabela-acoes`.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ attribute name="href" required="true" %>
<%@ attribute name="rotulo" required="true" description="texto do tooltip e nome acessivel" %>
<%@ attribute name="icone" required="true" description="alias de fragments/icone.jspf" %>

<a href="${href}" class="btn btn-ghost btn-sm btn-square tooltip"
   data-tip="${rotulo}" aria-label="${rotulo}">
    <c:set var="iconeClasse" value="size-4" />
    <%@ include file="/WEB-INF/jsp/fragments/icone.jspf" %>
</a>
