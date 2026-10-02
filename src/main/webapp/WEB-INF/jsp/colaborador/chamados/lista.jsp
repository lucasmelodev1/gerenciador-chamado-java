<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="colaborador-chamados">

            <section class="card">
                <div class="card-body">
                    <ui:card-head titulo="Fila de chamados" descricao="Atendimento"
                                  subtitulo="Os chamados mais antigos ficam no topo para priorizar a fila." />

                    <form method="get" action="${ctx}/colaborador/chamados" class="app-card-filtros app-card-filtros--campos">
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
                            <span>Tipo</span>
                            <select class="select" name="tipoChamadoId">
                                <option value="">Todos</option>
                                <c:forEach items="${tiposChamadoDisponiveis}" var="tipo">
                                    <option value="${tipo.id}" ${filtroTipoChamadoId eq tipo.id ? 'selected' : ''}>${tipo.titulo}</option>
                                </c:forEach>
                            </select>
                        </label>
                        <label class="field">
                            <span>Pesquisar unidade</span>
                            <input class="input" type="text" name="unidade" value="${filtroUnidade}" placeholder="Ex.: 101">
                        </label>
                        <label class="field">
                            <span>Data de abertura</span>
                            <input class="input" type="date" name="dataAbertura" value="${filtroDataAbertura}">
                        </label>
                        <div class="button-row">
                            <button type="submit" class="btn btn-primary">Filtrar</button>
                            <a href="${ctx}/colaborador/chamados" class="btn">Limpar</a>
                        </div>
                    </form>

                    <c:choose>
                        <c:when test="${empty chamados}">
                            <ui:vazio titulo="Nenhum chamado encontrado" mensagem="Revise os filtros ou aguarde novas ocorrencias no seu escopo." />
                        </c:when>
                        <c:otherwise>
                            <ui:tabela-chamados itens="${chamados}" base="${ctx}/colaborador/chamados"
                                                mostrarMorador="true" acaoTexto="Detalhar" acaoRotulo="Detalhar" />
                        </c:otherwise>
                    </c:choose>

                    <ui:paginacao pagina="${chamadosPage}" url="${ctx}/colaborador/chamados" parametros="&statusId=${filtroStatusId}&tipoChamadoId=${filtroTipoChamadoId}&unidade=${filtroUnidade}&dataAbertura=${filtroDataAbertura}" />
                </div>
            </section>
</ui:shell>
<ui:shell-fim />
