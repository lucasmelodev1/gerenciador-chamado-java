<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-status">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <%-- A lista era um `stack-list` de `.list-row`; virou tabela para usar a mesma
                 coluna de acoes das outras telas. Os tres status reservados do sistema
                 (Finalizado, Atrasado, Solicitado) nao recebem gatilho de edicao: o
                 servidor recusa a troca de nome deles. --%>
            <section class="card">
                <div class="card-body">
                    <ui:card-head titulo="Status configurados" descricao="Estados do chamado">
                        <button type="button" class="btn btn-primary btn-sm" data-drawer-abrir="drawer-status">
                            Novo status
                        </button>
                    </ui:card-head>

                    <div class="app-card-filtros">
                        <ui:busca alvo="status-table" rotulo="Pesquisar status" />
                    </div>

                    <c:choose>
                        <c:when test="${empty statusChamado}">
                            <c:set var="vazioTitulo" value="Nenhum status cadastrado" />
                            <c:set var="vazioMensagem" value="Cadastre ao menos um status e marque o inicial padrao." />
                            <%@ include file="/WEB-INF/jsp/fragments/vazio.jspf" %>
                        </c:when>
                        <c:otherwise>
                            <div class="overflow-x-auto">
                                <table class="table table-zebra" data-filter-table="status-table">
                                    <thead>
                                    <tr>
                                        <th>Nome</th>
                                        <th>Situacao</th>
                                        <th><span class="sr-only">Ações</span></th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    <c:forEach items="${statusChamado}" var="status">
                                        <tr>
                                            <td>${status.nome}</td>
                                            <td>
                                                <span class="flex flex-wrap items-center gap-1">
                                                    <c:choose>
                                                        <c:when test="${status.inicialPadrao}">
                                                            <ui:badge variante="success">Inicial</ui:badge>
                                                        </c:when>
                                                        <c:otherwise>
                                                            <ui:badge variante="neutral">Disponivel</ui:badge>
                                                        </c:otherwise>
                                                    </c:choose>
                                                    <c:if test="${not status.editavel}">
                                                        <ui:badge variante="ghost">Reservado</ui:badge>
                                                    </c:if>
                                                </span>
                                            </td>
                                            <td class="cell-actions app-tabela-acoes">
                                                <c:if test="${status.editavel}">
                                                    <ui:acao-editar drawer="drawer-status" titulo="Editar status"
                                                                    acao="${ctx}/admin/status-chamado/${status.id}">
                                                        <input type="hidden" data-campo="nome" value="${fn:escapeXml(status.nome)}">
                                                    </ui:acao-editar>
                                                </c:if>
                                                <c:if test="${not status.inicialPadrao}">
                                                    <ui:acao-form acao="${ctx}/admin/status-chamado/${status.id}/inicial-padrao"
                                                                  metodo="patch" icone="padrao" rotulo="Tornar padrao"
                                                                  confirmacao="Definir este status como inicial padrao?" />
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
                        <c:if test="${statusChamadoPage.hasPrevious}">
                            <a class="btn" href="${ctx}/admin/status-chamado?page=${statusChamadoPage.page - 1}&size=${statusChamadoPage.size}">Anterior</a>
                        </c:if>
                        <span>Pagina ${statusChamadoPage.page + 1} de ${statusChamadoPage.totalPages == 0 ? 1 : statusChamadoPage.totalPages}</span>
                        <c:if test="${statusChamadoPage.hasNext}">
                            <a class="btn" href="${ctx}/admin/status-chamado?page=${statusChamadoPage.page + 1}&size=${statusChamadoPage.size}">Proxima</a>
                        </c:if>
                    </div>
                </div>
            </section>
        </main>
    </div>
</div>

<%-- Fora de `.page-content`: o legado espremeria o backdrop. Ver custom.css > Drawer. --%>
<ui:drawer id="drawer-status"
           titulo="Novo status"
           descricao="Um status por etapa do atendimento. O inicial e o que o chamado recebe ao abrir."
           acao="${ctx}/admin/status-chamado">
    <label class="field">
        <span>Nome do status</span>
        <input class="input w-full" type="text" name="nome" value="${statusChamadoForm.nome}" placeholder="Em atendimento" maxlength="255" required>
    </label>
</ui:drawer>

<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
