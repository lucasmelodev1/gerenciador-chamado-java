<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="morador-reservas-lista">
<div class="app-shell">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="app-main">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <section class="card">
                <div class="section-header">
                    <div>
                        <p class="eyebrow">Areas comuns</p>
                        <h2>Minhas reservas</h2>
                    </div>
                    <div class="button-row">
                        <a href="${ctx}/morador/reservas/nova" class="btn btn-primary">Nova reserva</a>
                        <a href="${ctx}/morador/reservas/agenda" class="btn btn-secondary">Ver agenda</a>
                        <a href="${ctx}/morador/reservas/disponibilidade" class="btn btn-secondary">Consultar disponibilidade</a>
                    </div>
                </div>

                <c:choose>
                    <c:when test="${empty reservas}">
                        <div class="empty-state">
                            <h3>Nenhuma reserva encontrada</h3>
                            <p>Solicite a reserva de uma area comum para planejar o uso.</p>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <div class="table-wrap">
                            <table class="data-table">
                                <thead>
                                <tr>
                                    <th>Area</th>
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
                                        <td>${reserva.inicioFormatado}</td>
                                        <td>${reserva.fimFormatado}</td>
                                        <td><span class="status-pill">${reserva.status}</span></td>
                                        <td><c:out value="${empty reserva.motivoNegacao ? '-' : reserva.motivoNegacao}" /></td>
                                        <td class="cell-actions">
                                            <c:if test="${reserva.status eq 'Solicitado' or reserva.status eq 'Aprovado'}">
                                                <form method="post" action="${ctx}/morador/reservas/${reserva.id}" onsubmit="return confirm('Cancelar esta reserva?');">
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
                        <a class="btn btn-secondary" href="${ctx}/morador/reservas?page=${reservasPage.page - 1}&size=${reservasPage.size}">Anterior</a>
                    </c:if>
                    <span>Pagina ${reservasPage.page + 1} de ${reservasPage.totalPages == 0 ? 1 : reservasPage.totalPages}</span>
                    <c:if test="${reservasPage.hasNext}">
                        <a class="btn btn-secondary" href="${ctx}/morador/reservas?page=${reservasPage.page + 1}&size=${reservasPage.size}">Proxima</a>
                    </c:if>
                </div>
            </section>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
