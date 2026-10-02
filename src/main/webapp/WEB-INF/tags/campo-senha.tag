<%--
    Componente: campo de senha com botao "mostrar/ocultar" (S33/F3; icone na S34).

    Substitui `.field` + `.password-field` do CSS legado nas tres telas que tem senha
    (login, usuarios/lista e usuarios/detalhe). Os hooks sao `data-password-input` no input e
    `data-password-toggle` no botao, lidos por `static/js/forms.js`.

        <ui:campo-senha rotulo="Senha" nome="senha" maxlength="255"
                        dica="A senha e sempre redefinida." />

    Atributos: `rotulo` e `nome` (obrigatorios); `dica`, `placeholder`, `maxlength` e
    `classe` (opcionais).

    O botao e o mesmo formato das acoes das tabelas (`btn btn-ghost btn-square tooltip` com
    `data-tip`/`aria-label`), e nao um texto "Mostrar": o glifo e um `ui:icone` — `ver`
    (senha oculta) e `ocultar` (senha visivel) — dentro de um `<span data-password-icone>`.
    Quem escolhe qual dos dois aparece e o CSS, por `aria-pressed` (custom.css); o JS so
    troca o `type` do input, o `aria-pressed` e o rotulo.

    `data-password-campo` no container e o que o JS usa para achar o input: ele nao pode
    depender da classe `.password-field`, que saiu do markup com o CSS legado (S33) e deixava
    o botao sem efeito.

    Equivalencias: `.password-field` era `display: grid; grid-template-columns: 1fr auto;
    gap: 10px` e, abaixo de 640px, uma coluna. O `required` e fixo aqui porque as tres telas
    exigem a senha.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="ui" tagdir="/WEB-INF/tags" %>
<%@ attribute name="rotulo" required="true" %>
<%@ attribute name="nome" required="true" %>
<%@ attribute name="dica" required="false" %>
<%@ attribute name="placeholder" required="false" %>
<%@ attribute name="maxlength" required="false" %>
<%@ attribute name="classe" required="false" description="classes extras do <label>" %>

<label class="grid gap-2${empty classe ? '' : ' '}${classe}">
    <span class="font-semibold">${rotulo}</span>
    <div class="grid grid-cols-[1fr_auto] gap-2.5 max-[640px]:grid-cols-1" data-password-campo>
        <input class="input w-full" type="password" name="${nome}"
               <c:if test="${not empty placeholder}">placeholder="${placeholder}" </c:if><c:if test="${not empty maxlength}">maxlength="${maxlength}" </c:if>required data-password-input>
        <button type="button" class="btn btn-ghost btn-square tooltip" data-password-toggle
                data-tip="Mostrar senha" aria-label="Mostrar senha" aria-pressed="false">
            <span data-password-icone="mostrar"><ui:icone nome="ver" /></span>
            <span data-password-icone="ocultar"><ui:icone nome="ocultar" /></span>
        </button>
    </div>
    <c:if test="${not empty dica}">
        <small class="text-base-content/60">${dica}</small>
    </c:if>
</label>
