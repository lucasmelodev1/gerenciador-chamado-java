<%--
    Componente: acao de linha que NAVEGA (S25, tag em S26; modo texto em S31).

    Uso (so icone + tooltip, o formato das tabelas):
        <ui:acao-link href="${ctx}/admin/chamados/${chamado.id}" icone="ver" rotulo="Detalhar" />

    Uso (com texto visivel, o formato das listas que ainda usam `btn-link`):
        <ui:acao-link href="${ctx}/morador/chamados/${chamado.id}" texto="Acompanhar" />

    `rotulo` e o texto do tooltip E o nome acessivel no modo icone; `texto` e o rotulo
    visivel e ativa essa forma, com a mesma classe `btn btn-link` que as listas usavam
    antes de virarem componente.

    Para acoes que ENVIAM algo, use `ui:acao-form`; para abrir o drawer de edicao,
    `ui:acao-editar`. As tres saem com a mesma moldura no modo icone (`btn btn-ghost btn-sm
    btn-square tooltip`), e o estilo da coluna esta em `custom.css` > `.app-tabela-acoes`.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="ui" tagdir="/WEB-INF/tags" %>
<%@ attribute name="href" required="true" %>
<%@ attribute name="rotulo" required="false" description="texto do tooltip e nome acessivel (modo icone)" %>
<%@ attribute name="icone" required="false" description="alias de ui:icone (modo icone)" %>
<%@ attribute name="texto" required="false" description="rotulo visivel; ativa o modo texto (btn btn-link)" %>

<c:choose>
    <c:when test="${not empty texto}">
        <a href="${href}" class="btn btn-link">${texto}</a>
    </c:when>
    <c:otherwise>
        <a href="${href}" class="btn btn-ghost btn-sm btn-square tooltip"
           data-tip="${rotulo}" aria-label="${rotulo}">
            <ui:icone nome="${icone}" />
        </a>
    </c:otherwise>
</c:choose>
