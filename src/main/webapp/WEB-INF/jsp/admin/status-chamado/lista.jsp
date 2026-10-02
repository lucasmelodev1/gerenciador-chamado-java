<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="admin-status">

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
                            <ui:vazio titulo="Nenhum status cadastrado" mensagem="Cadastre ao menos um status e marque o inicial padrao." />
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

                    <ui:paginacao pagina="${statusChamadoPage}" url="${ctx}/admin/status-chamado" />
                </div>
            </section>
</ui:shell>

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

<ui:shell-fim />
