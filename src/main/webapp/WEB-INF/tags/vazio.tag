<%--
    Componente: estado vazio (S31).

    A daisyUI nao tem componente equivalente, entao e uma composicao propria que fica num
    unico lugar. Substitui o include `fragments/vazio.jspf`: la o chamador definia
    `vazioMensagem`/`vazioTitulo`/`vazioCompacto` em page scope e o fragmento precisava
    remover as variaveis no fim para nao vazarem para o proximo bloco da mesma pagina —
    `vazioMensagem`, aliás, nunca era removida.

    Uso:
        <ui:vazio titulo="Nenhuma area cadastrada"
                  mensagem="Cadastre as areas do condominio para uso na operacao." />
        <ui:vazio mensagem="Nenhum comentario registrado." compacto="true" />

    Atributos: `mensagem` (obrigatorio), `titulo` (opcional; quando presente o bloco nao e
    compacto) e `compacto` (opcional). O estilo vive em `components.css` > `.empty-state`.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ attribute name="mensagem" required="true" %>
<%@ attribute name="titulo" required="false" %>
<%@ attribute name="compacto" required="false" description="true => classe compact" %>

<c:set var="vazioCompacto" value="${compacto eq 'true'}" />
<div class="empty-state${vazioCompacto ? ' compact' : ''}">
    <c:if test="${not empty titulo}">
        <h3>${titulo}</h3>
    </c:if>
    <p>${mensagem}</p>
</div>
