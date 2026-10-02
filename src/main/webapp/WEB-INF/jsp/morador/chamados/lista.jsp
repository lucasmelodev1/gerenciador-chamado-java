<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="morador-chamados">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <section class="card">
                <div class="card-body">
                    <ui:card-head titulo="Meus chamados" descricao="Historico">
                        <a href="${ctx}/morador/chamados/novo" class="btn btn-primary">Abrir chamado</a>
                    </ui:card-head>

                    <form method="get" action="${ctx}/morador/chamados" class="app-card-filtros app-card-filtros--campos">
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
                            <span>Unidade</span>
                            <select class="select" name="unidadeId">
                                <option value="">Todas</option>
                                <c:forEach items="${unidadesDisponiveis}" var="unidade">
                                    <option value="${unidade.id}" ${filtroUnidadeId eq unidade.id ? 'selected' : ''}>${unidade.identificacao}</option>
                                </c:forEach>
                            </select>
                        </label>
                        <label class="field">
                            <span>Tipo</span>
                            <select class="select" name="tipoChamadoId">
                                <option value="">Todos</option>
                                <c:forEach items="${tiposChamadoDisponiveis}" var="tipo">
                                    <option value="${tipo.id}" ${filtroTipoChamadoId eq tipo.id ? 'selected' : ''}>${tipo.titulo}</option>
                                </c:forEach>
                            </select>
                        </label>
                        <label class="field">
                            <span>Data de abertura</span>
                            <input class="input" type="date" name="dataAbertura" value="${filtroDataAbertura}">
                        </label>
                        <div class="button-row">
                            <button type="submit" class="btn btn-primary">Filtrar</button>
                            <a href="${ctx}/morador/chamados" class="btn">Limpar</a>
                        </div>
                    </form>

                    <c:choose>
                        <c:when test="${empty chamados}">
                            <ui:vazio titulo="Nenhum chamado registrado" mensagem="Use a abertura de chamado para registrar a primeira ocorrencia." />
                        </c:when>
                        <c:otherwise>
                            <ui:tabela-chamados itens="${chamados}" base="${ctx}/morador/chamados"
                                                acaoTexto="Acompanhar" acaoRotulo="Acompanhar" />
                        </c:otherwise>
                    </c:choose>

                    <ui:paginacao pagina="${chamadosPage}" url="${ctx}/morador/chamados" parametros="&statusId=${filtroStatusId}&unidadeId=${filtroUnidadeId}&tipoChamadoId=${filtroTipoChamadoId}&dataAbertura=${filtroDataAbertura}" />
                </div>
            </section>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
