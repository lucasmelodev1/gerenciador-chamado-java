<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-blocos">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <section class="two-column-grid">
                <article class="card">
                    <div class="card-body">
                    <div class="section-header">
                        <div>
                            <p class="eyebrow">Cadastro</p>
                            <h2>Novo bloco</h2>
                        </div>
                    </div>
                    <form method="post" action="${ctx}/admin/blocos" class="stack-form">
                        <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                        <label class="field">
                            <span>Identificacao</span>
                            <input class="input w-full" type="text" name="identificacao" value="${blocoForm.identificacao}" placeholder="Bloco A" maxlength="255" required>
                        </label>
                        <div class="form-grid">
                            <label class="field">
                                <span>Andares</span>
                                <input class="input w-full" type="number" name="quantidadeAndares" min="1" value="${blocoForm.quantidadeAndares}" required>
                            </label>
                            <label class="field">
                                <span>Apartamentos por andar</span>
                                <input class="input w-full" type="number" name="apartamentosPorAndar" min="1" value="${blocoForm.apartamentosPorAndar}" required>
                            </label>
                        </div>
                        <button type="submit" class="btn btn-primary">Cadastrar bloco</button>
                    </form>
                                    </div>
                </article>

                <article class="card">
                    <div class="card-body">
                    <div class="section-header">
                        <div>
                            <p class="eyebrow">Lista</p>
                            <h2>Blocos cadastrados</h2>
                        </div>
                        <div class="toolbar-inline">
                            <input type="search" class="input input-sm" placeholder="Filtrar localmente" data-filter-input data-filter-target="blocos-table">
                        </div>
                    </div>

                    <c:choose>
                        <c:when test="${empty blocos}">
                            <c:set var="vazioTitulo" value="Nenhum bloco cadastrado" />
                            <c:set var="vazioMensagem" value="Cadastre o primeiro bloco para gerar as unidades automaticamente." />
                            <%@ include file="/WEB-INF/jsp/fragments/vazio.jspf" %>
                        </c:when>
                        <c:otherwise>
                            <div class="overflow-x-auto">
                                <table class="table table-zebra" data-filter-table="blocos-table">
                                    <thead>
                                    <tr>
                                        <th>Identificacao</th>
                                        <th>Andares</th>
                                        <th>Aptos/andar</th>
                                        <th></th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    <c:forEach items="${blocos}" var="bloco">
                                        <tr>
                                            <td>${bloco.identificacao}</td>
                                            <td>${bloco.quantidadeAndares}</td>
                                            <td>${bloco.apartamentosPorAndar}</td>
                                            <td class="cell-actions">
                                                <a href="${ctx}/admin/blocos/${bloco.id}" class="btn btn-link">Ver unidades</a>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                    </tbody>
                                </table>
                            </div>
                        </c:otherwise>
                    </c:choose>

                    <div class="pagination">
                        <c:if test="${blocosPage.hasPrevious}">
                            <a class="btn" href="${ctx}/admin/blocos?page=${blocosPage.page - 1}&size=${blocosPage.size}">Anterior</a>
                        </c:if>
                        <span>Pagina ${blocosPage.page + 1} de ${blocosPage.totalPages == 0 ? 1 : blocosPage.totalPages}</span>
                        <c:if test="${blocosPage.hasNext}">
                            <a class="btn" href="${ctx}/admin/blocos?page=${blocosPage.page + 1}&size=${blocosPage.size}">Proxima</a>
                        </c:if>
                    </div>
                                    </div>
                </article>
            </section>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
