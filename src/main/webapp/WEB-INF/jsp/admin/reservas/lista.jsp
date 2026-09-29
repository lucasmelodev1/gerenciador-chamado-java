<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-reservas-lista">
<div class="app-shell">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="app-main">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <section class="card">
                <div class="section-header">
                    <div>
                        <p class="eyebrow">Agenda unica</p>
                        <h2>Reservas das areas comuns</h2>
                    </div>
                    <a href="${ctx}/admin/reservas/agenda" class="btn btn-secondary">Ver agenda</a>
                </div>

                <c:choose>
                    <c:when test="${empty reservas}">
                        <div class="empty-state">
                            <h3>Nenhuma reserva registrada</h3>
                            <p>As solicitacoes dos moradores aparecerao aqui para decisao.</p>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <div class="table-wrap">
                            <table class="data-table">
                                <thead>
                                <tr>
                                    <th>Area</th>
                                    <th>Morador</th>
                                    <th>Unidade</th>
                                    <th>Inicio</th>
                                    <th>Fim</th>
                                    <th>Status</th>
                                    <th>Motivo</th>
                                    <th></th>
                                </tr>
                                </thead>
                                <tbody>
                                <c:forEach items="${reservas}" var="reserva">
                                    <tr>
                                        <td>${reserva.areaNome}</td>
                                        <td>${reserva.moradorNome}</td>
                                        <td>${reserva.unidadeIdentificacao}</td>
                                        <td>${reserva.inicioFormatado}</td>
                                        <td>${reserva.fimFormatado}</td>
                                        <td><span class="status-pill">${reserva.status}</span></td>
                                        <td><c:out value="${empty reserva.motivoNegacao ? '-' : reserva.motivoNegacao}" /></td>
                                        <td class="cell-actions">
                                            <c:if test="${reserva.status eq 'Solicitado'}">
                                                <form method="post" action="${ctx}/admin/reservas/${reserva.id}/aprovacao">
                                                    <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                                                    <input type="hidden" name="_method" value="patch">
                                                    <button type="submit" class="btn btn-link">Aprovar</button>
                                                </form>
                                                <form method="post" action="${ctx}/admin/reservas/${reserva.id}/negacao" class="inline-panel">
                                                    <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                                                    <input type="hidden" name="_method" value="patch">
                                                    <input type="text" name="motivo" maxlength="255" placeholder="Motivo da negacao" required>
                                                    <button type="submit" class="btn btn-link">Negar</button>
                                                </form>
                                            </c:if>
                                            <c:if test="${reserva.status eq 'Solicitado' or reserva.status eq 'Aprovado'}">
                                                <form method="post" action="${ctx}/admin/reservas/${reserva.id}" onsubmit="return confirm('Cancelar esta reserva?');">
                                                    <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                                                    <input type="hidden" name="_method" value="delete">
                                                    <button type="submit" class="btn btn-link">Cancelar</button>
                                                </form>
                                            </c:if>
                                        </td>
                                    </tr>
                                </c:forEach>
                                </tbody>
                            </table>
                        </div>
                    </c:otherwise>
                </c:choose>

                <div class="pagination">
                    <c:if test="${reservasPage.hasPrevious}">
                        <a class="btn btn-secondary" href="${ctx}/admin/reservas?page=${reservasPage.page - 1}&size=${reservasPage.size}">Anterior</a>
                    </c:if>
                    <span>Pagina ${reservasPage.page + 1} de ${reservasPage.totalPages == 0 ? 1 : reservasPage.totalPages}</span>
                    <c:if test="${reservasPage.hasNext}">
                        <a class="btn btn-secondary" href="${ctx}/admin/reservas?page=${reservasPage.page + 1}&size=${reservasPage.size}">Proxima</a>
                    </c:if>
                </div>
            </section>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
