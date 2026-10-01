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

            <%-- Tela so de leitura: o admin nao abre nem remove chamado, entao o cabecalho
                 nao tem acao e os filtros sao um formulario GET (o unico filtro do sistema
                 que vai ao servidor — os outros sao a busca local do `tables.js`). --%>
            <section class="card">
                <div class="card-body">
                    <ui:card-head titulo="Fila completa de chamados" descricao="Monitoramento" />

                    <form method="get" action="${ctx}/admin/chamados" class="app-card-filtros app-card-filtros--campos">
                        <label class="field">
                            <span>Status</span>
                            <select class="select" name="statusId">
                                <option value="">Todos</option>
                                <c:forEach items="${statusDisponiveis}" var="status">
                                    <option value="${status.id}" ${filtroStatusId eq status.id ? 'selected' : ''}>${status.nome}</option>
                                </c:forEach>
                            </select>
                        </label>
                        <label class="field">
                            <span>Morador</span>
                            <input class="input" type="text" name="moradorNome" value="${filtroMoradorNome}" placeholder="Ex.: mar">
                        </label>
                        <label class="field">
                            <span>Data de abertura</span>
                            <input class="input" type="date" name="dataAbertura" value="${filtroDataAbertura}">
                        </label>
                        <div class="button-row">
                            <button type="submit" class="btn btn-primary">Filtrar</button>
                            <a href="${ctx}/admin/chamados" class="btn">Limpar</a>
                        </div>
                    </form>

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
                                        <th><span class="sr-only">Acoes</span></th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    <c:forEach items="${chamados}" var="chamado">
                                        <tr>
                                            <td>${chamado.unidadeIdentificacao}</td>
                                            <td>${chamado.moradorNome}</td>
                                            <td>${chamado.tipoChamadoTitulo}</td>
                                            <td><ui:badge variante="ghost">${chamado.statusNome}</ui:badge></td>
                                            <td>${chamado.dataAberturaFormatada}</td>
                                            <td class="cell-actions app-tabela-acoes">
                                                <ui:acao-link href="${ctx}/admin/chamados/${chamado.id}"
                                                              icone="ver" rotulo="Detalhar" />
                                            </td>
                                        </tr>
                                    </c:forEach>
                                    </tbody>
                                </table>
                            </div>
                        </c:otherwise>
                    </c:choose>

                    <%-- A paginacao repete os filtros: sem isso, paginar perderia o recorte. --%>
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
