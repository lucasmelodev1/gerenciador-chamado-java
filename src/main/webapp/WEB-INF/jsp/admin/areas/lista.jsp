<%@ page pageEncoding="UTF-8" %>
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

            <%-- Criar e editar usam o MESMO `ui:drawer`, sem ida ao servidor para abrir.
                 O drawer e sempre renderizado no modo de criacao; `ui:acao-editar` carrega
                 a acao e os valores da linha, que o drawer.js aplica antes de abrir.
                 Antes isso dependia de `?areaId=`, e o reload era justamente o que deixava
                 o drawer fechado depois de salvar e exigia um segundo clique. --%>
            <section class="card">
                <div class="card-body">
                    <%-- S26: cabecalho, filtros e acoes saem dos tags `ui:*` documentados em
                         WEB-INF/tags/CONTEXT.md. A tela so declara o que e dela: titulos,
                         colunas e os valores de cada linha. --%>
                    <ui:card-head titulo="Areas cadastradas" descricao="Espacos do condominio">
                        <button type="button" class="btn btn-primary btn-sm" data-drawer-abrir="drawer-area">
                            Nova area
                        </button>
                    </ui:card-head>

                    <div class="app-card-filtros">
                        <ui:busca alvo="areas-table" rotulo="Pesquisar areas" />
                    </div>

                    <c:choose>
                        <c:when test="${empty areas}">
                            <ui:vazio titulo="Nenhuma area cadastrada" mensagem="Cadastre as areas do condominio para uso na operacao." />
                        </c:when>
                        <c:otherwise>
                            <div class="overflow-x-auto">
                                <table class="table table-zebra" data-filter-table="areas-table">
                                    <thead>
                                    <tr>
                                        <th>Nome</th>
                                        <th>Status</th>
                                        <%-- Coluna sem rotulo visivel: as acoes passaram a ser so
                                             icone (com tooltip), entao o texto vive aqui, para
                                             quem nao ve o icone. --%>
                                        <th><span class="sr-only">Ações</span></th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    <c:forEach items="${areas}" var="area">
                                        <tr>
                                            <td>${area.nome}</td>
                                            <%-- Status e um conjunto FECHADO de dois valores (CHECK na
                                                 migration V19), entao o mapeamento pode ser literal.
                                                 Mesma ideia de `fragments/reserva-status.jspf`. --%>
                                            <td>
                                                <ui:badge variante="${area.status eq 'Ativo' ? 'success' : 'neutral'}">${area.status}</ui:badge>
                                            </td>
                                            <td class="cell-actions app-tabela-acoes">
                                                <ui:acao-editar drawer="drawer-area" titulo="Editar area"
                                                                acao="${ctx}/admin/areas/${area.id}">
                                                    <input type="hidden" data-campo="nome" value="${fn:escapeXml(area.nome)}">
                                                    <input type="hidden" data-campo="status" value="${fn:escapeXml(area.status)}">
                                                </ui:acao-editar>
                                                <ui:acao-form acao="${ctx}/admin/areas/${area.id}"
                                                              icone="remover" rotulo="Remover" perigo="true"
                                                              confirmacao="Remover esta area? As reservas existentes serao preservadas." />
                                            </td>
                                        </tr>
                                    </c:forEach>
                                    </tbody>
                                </table>
                            </div>
                        </c:otherwise>
                    </c:choose>

                    <ui:paginacao pagina="${areasPage}" url="${ctx}/admin/areas" />
                </div>
            </section>
        </main>
    </div>
</div>

<%-- Fora de `.page-content` de proposito: la o legado aplica
     `.page-content > * { width: min(100%, 1360px); margin-inline: auto }`, que espremeria
     o backdrop do drawer e deixaria as bordas da tela claras. Ver custom.css > Drawer. --%>
<ui:drawer id="drawer-area"
           titulo="Nova area"
           descricao="Cadastre um espaco do condominio para uso nas reservas."
           acao="${ctx}/admin/areas">
    <label class="field">
        <span>Nome</span>
        <input class="input w-full" type="text" name="nome" placeholder="Piscina" maxlength="255" required>
    </label>

    <label class="field">
        <span>Status</span>
        <select class="select w-full" name="status" required>
            <c:forEach items="${statusAreaDisponiveis}" var="statusArea">
                <option value="${statusArea.valor}">${statusArea.valor}</option>
            </c:forEach>
        </select>
    </label>
</ui:drawer>

<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
