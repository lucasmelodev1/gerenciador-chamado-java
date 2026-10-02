<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="admin-reservas-lista">

            <%-- Decisao da reserva. Aprovar e direto; negar e cancelar passam por um
                 dialogo CENTRAL, e negar pede o motivo.

                 Os dois dialogos sao unicos e reaproveitados: o gatilho de cada linha
                 (`ui:acao-editar`) leva a acao daquela reserva, e o drawer.js limpa o
                 motivo digitado entre uma linha e outra. Antes o motivo era um `<input>`
                 solto dentro da celula de acoes, que estourava a coluna. --%>
            <section class="card">
                <div class="card-body">
                    <ui:card-head titulo="Reservas das áreas comuns" descricao="Agenda única">
                        <a href="${ctx}/admin/reservas/agenda" class="btn btn-sm">Ver agenda</a>
                    </ui:card-head>

                    <c:choose>
                        <c:when test="${empty reservas}">
                            <ui:vazio titulo="Nenhuma reserva registrada" mensagem="As solicitações dos moradores aparecerão aqui para decisão." />
                        </c:when>
                        <c:otherwise>
                            <div class="overflow-x-auto">
                                <table class="table table-zebra">
                                    <thead>
                                    <tr>
                                        <th>Área</th>
                                        <th>Morador</th>
                                        <th>Unidade</th>
                                        <th>Início</th>
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
                                            <td>${reserva.moradorNome}</td>
                                            <td>${reserva.unidadeIdentificacao}</td>
                                            <td>${reserva.inicioFormatado}</td>
                                            <td>${reserva.fimFormatado}</td>
                                            <td><ui:reserva-status status="${reserva.status}" /></td>
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

                    <ui:paginacao pagina="${reservasPage}" url="${ctx}/admin/reservas" />
                </div>
            </section>
</ui:shell>

<%-- Fora de `.page-content`: o legado espremeria o backdrop. Ver custom.css > Dialogo. --%>
<ui:dialog id="dialog-negacao"
           titulo="Negar reserva"
           descricao="O motivo fica visível para o morador na lista de reservas dele."
           acao="${ctx}/admin/reservas"
           rotuloConfirmar="Negar" varianteConfirmar="error" iconeConfirmar="negar"
           rotuloCancelar="Voltar">
    <%-- Sem rotulo visivel: o proprio placeholder e o titulo do campo, e o `aria-label`
         mantem o nome acessivel (o dialogo ja explica o porque na descricao). --%>
    <input class="input w-full" type="text" name="motivo" maxlength="255"
           placeholder="Motivo da negação" aria-label="Motivo da negação" required>
</ui:dialog>

<ui:dialog id="dialog-cancelamento"
           titulo="Cancelar reserva"
           descricao="O horário volta a ficar livre na agenda. Não é preciso informar um motivo."
           acao="${ctx}/admin/reservas"
           rotuloConfirmar="Cancelar reserva" varianteConfirmar="error" iconeConfirmar="fechar"
           rotuloCancelar="Voltar" />

<ui:shell-fim />
