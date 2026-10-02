<%--
    Componente: badge de status de reserva com cor semantica (S31).

    Substitui o include `fragments/reserva-status.jspf`, que recebia o status por variavel de
    page scope e ainda precisava remover a variavel no fim.

    Uso:
        <ui:reserva-status status="${reserva.status}" />

    Os quatro estados do enum `StatusSolicitacaoArea` sao valores fixos, entao o mapeamento e
    literal — o que tambem e obrigatorio para o Tailwind extrair as classes (nome composto por
    variavel nao e detectado; ver UI-REWRITE-MAP.md §4.2).
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ attribute name="status" required="true" description="valor de StatusSolicitacaoArea" %>

<c:choose>
    <c:when test="${status eq 'Solicitado'}"><span class="badge badge-warning">${status}</span></c:when>
    <c:when test="${status eq 'Aprovado'}"><span class="badge badge-success">${status}</span></c:when>
    <c:when test="${status eq 'Negado'}"><span class="badge badge-error">${status}</span></c:when>
    <c:otherwise><span class="badge badge-neutral">${status}</span></c:otherwise>
</c:choose>
