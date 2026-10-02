<%@ page pageEncoding="UTF-8" %>
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
                            <ui:vazio titulo="Nenhum chamado encontrado" mensagem="Altere os filtros ou aguarde novas aberturas." />
                        </c:when>
                        <c:otherwise>
                            <ui:tabela-chamados itens="${chamados}" base="${ctx}/admin/chamados"
                                                mostrarMorador="true" acaoIcone="ver" acaoRotulo="Detalhar" />
                        </c:otherwise>
                    </c:choose>

                    <%-- A paginacao repete os filtros: sem isso, paginar perderia o recorte. --%>
                    <ui:paginacao pagina="${chamadosPage}" url="${ctx}/admin/chamados" parametros="&statusId=${filtroStatusId}&moradorNome=${filtroMoradorNome}&dataAbertura=${filtroDataAbertura}" />
                </div>
            </section>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
