<%--
    Componente: cabecalho de card de listagem (S24, extraido para tag em S26).

    Uma linha com a descricao e o titulo a esquerda (colados, `gap: 2px`) e a acao
    primaria a direita (`space-between`). O filete na base e o divisor que separa
    este cabecalho da faixa de filtros que vem logo abaixo. Estilo em
    `custom.css` > `.app-card-head`.

    Uso (o corpo e a acao, normalmente o gatilho do drawer de criacao):
        <ui:card-head titulo="Areas cadastradas" descricao="Espacos do condominio">
            <button type="button" class="btn btn-primary btn-sm" data-drawer-abrir="drawer-area">
                Nova area
            </button>
        </ui:card-head>

    Sem corpo (tela sem acao primaria, ex.: chamados do admin) o cabecalho sai so com
    titulo e descricao, e o filete continua la.

    NAO reusa `.section-header` do legado: aquela classe carrega depois de
    `custom.css` e a `responsive.css` a empilha abaixo de 900px — ver o comentario da
    secao "Cabecalho de card de listagem" em `custom.css`.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ attribute name="titulo" required="true" %>
<%@ attribute name="descricao" required="false" %>

<div class="app-card-head">
    <div class="app-card-head__texto">
        <c:if test="${not empty descricao}">
            <p class="eyebrow">${descricao}</p>
        </c:if>
        <h2>${titulo}</h2>
    </div>
    <jsp:doBody />
</div>
