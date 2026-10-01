<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-tipos-chamado">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>
            <c:set var="tipoChamadoAction" value="${ctx}/admin/tipos-chamado" />
            <c:if test="${not empty tipoChamadoEdicao}">
                <c:set var="tipoChamadoAction" value="${ctx}/admin/tipos-chamado/${tipoChamadoEdicao.id}" />
            </c:if>

            <section class="two-column-grid">
                <article class="card">
                    <div class="card-body">
                    <div class="section-header">
                        <div>
                            <p class="eyebrow">Catalogo</p>
                            <h2><c:choose><c:when test="${not empty tipoChamadoEdicao}">Editar tipo</c:when><c:otherwise>Novo tipo</c:otherwise></c:choose></h2>
                        </div>
                    </div>

                    <form method="post" action="${tipoChamadoAction}" class="stack-form">
                        <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                        <c:if test="${not empty tipoChamadoEdicao}">
                            <input type="hidden" name="_method" value="patch">
                        </c:if>
                        <label class="field">
                            <span>Titulo</span>
                            <input class="input w-full" type="text" name="titulo" value="${tipoChamadoForm.titulo}" placeholder="Vazamento" maxlength="255" required>
                        </label>
                        <label class="field">
                            <span>Prazo maximo em horas</span>
                            <input class="input w-full" type="number" min="1" name="prazoHoras" value="${tipoChamadoForm.prazoHoras}" required>
                        </label>
                        <div class="button-row">
                            <button type="submit" class="btn btn-primary">
                                <c:choose><c:when test="${not empty tipoChamadoEdicao}">Salvar tipo</c:when><c:otherwise>Cadastrar tipo</c:otherwise></c:choose>
                            </button>
                            <c:if test="${not empty tipoChamadoEdicao}">
                                <a href="${ctx}/admin/tipos-chamado" class="btn">Cancelar</a>
                            </c:if>
                        </div>
                    </form>
                                    </div>
                </article>

                <article class="card">
                    <div class="card-body">
                    <div class="section-header">
                        <div>
                            <p class="eyebrow">Parametros de abertura</p>
                            <h2>Tipos cadastrados</h2>
                        </div>
                        <input type="search" class="input input-sm" placeholder="Filtrar localmente" data-filter-input data-filter-target="tipos-table">
                    </div>

                    <c:choose>
                        <c:when test="${empty tiposChamado}">
                            <c:set var="vazioTitulo" value="Nenhum tipo cadastrado" />
                            <c:set var="vazioMensagem" value="Cadastre os motivos de abertura de chamado para os moradores." />
                            <%@ include file="/WEB-INF/jsp/fragments/vazio.jspf" %>
                        </c:when>
                        <c:otherwise>
                            <div class="overflow-x-auto">
                                <table class="table table-zebra" data-filter-table="tipos-table">
                                    <thead>
                                    <tr>
                                        <th>Titulo</th>
                                        <th>SLA</th>
                                        <th></th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    <c:forEach items="${tiposChamado}" var="tipo">
                                        <tr>
                                            <td>${tipo.titulo}</td>
                                            <td>${tipo.prazoHoras} horas</td>
                                            <td class="cell-actions">
                                                <a href="${ctx}/admin/tipos-chamado?tipoId=${tipo.id}" class="btn btn-link">Editar</a>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                    </tbody>
                                </table>
                            </div>
                        </c:otherwise>
                    </c:choose>

                    <div class="pagination">
                        <c:if test="${tiposChamadoPage.hasPrevious}">
                            <a class="btn" href="${ctx}/admin/tipos-chamado?page=${tiposChamadoPage.page - 1}&size=${tiposChamadoPage.size}">Anterior</a>
                        </c:if>
                        <span>Pagina ${tiposChamadoPage.page + 1} de ${tiposChamadoPage.totalPages == 0 ? 1 : tiposChamadoPage.totalPages}</span>
                        <c:if test="${tiposChamadoPage.hasNext}">
                            <a class="btn" href="${ctx}/admin/tipos-chamado?page=${tiposChamadoPage.page + 1}&size=${tiposChamadoPage.size}">Proxima</a>
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
