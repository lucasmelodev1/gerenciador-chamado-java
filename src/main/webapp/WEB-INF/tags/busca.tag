<%--
    Componente: campo de busca da faixa de filtros (S24, extraido para tag em S26).

    O `label.input` da daisyUI ja e `inline-flex` com `gap` e zera o `<input>` interno,
    entao o icone de lupa entra na propria moldura, a esquerda do texto — sem
    `position: absolute` e sem utilitario novo.

    O filtro e LOCAL (`static/js/tables.js`): casa `data-filter-input` com a tabela
    `[data-filter-table="<alvo>"]` e esconde as linhas por `textContent`. Nao ha
    requisicao ao servidor.

    Uso:
        <div class="app-card-filtros">
            <ui:busca alvo="areas-table" rotulo="Pesquisar areas" />
        </div>

    `rotulo` e o nome acessivel (aria-label): o campo nao tem texto visivel, entao sem
    ele o leitor de tela anuncia so "campo de busca".
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ attribute name="alvo" required="true" description="valor de data-filter-target; casa com o data-filter-table da tabela" %>
<%@ attribute name="rotulo" required="false" description="nome acessivel do campo (padrao: Pesquisar)" %>
<%@ attribute name="placeholder" required="false" %>

<c:set var="buscaRotulo" value="${empty rotulo ? 'Pesquisar' : rotulo}" />
<c:set var="buscaPlaceholder" value="${empty placeholder ? 'Pesquisar...' : placeholder}" />

<label class="input input-sm">
    <c:set var="icone" value="pesquisar" />
    <c:set var="iconeClasse" value="size-4 shrink-0 opacity-60" />
    <%@ include file="/WEB-INF/jsp/fragments/icone.jspf" %>
    <input type="search" placeholder="${buscaPlaceholder}" aria-label="${buscaRotulo}"
           data-filter-input data-filter-target="${alvo}">
</label>
