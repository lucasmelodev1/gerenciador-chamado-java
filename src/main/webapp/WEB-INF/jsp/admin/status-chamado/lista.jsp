<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-status">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>
            <c:set var="statusChamadoAction" value="${ctx}/admin/status-chamado" />
            <c:if test="${not empty statusEdicao}">
                <c:set var="statusChamadoAction" value="${ctx}/admin/status-chamado/${statusEdicao.id}" />
            </c:if>
            <c:set var="statusEdicaoBloqueada" value="${statusEdicaoBloqueada eq true}" />

            <section class="two-column-grid">
                <article class="card">
                    <div class="card-body">
                    <div class="section-header">
                        <div>
                            <p class="eyebrow">Fluxo</p>
                            <h2><c:choose><c:when test="${not empty statusEdicao}">Editar status</c:when><c:otherwise>Novo status</c:otherwise></c:choose></h2>
                        </div>
                    </div>

                    <form method="post" action="${statusChamadoAction}" class="stack-form">
                        <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                        <c:if test="${not empty statusEdicao}">
                            <input type="hidden" name="_method" value="patch">
                        </c:if>
                        <label class="field">
                            <span>Nome do status</span>
                            <input class="input w-full" type="text" name="nome" value="${statusChamadoForm.nome}" placeholder="Em atendimento" maxlength="255" required ${statusEdicaoBloqueada ? 'disabled' : ''}>
                        </label>
                        <c:if test="${statusEdicaoBloqueada}">
                            <p class="helper-text">Os status Finalizado, Atrasado e Solicitado sao reservados e nao podem ser editados.</p>
                        </c:if>
                        <div class="button-row">
                            <button type="submit" class="btn btn-primary" ${statusEdicaoBloqueada ? 'disabled' : ''}>
                                <c:choose><c:when test="${not empty statusEdicao}">Salvar status</c:when><c:otherwise>Cadastrar status</c:otherwise></c:choose>
                            </button>
                            <c:if test="${not empty statusEdicao}">
                                <a href="${ctx}/admin/status-chamado" class="btn">Cancelar</a>
                            </c:if>
                        </div>
                    </form>
                                    </div>
                </article>

                <article class="card">
                    <div class="card-body">
                    <div class="section-header">
                        <div>
                            <p class="eyebrow">Estados do chamado</p>
                            <h2>Status configurados</h2>
                        </div>
                    </div>

                    <c:choose>
                        <c:when test="${empty statusChamado}">
                            <c:set var="vazioTitulo" value="Nenhum status cadastrado" />
                            <c:set var="vazioMensagem" value="Cadastre ao menos um status e marque o inicial padrao." />
                            <%@ include file="/WEB-INF/jsp/fragments/vazio.jspf" %>
                        </c:when>
                        <c:otherwise>
                            <div class="stack-list">
                                <c:forEach items="${statusChamado}" var="status">
                                    <div class="list-row status-row">
                                        <div>
                                            <strong>${status.nome}</strong>
                                            <span><c:if test="${status.inicialPadrao}">Status inicial padrao</c:if><c:if test="${not status.inicialPadrao}">Disponivel para fluxo operacional</c:if></span>
                                        </div>
                                        <div class="button-row">
                                            <c:if test="${status.editavel}">
                                                <a href="${ctx}/admin/status-chamado?statusId=${status.id}" class="btn">Editar</a>
                                            </c:if>
                                            <c:if test="${not status.editavel}">
                                                <span class="btn disabled" aria-disabled="true">Reservado</span>
                                            </c:if>
                                            <form method="post" action="${ctx}/admin/status-chamado/${status.id}/inicial-padrao" class="inline-form" data-confirm="Definir este status como inicial padrao?">
                                                <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                                                <input type="hidden" name="_method" value="patch">
                                                <button type="submit" class="btn btn-primary" ${status.inicialPadrao ? 'disabled' : ''}>
                                                    Tornar padrao
                                                </button>
                                            </form>
                                        </div>
                                    </div>
                                </c:forEach>
                            </div>
                        </c:otherwise>
                    </c:choose>

                    <div class="pagination">
                        <c:if test="${statusChamadoPage.hasPrevious}">
                            <a class="btn" href="${ctx}/admin/status-chamado?page=${statusChamadoPage.page - 1}&size=${statusChamadoPage.size}">Anterior</a>
                        </c:if>
                        <span>Pagina ${statusChamadoPage.page + 1} de ${statusChamadoPage.totalPages == 0 ? 1 : statusChamadoPage.totalPages}</span>
                        <c:if test="${statusChamadoPage.hasNext}">
                            <a class="btn" href="${ctx}/admin/status-chamado?page=${statusChamadoPage.page + 1}&size=${statusChamadoPage.size}">Proxima</a>
                        </c:if>
                    </div>
                                    </div>
                </article>
            </section>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
