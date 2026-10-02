<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="colaborador-chamados">
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
                        <p class="eyebrow">Atendimento</p>
                        <h2>Fila de chamados</h2>
                        <p class="section-subtitle">Os chamados mais antigos ficam no topo para priorizar a fila.</p>
                    </div>
                </div>

                <form method="get" action="${ctx}/colaborador/chamados" class="filter-grid">
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
                        <span>Tipo</span>
                        <select class="select w-full" name="tipoChamadoId">
                            <option value="">Todos</option>
                            <c:forEach items="${tiposChamadoDisponiveis}" var="tipo">
                                <option value="${tipo.id}" ${filtroTipoChamadoId eq tipo.id ? 'selected' : ''}>${tipo.titulo}</option>
                            </c:forEach>
                        </select>
                    </label>
                    <label class="field">
                        <span>Pesquisar unidade</span>
                        <input class="input w-full" type="text" name="unidade" value="${filtroUnidade}" placeholder="Ex.: 101">
                    </label>
                    <label class="field">
                        <span>Data de abertura</span>
                        <input class="input w-full" type="date" name="dataAbertura" value="${filtroDataAbertura}">
                    </label>
                    <div class="button-row align-end">
                        <button type="submit" class="btn btn-primary">Filtrar</button>
                        <a href="${ctx}/colaborador/chamados" class="btn">Limpar</a>
                    </div>
                </form>
                            </div>
            </section>

            <section class="card">
                <div class="card-body">
                <c:choose>
                    <c:when test="${empty chamados}">
                        <ui:vazio titulo="Nenhum chamado encontrado" mensagem="Revise os filtros ou aguarde novas ocorrencias no seu escopo." />
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
                                            <a href="${ctx}/colaborador/chamados/${chamado.id}" class="btn btn-link">Detalhar</a>
                                        </td>
                                    </tr>
                                </c:forEach>
                                </tbody>
                            </table>
                        </div>
                    </c:otherwise>
                </c:choose>

                <ui:paginacao pagina="${chamadosPage}" url="${ctx}/colaborador/chamados" parametros="&statusId=${filtroStatusId}&tipoChamadoId=${filtroTipoChamadoId}&unidade=${filtroUnidade}&dataAbertura=${filtroDataAbertura}" />
                            </div>
            </section>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
