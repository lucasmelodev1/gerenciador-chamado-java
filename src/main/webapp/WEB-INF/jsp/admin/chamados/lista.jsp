<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-chamados">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <section class="card">
                <div class="card-body">
                <div class="section-header">
                    <div>
                        <p class="eyebrow">Monitoramento</p>
                        <h2>Fila completa de chamados</h2>
                        <p class="section-subtitle">Os chamados mais antigos aparecem primeiro na lista.</p>
                    </div>
                </div>

                <form method="get" action="${ctx}/admin/chamados" class="filter-grid">
                    <label class="field">
                        <span>Status</span>
                        <select class="select w-full" name="statusId">
                            <option value="">Todos</option>
                            <c:forEach items="${statusDisponiveis}" var="status">
                                <option value="${status.id}" ${filtroStatusId eq status.id ? 'selected' : ''}>${status.nome}</option>
                            </c:forEach>
                        </select>
                    </label>
                    <label class="field">
                        <span>Morador</span>
                        <input class="input w-full" type="text" name="moradorNome" value="${filtroMoradorNome}" placeholder="Ex.: mar">
                    </label>
                    <label class="field">
                        <span>Data de abertura</span>
                        <input class="input w-full" type="date" name="dataAbertura" value="${filtroDataAbertura}">
                    </label>
                    <div class="button-row align-end">
                        <button type="submit" class="btn btn-primary">Filtrar</button>
                        <a href="${ctx}/admin/chamados" class="btn">Limpar</a>
                    </div>
                </form>
                            </div>
            </section>

            <section class="card">
                <div class="card-body">
                <c:choose>
                    <c:when test="${empty chamados}">
                        <c:set var="vazioTitulo" value="Nenhum chamado encontrado" />
                        <c:set var="vazioMensagem" value="Altere os filtros ou aguarde novas aberturas." />
                        <%@ include file="/WEB-INF/jsp/fragments/vazio.jspf" %>
                    </c:when>
                    <c:otherwise>
                        <div class="overflow-x-auto">
                            <table class="table table-zebra">
                                <thead>
                                <tr>
                                    <th>Unidade</th>
                                    <th>Morador</th>
                                    <th>Tipo</th>
                                    <th>Status</th>
                                    <th>Abertura</th>
                                    <th></th>
                                </tr>
                                </thead>
                                <tbody>
                                <c:forEach items="${chamados}" var="chamado">
                                    <tr>
                                        <td>${chamado.unidadeIdentificacao}</td>
                                        <td>${chamado.moradorNome}</td>
                                        <td>${chamado.tipoChamadoTitulo}</td>
                                        <td><span class="badge badge-ghost">${chamado.statusNome}</span></td>
                                        <td>${chamado.dataAberturaFormatada}</td>
                                        <td class="cell-actions">
                                            <a href="${ctx}/admin/chamados/${chamado.id}" class="btn btn-link">Detalhar</a>
                                        </td>
                                    </tr>
                                </c:forEach>
                                </tbody>
                            </table>
                        </div>
                    </c:otherwise>
                </c:choose>

                <div class="pagination">
                    <c:if test="${chamadosPage.hasPrevious}">
                        <a class="btn" href="${ctx}/admin/chamados?page=${chamadosPage.page - 1}&size=${chamadosPage.size}&statusId=${filtroStatusId}&moradorNome=${filtroMoradorNome}&dataAbertura=${filtroDataAbertura}">Anterior</a>
                    </c:if>
                    <span>Pagina ${chamadosPage.page + 1} de ${chamadosPage.totalPages == 0 ? 1 : chamadosPage.totalPages}</span>
                    <c:if test="${chamadosPage.hasNext}">
                        <a class="btn" href="${ctx}/admin/chamados?page=${chamadosPage.page + 1}&size=${chamadosPage.size}&statusId=${filtroStatusId}&moradorNome=${filtroMoradorNome}&dataAbertura=${filtroDataAbertura}">Proxima</a>
                    </c:if>
                </div>
                            </div>
            </section>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
