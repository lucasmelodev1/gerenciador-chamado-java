<%--
    Componente: cartao de metrica do painel (S33/F5).

    Substitui `.stat-card`/`.stat-card-wide` do legado (numero grande, rotulo em cima e, no
    cartao de destaque, um link de acao). O que era CSS virou utilitario aqui — a excecao e
    a barra de destaque (`::after`), que vive no `custom.css` sob `.app-metrica`.

        <ui:metrica rotulo="Blocos" valor="${totalBlocos}" />


    Atributos:
        rotulo      obrigatorio — a linha de cima
        valor       obrigatorio — o numero (ou o texto) grande
        destaque    opcional — `true` pinta com o tom forte do primary e ocupa mais colunas
        href        opcional — href do link do rodape do cartao (e um link, nao uma acao de
                    formulario: o coletor de action URLs do `ui-invariants.sh` so olha
                    `action=`/`acao=`/`base=`)
        rotuloLink  opcional — texto do link
        classeLink  opcional — classes do link (padrao `btn`; as telas usam `btn btn-primary`)

    Numeros do legado: raio 16px (`rounded-2xl`), padding 22px (`p-5.5`), `gap` 10px
    (`gap-2.5`), altura minima 150px (`min-h-[150px]`), numero em 2.25rem/700
    (`text-4xl font-bold`) e hover de 2px (`hover:-translate-y-0.5`). O cartao de destaque
    ocupa 2 colunas na grade de 5, 3 na de 3 e 1 quando ela empilha — daí os tres
    `col-span` com `min-[…]`.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ attribute name="rotulo" required="true" %>
<%@ attribute name="valor" required="true" %>
<%@ attribute name="destaque" required="false" description="true => cartao de destaque" %>
<%@ attribute name="href" required="false" %>
<%@ attribute name="rotuloLink" required="false" %>
<%@ attribute name="classeLink" required="false" description="classes do link (padrao: btn)" %>

<c:set var="metricaDestaque" value="${destaque eq 'true'}" />
<c:set var="metricaBase" value="app-metrica relative grid min-h-[150px] content-start gap-2.5 overflow-hidden rounded-2xl border p-5.5 transition duration-200 hover:-translate-y-0.5 hover:border-accent/20 hover:shadow-forte" />
<c:set var="metricaLink" value="${empty classeLink ? 'btn' : classeLink}" />

<c:choose>
    <c:when test="${metricaDestaque}">
        <article class="${metricaBase} col-span-1 min-[981px]:col-span-3 min-[1201px]:col-span-2 border-white/70 bg-primary-strong text-primary-content">
            <span class="text-primary-content/70">${rotulo}</span>
            <strong class="text-4xl font-bold">${valor}</strong>
            <c:if test="${not empty href}">
                <a href="${href}" class="${metricaLink}">${rotuloLink}</a>
            </c:if>
        </article>
    </c:when>
    <c:otherwise>
        <article class="${metricaBase} border-white/75 bg-base-100">
            <span class="text-base-content/60">${rotulo}</span>
            <strong class="text-4xl font-bold">${valor}</strong>
        </article>
    </c:otherwise>
</c:choose>
