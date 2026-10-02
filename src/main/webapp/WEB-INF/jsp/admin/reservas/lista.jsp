<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-reservas-lista">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <%-- Decisao da reserva. Aprovar e direto; negar e cancelar passam por um
                 dialogo CENTRAL, e negar pede o motivo.

                 Os dois dialogos sao unicos e reaproveitados: o gatilho de cada linha
                 (`ui:acao-editar`) leva a acao daquela reserva, e o drawer.js limpa o
                 motivo digitado entre uma linha e outra. Antes o motivo era um `<input>`
                 solto dentro da celula de acoes, que estourava a coluna. --%>
            <section class="card">
                <div class="card-body">
                    <ui:card-head titulo="Reservas das areas comuns" descricao="Agenda unica">
                        <a href="${ctx}/admin/reservas/agenda" class="btn btn-sm">Ver agenda</a>
                    </ui:card-head>

                    <c:choose>
                        <c:when test="${empty reservas}">
                            <c:set var="vazioTitulo" value="Nenhuma reserva registrada" />
                            <c:set var="vazioMensagem" value="As solicitacoes dos moradores aparecerao aqui para decisao." />
                            <%@ include file="/WEB-INF/jsp/fragments/vazio.jspf" %>
                        </c:when>
                        <c:otherwise>
                            <div class="overflow-x-auto">
                                <table class="table table-zebra">
                                    <thead>
                                    <tr>
                                        <th>Area</th>
                                        <th>Morador</th>
                                        <th>Unidade</th>
                                        <th>Inicio</th>
                                        <th>Fim</th>
                                        <th>Status</th>
                                        <th>Motivo</th>
                                        <th><span class="sr-only">Acoes</span></th>
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
                                            <td><c:set var="reservaStatus" value="${reserva.status}" />
<%@ include file="/WEB-INF/jsp/fragments/reserva-status.jspf" %></td>
                                            <td><c:out value="${empty reserva.motivoNegacao ? '-' : reserva.motivoNegacao}" /></td>
                                            <td class="cell-actions app-tabela-acoes">
                                                <c:if test="${reserva.status eq 'Solicitado'}">
                                                    <ui:acao-form acao="${ctx}/admin/reservas/${reserva.id}/aprovacao"
                                                                  metodo="patch" icone="aprovar" rotulo="Aprovar" />
                                                    <ui:acao-editar drawer="dialog-negacao" titulo="Negar reserva"
                                                                    acao="${ctx}/admin/reservas/${reserva.id}/negacao"
                                                                    icone="negar" rotulo="Negar" />
                                                </c:if>
                                                <c:if test="${reserva.status eq 'Solicitado' or reserva.status eq 'Aprovado'}">
                                                    <ui:acao-editar drawer="dialog-cancelamento" titulo="Cancelar reserva"
                                                                    acao="${ctx}/admin/reservas/${reserva.id}"
                                                                    metodo="delete" icone="fechar" rotulo="Cancelar" />
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
                            <a class="btn" href="${ctx}/admin/reservas?page=${reservasPage.page - 1}&size=${reservasPage.size}">Anterior</a>
                        </c:if>
                        <span>Pagina ${reservasPage.page + 1} de ${reservasPage.totalPages == 0 ? 1 : reservasPage.totalPages}</span>
                        <c:if test="${reservasPage.hasNext}">
                            <a class="btn" href="${ctx}/admin/reservas?page=${reservasPage.page + 1}&size=${reservasPage.size}">Proxima</a>
                        </c:if>
                    </div>
                </div>
            </section>
        </main>
    </div>
</div>

<%-- Fora de `.page-content`: o legado espremeria o backdrop. Ver custom.css > Dialogo. --%>
<ui:dialog id="dialog-negacao"
           titulo="Negar reserva"
           descricao="O motivo fica visivel para o morador na lista de reservas dele."
           acao="${ctx}/admin/reservas"
           rotuloConfirmar="Negar" varianteConfirmar="error" iconeConfirmar="negar"
           rotuloCancelar="Voltar">
    <%-- Sem rotulo visivel: o proprio placeholder e o titulo do campo, e o `aria-label`
         mantem o nome acessivel (o dialogo ja explica o porque na descricao). --%>
    <input class="input w-full" type="text" name="motivo" maxlength="255"
           placeholder="Motivo da negacao" aria-label="Motivo da negacao" required>
</ui:dialog>

<ui:dialog id="dialog-cancelamento"
           titulo="Cancelar reserva"
           descricao="O horario volta a ficar livre na agenda. Nao ha motivo a informar."
           acao="${ctx}/admin/reservas"
           rotuloConfirmar="Cancelar reserva" varianteConfirmar="error" iconeConfirmar="fechar"
           rotuloCancelar="Voltar" />

<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
