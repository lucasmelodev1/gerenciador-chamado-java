<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-areas">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>
            <c:set var="areaAction" value="${ctx}/admin/areas" />
            <c:if test="${not empty areaEdicao}">
                <c:set var="areaAction" value="${ctx}/admin/areas/${areaEdicao.id}" />
            </c:if>

            <section class="two-column-grid">
                <article class="card">
                    <div class="card-body">
                    <div class="section-header">
                        <div>
                            <p class="eyebrow">Estrutura</p>
                            <h2><c:choose><c:when test="${not empty areaEdicao}">Editar area</c:when><c:otherwise>Nova area</c:otherwise></c:choose></h2>
                        </div>
                    </div>

                    <form method="post" action="${areaAction}" class="stack-form">
                        <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                        <c:if test="${not empty areaEdicao}">
                            <input type="hidden" name="_method" value="patch">
                        </c:if>
                        <label class="field">
                            <span>Nome</span>
                            <input class="input w-full" type="text" name="nome" value="${areaForm.nome}" placeholder="Piscina" maxlength="255" required>
                        </label>
                        <label class="field">
                            <span>Status</span>
                            <select class="select w-full" name="status" required>
                                <c:forEach items="${statusAreaDisponiveis}" var="statusArea">
                                    <option value="${statusArea.valor}" ${areaForm.status eq statusArea.valor ? 'selected' : ''}>${statusArea.valor}</option>
                                </c:forEach>
                            </select>
                        </label>
                        <div class="button-row">
                            <button type="submit" class="btn btn-primary">
                                <c:choose><c:when test="${not empty areaEdicao}">Salvar area</c:when><c:otherwise>Cadastrar area</c:otherwise></c:choose>
                            </button>
                            <c:if test="${not empty areaEdicao}">
                                <a href="${ctx}/admin/areas" class="btn">Cancelar</a>
                            </c:if>
                        </div>
                    </form>
                                    </div>
                </article>

                <article class="card">
                    <div class="card-body">
                    <div class="section-header">
                        <div>
                            <p class="eyebrow">Espacos do condominio</p>
                            <h2>Areas cadastradas</h2>
                        </div>
                        <input type="search" class="input input-sm" placeholder="Filtrar localmente" data-filter-input data-filter-target="areas-table">
                    </div>

                    <c:choose>
                        <c:when test="${empty areas}">
                            <c:set var="vazioTitulo" value="Nenhuma area cadastrada" />
                            <c:set var="vazioMensagem" value="Cadastre as areas do condominio para uso na operacao." />
                            <%@ include file="/WEB-INF/jsp/fragments/vazio.jspf" %>
                        </c:when>
                        <c:otherwise>
                            <div class="overflow-x-auto">
                                <table class="table table-zebra" data-filter-table="areas-table">
                                    <thead>
                                    <tr>
                                        <th>Nome</th>
                                        <th>Status</th>
                                        <th></th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    <c:forEach items="${areas}" var="area">
                                        <tr>
                                            <td>${area.nome}</td>
                                            <td>${area.status}</td>
                                            <td class="cell-actions">
                                                <a href="${ctx}/admin/areas?areaId=${area.id}" class="btn btn-link">Editar</a>
                                                <form method="post" action="${ctx}/admin/areas/${area.id}" data-confirm="Remover esta area? As reservas existentes serao preservadas.">
                                                    <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                                                    <input type="hidden" name="_method" value="delete">
                                                    <button type="submit" class="btn btn-error">Remover</button>
                                                </form>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                    </tbody>
                                </table>
                            </div>
                        </c:otherwise>
                    </c:choose>

                    <div class="pagination">
                        <c:if test="${areasPage.hasPrevious}">
                            <a class="btn" href="${ctx}/admin/areas?page=${areasPage.page - 1}&size=${areasPage.size}">Anterior</a>
                        </c:if>
                        <span>Pagina ${areasPage.page + 1} de ${areasPage.totalPages == 0 ? 1 : areasPage.totalPages}</span>
                        <c:if test="${areasPage.hasNext}">
                            <a class="btn" href="${ctx}/admin/areas?page=${areasPage.page + 1}&size=${areasPage.size}">Proxima</a>
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
