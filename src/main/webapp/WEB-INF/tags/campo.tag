<%--
    Componente: campo de formulario (S33/F3).

    Substitui o par `.field` + `.field-hint` do CSS legado. Na pratica, o que sai da tela e
    o esqueleto `label > span + controle` e o peso do rotulo:

        <ui:campo rotulo="Nome">
            <input class="input w-full" type="text" name="nome" required>
        </ui:campo>

    Com dica fixa:
        <ui:campo rotulo="Senha" dica="A senha e sempre redefinida.">
            ...
        </ui:campo>

    Atributos:
        rotulo  obrigatorio — o texto do `<span>`
        dica    opcional — vai num `<small>` DEPOIS do corpo
        classe  opcional — classes extras do `<label>` (ex.: `flex-1 basis-60` dentro de um
                `inline-panel`, que no legado vinha de `.inline-panel .field`)

    Equivalencias com o legado: `.field` era `display: grid; gap: 8px` (`grid gap-2`) e
    `.field span` tinha `font-weight: 600` (`font-semibold`; a daisyUI nao pesa o rotulo
    sozinha). A dica/`.field-hint` era `color: var(--muted)` sobre um `<small>` — daí
    `text-sm` NAO aparecer: o tamanho continua vindo do elemento `small`.

    Dicas dinamicas (o contador de caracteres, por exemplo) ficam no CORPO, junto do
    controle, porque carregam hooks (`data-character-output`) e texto que o JS atualiza.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ attribute name="rotulo" required="true" %>
<%@ attribute name="dica" required="false" %>
<%@ attribute name="classe" required="false" description="classes extras do <label>" %>

<label class="grid gap-2${empty classe ? '' : ' '}${classe}">
    <span class="font-semibold">${rotulo}</span>
    <jsp:doBody />
    <c:if test="${not empty dica}">
        <small class="text-base-content/60">${dica}</small>
    </c:if>
</label>
