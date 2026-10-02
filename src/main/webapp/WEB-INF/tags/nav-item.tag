<%--
    Componente: item da navegacao lateral (S32) — icone + rotulo, com o estado ativo
    resolvido no servidor.

    Substitui a string `Grupo@href|Rotulo|aliasDoIcone#...` que o `sidebar.jspf` partia com
    `fn:split`: la um rotulo que contivesse `|`, `#`, `@` ou `;` corrompia o menu inteiro.

    Uso:
        <ui:nav-item href="/admin/chamados" rotulo="Chamados" icone="chamados" />
        <ui:nav-item href="/admin" rotulo="Inicio" icone="inicio" exato="true" />

    Atributos: `href` (caminho sem o context path), `rotulo`, `icone` (alias de `ui:icone`) e
    `exato` (`true` para a home do perfil, que casa o caminho exato em vez do prefixo).

    O estado ativo e do SERVIDOR e o PRIMEIRO item que casa vence — por isso cada grupo lista
    os caminhos do mais especifico para o mais generico (`/admin/reservas/agenda` antes de
    `/admin/reservas`). O `scripts/ui-shell.sh` confere que existe exatamente um
    `aria-current="page"`.

    `navPath`, `ctx` e o proprio marcador de resolvido vem do request scope, publicado pelo
    `fragments/sidebar.jspf`: um tag file le o chamador pelo escopo de request (mesmo padrao
    do `chamado` no `ui:detalhe-chamado`).
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="ui" tagdir="/WEB-INF/tags" %>
<%@ attribute name="href" required="true" description="caminho sem o context path" %>
<%@ attribute name="rotulo" required="true" %>
<%@ attribute name="icone" required="true" description="alias de ui:icone" %>
<%@ attribute name="exato" required="false" description="true => casa o caminho exato (home do perfil)" %>

<c:set var="navItemResolvido" value="${requestScope.navItemAtivoResolvido}" />
<c:choose>
    <c:when test="${exato eq 'true'}">
        <c:set var="navItemAtivo" value="${empty navItemResolvido and navPath eq href}" />
    </c:when>
    <c:otherwise>
        <c:set var="navItemAtivo" value="${empty navItemResolvido and fn:startsWith(navPath, href)}" />
    </c:otherwise>
</c:choose>
<c:if test="${navItemAtivo}">
    <c:set var="navItemAtivoResolvido" value="true" scope="request" />
</c:if>

<li>
    <a href="${ctx}${href}"
       class="${navItemAtivo ? 'menu-active' : ''}"${navItemAtivo ? ' aria-current="page"' : ''}>
        <ui:icone nome="${icone}" classe="size-4 shrink-0" />
        <%-- `min-w-0` porque o item do menu e um grid de 3 colunas e o item de grid nasce
             com `min-width:auto`, o que impediria o `truncate`. --%>
        <span class="min-w-0 truncate">${rotulo}</span>
    </a>
</li>
