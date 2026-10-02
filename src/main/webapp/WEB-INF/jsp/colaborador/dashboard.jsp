<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="colaborador-dashboard">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <section class="stats-grid">
                <article class="stat-card">
                    <span>Chamados atrasados</span>
                    <strong>${totalChamadosAtrasados}</strong>
                </article>
                <article class="stat-card stat-card-wide">
                    <span>Chamados em atendimento</span>
                    <strong>${totalChamadosAbertos}</strong>
                    <a href="${ctx}/colaborador/chamados" class="btn btn-primary">Abrir fila</a>
                </article>
            </section>

            <section class="card">
                <div class="card-body">
                <div class="section-header">
                    <div>
                        <p class="eyebrow">Fila imediata</p>
                        <h2>Chamados recentes</h2>
                    </div>
                </div>

                <c:choose>
                    <c:when test="${empty chamados}">
                        <c:set var="vazioTitulo" value="Nenhum chamado disponivel no seu escopo" />
                        <c:set var="vazioMensagem" value="Quando surgirem novos atendimentos eles aparecerao aqui." />
                        <%@ include file="/WEB-INF/jsp/fragments/vazio.jspf" %>
                    </c:when>
                    <c:otherwise>
                        <div class="overflow-x-auto">
                            <table class="table table-zebra">
                                <thead>
                                <tr>
                                    <th>Unidade</th>
                                    <th>Tipo</th>
                                    <th>Status</th>
                                    <th></th>
                                </tr>
                                </thead>
                                <tbody>
                                <c:forEach items="${chamados}" var="chamado">
                                    <tr>
                                        <td>${chamado.unidadeIdentificacao}</td>
                                        <td>${chamado.tipoChamadoTitulo}</td>
                                        <td><span class="badge badge-ghost">${chamado.statusNome}</span></td>
                                        <td class="cell-actions">
                                            <a href="${ctx}/colaborador/chamados/${chamado.id}" class="btn btn-link">Atender</a>
                                        </td>
                                    </tr>
                                </c:forEach>
                                </tbody>
                            </table>
                        </div>
                    </c:otherwise>
                </c:choose>
                            </div>
            </section>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
