<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="admin-tipos-chamado">

            <%-- Tipo de chamado nao tem endpoint de remocao (TipoChamadoApiController so
                 expoe POST e PATCH), entao a tabela so oferece a edicao, no drawer. --%>
            <section class="card">
                <div class="card-body">
                    <ui:card-head titulo="Tipos cadastrados" descricao="Parametros de abertura">
                        <button type="button" class="btn btn-primary btn-sm" data-drawer-abrir="drawer-tipo">
                            Novo tipo
                        </button>
                    </ui:card-head>

                    <div class="app-card-filtros">
                        <ui:busca alvo="tipos-table" rotulo="Pesquisar tipos" />
                    </div>

                    <c:choose>
                        <c:when test="${empty tiposChamado}">
                            <ui:vazio titulo="Nenhum tipo cadastrado" mensagem="Cadastre os motivos de abertura de chamado para os moradores." />
                        </c:when>
                        <c:otherwise>
                            <div class="overflow-x-auto">
                                <table class="table table-zebra" data-filter-table="tipos-table">
                                    <thead>
                                    <tr>
                                        <th>Titulo</th>
                                        <th>SLA</th>
                                        <th><span class="sr-only">Ações</span></th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    <c:forEach items="${tiposChamado}" var="tipo">
                                        <tr>
                                            <td>${tipo.titulo}</td>
                                            <td>${tipo.prazoHoras} horas</td>
                                            <td class="cell-actions app-tabela-acoes">
                                                <ui:acao-painel painel="drawer-tipo" titulo="Editar tipo"
                                                                acao="${ctx}/admin/tipos-chamado/${tipo.id}">
                                                    <input type="hidden" data-campo="titulo" value="${fn:escapeXml(tipo.titulo)}">
                                                    <input type="hidden" data-campo="prazoHoras" value="${tipo.prazoHoras}">
                                                </ui:acao-painel>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                    </tbody>
                                </table>
                            </div>
                        </c:otherwise>
                    </c:choose>

                    <ui:paginacao pagina="${tiposChamadoPage}" url="${ctx}/admin/tipos-chamado" />
                </div>
            </section>
</ui:shell>

<%-- Fora de `.page-content`: o legado espremeria o backdrop. Ver custom.css > Drawer.
     O PATCH devolve `?tipoId=<id>` para a listagem — o parametro nao e mais lido por
     ninguem, e o drawer volta fechado. --%>
<ui:drawer id="drawer-tipo"
           titulo="Novo tipo"
           descricao="O prazo define o SLA usado no acompanhamento dos chamados."
           acao="${ctx}/admin/tipos-chamado">
    <label class="field">
        <span>Titulo</span>
        <input class="input w-full" type="text" name="titulo" value="${tipoChamadoForm.titulo}" placeholder="Vazamento" maxlength="255" required>
    </label>

    <label class="field">
        <span>Prazo maximo em horas</span>
        <input class="input w-full" type="number" min="1" name="prazoHoras" value="${tipoChamadoForm.prazoHoras}" required>
    </label>
</ui:drawer>

<ui:shell-fim />
