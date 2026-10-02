<%--
    Componente: campo de senha com botao "Mostrar" (S33/F3).

    Substitui `.field` + `.password-field` do CSS legado nas tres telas que tem senha
    (login, usuarios/lista e usuarios/detalhe). O par de hooks e o mesmo de antes:
    `data-password-input` no input e `data-password-toggle` no botao, lidos por
    `static/js/forms.js` (que troca o `type` e o texto do botao).

        <ui:campo-senha rotulo="Senha" nome="senha" maxlength="255"
                        dica="A senha e sempre redefinida." />

    Atributos: `rotulo` e `nome` (obrigatorios); `dica`, `placeholder`, `maxlength` e
    `classe` (opcionais).

    Equivalencias: `.password-field` era `display: grid; grid-template-columns: 1fr auto;
    gap: 10px` e, abaixo de 640px, uma coluna. O `required` e fixo aqui porque as tres telas
    exigem a senha.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ attribute name="rotulo" required="true" %>
<%@ attribute name="nome" required="true" %>
<%@ attribute name="dica" required="false" %>
<%@ attribute name="placeholder" required="false" %>
<%@ attribute name="maxlength" required="false" %>
<%@ attribute name="classe" required="false" description="classes extras do <label>" %>

<label class="grid gap-2${empty classe ? '' : ' '}${classe}">
    <span class="font-semibold">${rotulo}</span>
    <div class="grid grid-cols-[1fr_auto] gap-2.5 max-[640px]:grid-cols-1">
        <input class="input w-full" type="password" name="${nome}"
               <c:if test="${not empty placeholder}">placeholder="${placeholder}" </c:if><c:if test="${not empty maxlength}">maxlength="${maxlength}" </c:if>required data-password-input>
        <button type="button" class="btn btn-ghost" data-password-toggle>Mostrar</button>
    </div>
    <c:if test="${not empty dica}">
        <small class="text-base-content/60">${dica}</small>
    </c:if>
</label>
