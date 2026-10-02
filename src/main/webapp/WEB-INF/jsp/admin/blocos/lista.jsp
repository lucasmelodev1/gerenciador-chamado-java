<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="admin-blocos">

            <%-- Bloco nao tem endpoint de edicao nem de remocao (BlocoApiController so
                 expoe POST), entao a tabela apenas navega para as unidades; a criacao
                 vive no drawer. --%>
            <section class="card">
                <div class="card-body">
                    <ui:card-head titulo="Blocos cadastrados" descricao="Estrutura do condominio">
                        <button type="button" class="btn btn-primary btn-sm" data-drawer-abrir="drawer-bloco">
                            Novo bloco
                        </button>
                    </ui:card-head>

                    <div class="app-card-filtros">
                        <ui:busca alvo="blocos-table" rotulo="Pesquisar blocos" />
                    </div>

                    <c:choose>
                        <c:when test="${empty blocos}">
                            <ui:vazio titulo="Nenhum bloco cadastrado" mensagem="Cadastre o primeiro bloco para gerar as unidades automaticamente." />
                        </c:when>
                        <c:otherwise>
                            <div class="overflow-x-auto">
                                <table class="table table-zebra" data-filter-table="blocos-table">
                                    <thead>
                                    <tr>
                                        <th>Identificacao</th>
                                        <th>Andares</th>
                                        <th>Aptos/andar</th>
                                        <th><span class="sr-only">Ações</span></th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    <c:forEach items="${blocos}" var="bloco">
                                        <tr>
                                            <td>${bloco.identificacao}</td>
                                            <td>${bloco.quantidadeAndares}</td>
                                            <td>${bloco.apartamentosPorAndar}</td>
                                            <td class="cell-actions app-tabela-acoes">
                                                <ui:acao-link href="${ctx}/admin/blocos/${bloco.id}"
                                                              icone="ver" rotulo="Ver unidades" />
                                            </td>
                                        </tr>
                                    </c:forEach>
                                    </tbody>
                                </table>
                            </div>
                        </c:otherwise>
                    </c:choose>

                    <ui:paginacao pagina="${blocosPage}" url="${ctx}/admin/blocos" />
                </div>
            </section>
</ui:shell>

<%-- Fora de `.app-page`: la o legado aplica
     `.app-page > * { width: min(100%, 1360px); margin-inline: auto }` e espremeria o
     backdrop do drawer. Ver custom.css > Drawer. --%>
<ui:drawer id="drawer-bloco"
           titulo="Novo bloco"
           descricao="As unidades do bloco sao geradas automaticamente."
           acao="${ctx}/admin/blocos">
    <ui:campo rotulo="Identificacao">
        <input class="input w-full" type="text" name="identificacao" value="${blocoForm.identificacao}" placeholder="Bloco A" maxlength="255" required>
    </ui:campo>

    <div class="form-grid">
        <ui:campo rotulo="Andares">
            <input class="input w-full" type="number" name="quantidadeAndares" min="1" value="${blocoForm.quantidadeAndares}" required>
        </ui:campo>
        <ui:campo rotulo="Apartamentos por andar">
            <input class="input w-full" type="number" name="apartamentosPorAndar" min="1" value="${blocoForm.apartamentosPorAndar}" required>
        </ui:campo>
    </div>
</ui:drawer>

<ui:shell-fim />
