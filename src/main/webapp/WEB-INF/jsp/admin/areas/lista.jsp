<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-areas">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <%-- Formulario no `ui:drawer` (S23). A tela tem dois estados, e o servidor
                 renderiza o drawer ja no estado certo:
                   - `?areaId=<id>`  -> edicao; o drawer abre sozinho (`aberto="true"`);
                   - sem query       -> cadastro; o botao "Nova area" abre pelo JS. --%>
            <c:set var="areaEditando" value="${not empty areaEdicao}" />
            <c:set var="areaAction" value="${ctx}/admin/areas" />
            <c:if test="${areaEditando}">
                <c:set var="areaAction" value="${ctx}/admin/areas/${areaEdicao.id}" />
            </c:if>

            <section class="card">
                <div class="card-body">
                    <div class="section-header">
                        <div>
                            <p class="eyebrow">Espacos do condominio</p>
                            <h2>Areas cadastradas</h2>
                        </div>
                        <div class="toolbar-inline">
                            <input type="search" class="input input-sm" placeholder="Filtrar localmente"
                                   data-filter-input data-filter-target="areas-table">

                            <%-- Em modo edicao o drawer ja esta aberto no estado "editar":
                                 o botao precisa voltar para a URL limpa, senao abriria o
                                 mesmo drawer ainda apontando para a area editada. --%>
                            <c:choose>
                                <c:when test="${areaEditando}">
                                    <a class="btn btn-primary btn-sm" href="${ctx}/admin/areas">Nova area</a>
                                </c:when>
                                <c:otherwise>
                                    <button type="button" class="btn btn-primary btn-sm" data-drawer-abrir="drawer-area">
                                        Nova area
                                    </button>
                                </c:otherwise>
                            </c:choose>
                        </div>
                    </div>

                    <c:choose>
                        <c:when test="${empty areas}">
                            <c:set var="vazioTitulo" value="Nenhuma area cadastrada" />
                            <c:set var="vazioMensagem" value="Cadastre as areas do condominio para uso na operacao." />
                            <%@ include file="/WEB-INF/jsp/fragments/vazio.jspf" %>
                        </c:when>
                        <c:otherwise>
                            <div class="overflow-x-auto">
                                <table class="table table-zebra" data-filter-table="areas-table">
                                    <thead>
                                    <tr>
                                        <th>Nome</th>
                                        <th>Status</th>
                                        <th></th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    <c:forEach items="${areas}" var="area">
                                        <tr>
                                            <td>${area.nome}</td>
                                            <td>${area.status}</td>
                                            <td class="cell-actions">
                                                <a href="${ctx}/admin/areas?areaId=${area.id}" class="btn btn-link">Editar</a>
                                                <form method="post" action="${ctx}/admin/areas/${area.id}" data-confirm="Remover esta area? As reservas existentes serao preservadas.">
                                                    <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                                                    <input type="hidden" name="_method" value="delete">
                                                    <button type="submit" class="btn btn-error">Remover</button>
                                                </form>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                    </tbody>
                                </table>
                            </div>
                        </c:otherwise>
                    </c:choose>

                    <div class="pagination">
                        <c:if test="${areasPage.hasPrevious}">
                            <a class="btn" href="${ctx}/admin/areas?page=${areasPage.page - 1}&size=${areasPage.size}">Anterior</a>
                        </c:if>
                        <span>Pagina ${areasPage.page + 1} de ${areasPage.totalPages == 0 ? 1 : areasPage.totalPages}</span>
                        <c:if test="${areasPage.hasNext}">
                            <a class="btn" href="${ctx}/admin/areas?page=${areasPage.page + 1}&size=${areasPage.size}">Proxima</a>
                        </c:if>
                    </div>
                </div>
            </section>
        </main>
    </div>
</div>

<%-- Fora de `.page-content` de proposito: la o legado aplica
     `.page-content > * { width: min(100%, 1360px); margin-inline: auto }`, que espremeria
     o backdrop do drawer e deixaria as bordas da tela claras. Ver custom.css > Drawer. --%>
<ui:drawer id="drawer-area"
           titulo="${areaEditando ? 'Editar area' : 'Nova area'}"
           descricao="${areaEditando ? 'Atualize os dados do espaco e salve.' : 'Cadastre um espaco do condominio para uso nas reservas.'}"
           acao="${areaAction}"
           rotuloSalvar="${areaEditando ? 'Salvar area' : 'Cadastrar area'}"
           aberto="${areaEditando ? 'true' : 'false'}">
    <c:if test="${areaEditando}">
        <input type="hidden" name="_method" value="patch">
    </c:if>

    <label class="field">
        <span>Nome</span>
        <input class="input w-full" type="text" name="nome" value="${areaForm.nome}" placeholder="Piscina" maxlength="255" required>
    </label>

    <label class="field">
        <span>Status</span>
        <select class="select w-full" name="status" required>
            <c:forEach items="${statusAreaDisponiveis}" var="statusArea">
                <option value="${statusArea.valor}" ${areaForm.status eq statusArea.valor ? 'selected' : ''}>${statusArea.valor}</option>
            </c:forEach>
        </select>
    </label>
</ui:drawer>

<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
