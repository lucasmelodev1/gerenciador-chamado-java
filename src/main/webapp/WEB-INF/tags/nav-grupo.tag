<%--
    Componente: grupo da navegacao lateral (S32).

    O rotulo do grupo + o `menu` da daisyUI. O grupo nao abre a lista de itens: o corpo e a
    composicao de varios `ui:nav-item` irmaos.

    Uso:
        <ui:nav-grupo rotulo="Cadastros">
            <ui:nav-item href="/admin/blocos" rotulo="Blocos" icone="blocos" />
        </ui:nav-grupo>

    Atributo: `rotulo` (opcional — sem ele o grupo sai sem a linha de titulo).
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ attribute name="rotulo" required="false" %>

<div class="grid gap-0.5">
    <c:if test="${not empty rotulo}">
        <p class="px-2 text-xs font-semibold tracking-wider uppercase opacity-60">${rotulo}</p>
    </c:if>
    <ul class="menu w-full">
        <jsp:doBody />
    </ul>
</div>
