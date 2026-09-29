<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="morador-reserva-disponibilidade">
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
                        <h2>Disponibilidade</h2>
                    </div>
                    <a href="${ctx}/morador/reservas" class="btn btn-secondary">Minhas reservas</a>
                </div>

                <form method="get" action="${ctx}/morador/reservas/disponibilidade" class="inline-panel">
                    <label class="field">
                        <span>Area</span>
                        <select name="areaId" required>
                            <option value="">Selecione uma area</option>
                            <c:forEach items="${areas}" var="area">
                                <option value="${area.id}" ${areaId eq area.id ? 'selected' : ''}>${area.nome}</option>
                            </c:forEach>
                        </select>
                    </label>
                    <label class="field">
                        <span>Data</span>
                        <input type="date" name="data" value="${data}" required>
                    </label>
                    <button type="submit" class="btn btn-primary">Consultar</button>
                </form>

                <c:choose>
                    <c:when test="${not consultou}">
                        <div class="empty-state compact">
                            <p>Selecione uma area e uma data para consultar a disponibilidade.</p>
                        </div>
                    </c:when>
                    <c:when test="${empty disponibilidade}">
                        <div class="empty-state compact">
                            <p>Nenhuma reserva aprovada ou pendente para esta area nesta data.</p>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <div class="table-wrap">
                            <table class="data-table">
                                <thead>
                                <tr>
                                    <th>Inicio</th>
                                    <th>Fim</th>
                                    <th>Status</th>
                                </tr>
                                </thead>
                                <tbody>
                                <c:forEach items="${disponibilidade}" var="reserva">
                                    <tr>
                                        <td>${reserva.inicioFormatado}</td>
                                        <td>${reserva.fimFormatado}</td>
                                        <td>
                                            <span class="status-pill">${reserva.status}</span>
                                            <c:if test="${reserva.status eq 'Solicitado'}">
                                                <small class="field-hint">Pendente, nao garante a ocupacao.</small>
                                            </c:if>
                                        </td>
                                    </tr>
                                </c:forEach>
                                </tbody>
                            </table>
                        </div>
                    </c:otherwise>
                </c:choose>
            </section>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
