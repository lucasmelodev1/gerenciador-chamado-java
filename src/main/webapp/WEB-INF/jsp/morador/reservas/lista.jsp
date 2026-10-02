<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="morador-reservas-lista">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <section class="card">
                <div class="card-body">
                    <ui:card-head titulo="Minhas reservas" descricao="Areas comuns">
                        <div class="button-row">
                            <a href="${ctx}/morador/reservas/nova" class="btn btn-primary">Nova reserva</a>
                            <a href="${ctx}/morador/reservas/agenda" class="btn">Ver agenda</a>
                            <a href="${ctx}/morador/reservas/disponibilidade" class="btn">Consultar disponibilidade</a>
                        </div>
                    </ui:card-head>

                    <c:choose>
                        <c:when test="${empty reservas}">
                            <ui:vazio titulo="Nenhuma reserva encontrada" mensagem="Solicite a reserva de uma area comum para planejar o uso." />
                        </c:when>
                        <c:otherwise>
                            <div class="overflow-x-auto">
                                <table class="table table-zebra">
                                    <thead>
                                    <tr>
                                        <th>Area</th>
                                        <th>Inicio</th>
                                        <th>Fim</th>
                                        <th>Status</th>
                                        <th>Motivo</th>
                                        <th><span class="sr-only">Ações</span></th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    <c:forEach items="${reservas}" var="reserva">
                                        <tr>
                                            <td>${reserva.areaNome}</td>
                                            <td>${reserva.inicioFormatado}</td>
                                            <td>${reserva.fimFormatado}</td>
                                            <td><ui:reserva-status status="${reserva.status}" /></td>
                                            <td><c:out value="${empty reserva.motivoNegacao ? '-' : reserva.motivoNegacao}" /></td>
                                            <td class="cell-actions">
                                                <c:if test="${reserva.status eq 'Solicitado' or reserva.status eq 'Aprovado'}">
                                                    <ui:acao-form acao="${ctx}/morador/reservas/${reserva.id}"
                                                                  texto="Cancelar" variante="link"
                                                                  confirmacao="Cancelar esta reserva?" />
                                                </c:if>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                    </tbody>
                                </table>
                            </div>
                        </c:otherwise>
                    </c:choose>

                    <ui:paginacao pagina="${reservasPage}" url="${ctx}/morador/reservas" />
                </div>
            </section>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
