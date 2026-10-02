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
    compacto) e `compacto` (opcional).

    O estilo era `.empty-state`/`.empty-state.compact` no legado; virou utilitario no F4 da
    S33 (`rounded-xl` = 12px, `bg-white/75` = a `--panel-soft`, borda tracejada a 15% do
    texto, `px-6 py-9` = 36/24px e `p-4.5` = 18px no compacto).
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ attribute name="mensagem" required="true" %>
<%@ attribute name="titulo" required="false" %>
<%@ attribute name="compacto" required="false" description="true => bloco compacto" %>

<c:set var="vazioCompacto" value="${compacto eq 'true'}" />
<c:set var="vazioEspaco" value="${vazioCompacto ? 'p-4.5' : 'px-6 py-9'}" />
<div class="rounded-xl border border-dashed border-base-content/15 bg-white/75 text-center ${vazioEspaco}">
    <c:if test="${not empty titulo}">
        <h3 class="mb-2">${titulo}</h3>
    </c:if>
    <p>${mensagem}</p>
</div>
