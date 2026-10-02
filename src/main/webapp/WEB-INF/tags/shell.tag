<%--
    Componente: abertura da pagina (S31).

    As 25 telas autenticadas repetiam o mesmo bloco: doctype, `<head>`, wrapper do drawer,
    lateral, topbar, `<main class="page-content">` e as mensagens de redirect. Aqui isso vira
    uma chamada; a pagina declara so o `dataPagina` e o conteudo.

    Uso:
        <ui:shell dataPagina="admin-areas">
            ...conteudo de <main>...
        </ui:shell>

        ...paineis (ui:drawer/ui:dialog, que precisam ficar FORA de .page-content)...

        <ui:shell-fim />

    Atributos:
        dataPagina  obrigatorio — valor de `data-page` do <body> (marcador do shell)
        classeMain  opcional — classe extra do <main> (ex.: `narrow-content`)

    Sao DOIS tags porque o corpo do `<jsp:doBody/>` e um so: os paineis precisam ser
    renderizados entre `</main>` e o fim do `<body>` — dentro de `.page-content` o legado
    espremeria o backdrop (ver custom.css > Drawer lateral). O `ui:shell` abre e fecha o
    `<main>`/drawer; o `ui:shell-fim` carrega os scripts e fecha o documento.

    `${ctx}` e definido aqui (`${request.contextPath}`) porque `sidebar.jspf`/`topbar.jspf`/
    `head.jspf` sao INCLUIDOS por este arquivo e nao veem o `ctx` da pagina. O acesso ao
    token CSRF no <head> continua em `fragments/head.jspf` — nao remova.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="ui" tagdir="/WEB-INF/tags" %>
<%@ attribute name="dataPagina" required="true" description="valor de data-page do <body>" %>
<%@ attribute name="classeMain" required="false" description="classe extra do <main>" %>

<c:set var="ctx" value="${request.contextPath}" />
<c:set var="mainClasse" value="page-content${empty classeMain ? '' : ' '}${classeMain}" />
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="${dataPagina}">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="${mainClasse}">
            <ui:flash />

            <jsp:doBody />
        </main>
    </div>
</div>
