<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="morador-reserva-disponibilidade">

            <section class="card">
                <div class="card-body">
                <ui:card-head titulo="Disponibilidade" descricao="Areas comuns">
                    <a href="${ctx}/morador/reservas" class="btn">Minhas reservas</a>
                </ui:card-head>

                <form method="get" action="${ctx}/morador/reservas/disponibilidade" class="inline-panel">
                    <label class="field">
                        <span>Area</span>
                        <select class="select w-full" name="areaId" required>
                            <option value="">Selecione uma area</option>
                            <c:forEach items="${areas}" var="area">
                                <option value="${area.id}" ${areaId eq area.id ? 'selected' : ''}>${area.nome}</option>
                            </c:forEach>
                        </select>
                    </label>
                    <label class="field">
                        <span>Data</span>
                        <input class="input w-full" type="date" name="data" value="${data}" required>
                    </label>
                    <button type="submit" class="btn btn-primary">Consultar</button>
                </form>

                <c:choose>
                    <c:when test="${not consultou}">
                        <ui:vazio mensagem="Selecione uma area e uma data para consultar a disponibilidade." compacto="true" />
                    </c:when>
                    <c:when test="${empty disponibilidade}">
                        <ui:vazio mensagem="Nenhuma reserva aprovada ou pendente para esta area nesta data." compacto="true" />
                    </c:when>
                    <c:otherwise>
                        <div class="overflow-x-auto">
                            <table class="table table-zebra">
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
                                            <ui:reserva-status status="${reserva.status}" />
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
                            </div>
            </section>
</ui:shell>
<ui:shell-fim />
