<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="admin-areas">

            <%-- Criar e editar usam o MESMO `ui:drawer`, sem ida ao servidor para abrir.
                 O drawer e sempre renderizado no modo de criacao; `ui:acao-painel` carrega
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
                                                 Mesma ideia do `ui:reserva-status`. --%>
                                            <td>
                                                <ui:badge variante="${area.status eq 'Ativo' ? 'success' : 'neutral'}">${area.status}</ui:badge>
                                            </td>
                                            <td class="cell-actions app-tabela-acoes">
                                                <ui:acao-painel painel="drawer-area" titulo="Editar area"
                                                                acao="${ctx}/admin/areas/${area.id}">
                                                    <input type="hidden" data-campo="nome" value="${fn:escapeXml(area.nome)}">
                                                    <input type="hidden" data-campo="status" value="${fn:escapeXml(area.status)}">
                                                </ui:acao-painel>
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
</ui:shell>

<%-- Fora de `.app-page` de proposito: la o legado aplica
     `.app-page > * { width: min(100%, 1360px); margin-inline: auto }`, que espremeria
     o backdrop do drawer e deixaria as bordas da tela claras. Ver custom.css > Drawer. --%>
<ui:drawer id="drawer-area"
           titulo="Nova area"
           descricao="Cadastre um espaco do condominio para uso nas reservas."
           acao="${ctx}/admin/areas">
    <ui:campo rotulo="Nome">
        <input class="input w-full" type="text" name="nome" placeholder="Piscina" maxlength="255" required>
    </ui:campo>

    <ui:campo rotulo="Status">
        <select class="select w-full" name="status" required>
            <c:forEach items="${statusAreaDisponiveis}" var="statusArea">
                <option value="${statusArea.valor}">${statusArea.valor}</option>
            </c:forEach>
        </select>
    </ui:campo>
</ui:drawer>

<ui:shell-fim />
