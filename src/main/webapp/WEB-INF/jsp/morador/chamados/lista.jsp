<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="morador-chamados">

            <section class="card">
                <div class="card-body">
                    <ui:card-head titulo="Meus chamados" descricao="Historico">
                        <a href="${ctx}/morador/chamados/novo" class="btn btn-primary">Abrir chamado</a>
                    </ui:card-head>

                    <form method="get" action="${ctx}/morador/chamados" class="app-card-filtros app-card-filtros--campos">
                        <ui:campo rotulo="Status">
                            <select class="select" name="statusId">
                                <option value="">Todos</option>
                                <c:forEach items="${statusDisponiveis}" var="status">
                                    <option value="${status.id}" ${filtroStatusId eq status.id ? 'selected' : ''}>${status.nome}</option>
                                </c:forEach>
                            </select>
                        </ui:campo>
                        <ui:campo rotulo="Unidade">
                            <select class="select" name="unidadeId">
                                <option value="">Todas</option>
                                <c:forEach items="${unidadesDisponiveis}" var="unidade">
                                    <option value="${unidade.id}" ${filtroUnidadeId eq unidade.id ? 'selected' : ''}>${unidade.identificacao}</option>
                                </c:forEach>
                            </select>
                        </ui:campo>
                        <ui:campo rotulo="Tipo">
                            <select class="select" name="tipoChamadoId">
                                <option value="">Todos</option>
                                <c:forEach items="${tiposChamadoDisponiveis}" var="tipo">
                                    <option value="${tipo.id}" ${filtroTipoChamadoId eq tipo.id ? 'selected' : ''}>${tipo.titulo}</option>
                                </c:forEach>
                            </select>
                        </ui:campo>
                        <ui:campo rotulo="Data de abertura">
                            <input class="input" type="date" name="dataAbertura" value="${filtroDataAbertura}">
                        </ui:campo>
                        <div class="flex flex-wrap items-center gap-3">
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
</ui:shell>
<ui:shell-fim />
