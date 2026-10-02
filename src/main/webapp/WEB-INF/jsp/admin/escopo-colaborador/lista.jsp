<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-escopo-colaborador">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <section class="two-column-grid">
                <article class="card">
                    <div class="card-body">
                    <div class="section-header">
                        <div>
                            <p class="eyebrow">Operacao</p>
                            <h2>Designar colaborador por tipo</h2>
                        </div>
                    </div>

                    <form method="get" action="${ctx}/admin/escopo-colaborador" class="stack-form compact-form">
                        <label class="field">
                            <span>Buscar por e-mail</span>
                            <input class="input w-full" type="text" name="colaboradorEmail" value="${filtroColaboradorEmail}" placeholder="Ex.: ana" />
                        </label>
                        <label class="field">
                            <span>Colaborador</span>
                            <select class="select w-full" name="colaboradorId" data-auto-submit>
                                <option value="">Escolha um colaborador</option>
                                <c:forEach items="${colaboradoresDisponiveis}" var="colaborador">
                                    <option value="${colaborador.id}" ${colaboradorSelecionadoId eq colaborador.id ? 'selected' : ''}>
                                        ${colaborador.nome} - ${colaborador.email}
                                    </option>
                                </c:forEach>
                            </select>
                        </label>
                        <div class="button-row">
                            <button type="submit" class="btn btn-primary">Buscar colaborador</button>
                            <a href="${ctx}/admin/escopo-colaborador" class="btn">Limpar</a>
                        </div>
                    </form>

                    <c:if test="${not empty colaboradorSelecionado}">
                        <div class="divider"></div>
                        <div class="list-row">
                            <div>
                                <strong>${colaboradorSelecionado.nome}</strong>
                                <span>${colaboradorSelecionado.email}</span>
                            </div>
                            <a href="${ctx}/admin/usuarios/${colaboradorSelecionado.id}" class="btn">Abrir cadastro</a>
                        </div>

                        <c:choose>
                            <c:when test="${empty tiposChamadoColaborador}">
                                <c:set var="vazioMensagem" value="Este colaborador ainda nao possui tipos de chamado vinculados." />
                                <c:set var="vazioCompacto" value="${true}" />
                                <%@ include file="/WEB-INF/jsp/fragments/vazio.jspf" %>
                            </c:when>
                            <c:otherwise>
                                <div class="stack-list">
                                    <c:forEach items="${tiposChamadoColaborador}" var="tipoChamado">
                                        <div class="list-row">
                                            <div>
                                                <strong>${tipoChamado.titulo}</strong>
                                                <span>Prazo: ${tipoChamado.prazoHoras}h</span>
                                            </div>
                                            <form method="post" action="${ctx}/admin/colaboradores/${colaboradorSelecionado.id}/tipos-chamado/${tipoChamado.id}?dashboard=true" data-confirm="Desvincular este tipo de chamado do colaborador?" class="inline-form">
                                                <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                                                <input type="hidden" name="_method" value="delete">
                                                <button type="submit" class="btn btn-error">Desvincular</button>
                                            </form>
                                        </div>
                                    </c:forEach>
                                </div>
                            </c:otherwise>
                        </c:choose>

                        <div class="divider"></div>

                        <form method="post" action="${ctx}/admin/colaboradores/${colaboradorSelecionado.id}/tipos-chamado?dashboard=true" class="stack-form compact-form">
                            <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                            <input type="hidden" name="_method" value="put">
                            <label class="field">
                                <span>Selecionar tipo de chamado</span>
                                <select class="select w-full" name="tipoChamadoId" required>
                                    <option value="">Escolha um tipo</option>
                                    <c:forEach items="${tiposChamadoDisponiveis}" var="tipoChamado">
                                        <c:set var="tipoChamadoJaVinculado" value="${tiposChamadoResponsaveisIds.contains(tipoChamado.id)}" />
                                        <option value="${tipoChamado.id}" ${tipoChamadoJaVinculado ? 'disabled' : ''}>
                                            ${tipoChamado.titulo} - ${tipoChamado.prazoHoras}h
                                            ${tipoChamadoJaVinculado ? ' (ja vinculado)' : ''}
                                        </option>
                                    </c:forEach>
                                </select>
                            </label>
                            <button type="submit" class="btn btn-primary">Vincular tipo de chamado</button>
                        </form>
                    </c:if>
                                    </div>
                </article>

                <article class="card">
                    <div class="card-body">
                    <div class="section-header">
                        <div>
                            <p class="eyebrow">Consulta</p>
                            <h2>Colaboradores encontrados</h2>
                        </div>
                    </div>

                    <c:choose>
                        <c:when test="${empty colaboradoresDisponiveis}">
                            <c:set var="vazioTitulo" value="Nenhum colaborador encontrado" />
                            <c:set var="vazioMensagem" value="Ajuste o prefixo do e-mail para localizar outro colaborador." />
                            <%@ include file="/WEB-INF/jsp/fragments/vazio.jspf" %>
                        </c:when>
                        <c:otherwise>
                            <div class="overflow-x-auto">
                                <table class="table table-zebra">
                                    <thead>
                                    <tr>
                                        <th>Nome</th>
                                        <th>Email</th>
                                        <th></th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    <c:forEach items="${colaboradoresDisponiveis}" var="colaborador">
                                        <c:url var="selecionarColaboradorUrl" value="/admin/escopo-colaborador">
                                            <c:param name="colaboradorId" value="${colaborador.id}" />
                                            <c:if test="${not empty filtroColaboradorEmail}">
                                                <c:param name="colaboradorEmail" value="${filtroColaboradorEmail}" />
                                            </c:if>
                                        </c:url>
                                        <tr>
                                            <td>${colaborador.nome}</td>
                                            <td>${colaborador.email}</td>
                                            <td class="cell-actions">
                                                <a href="${selecionarColaboradorUrl}" class="btn btn-link">Selecionar</a>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                    </tbody>
                                </table>
                            </div>
                        </c:otherwise>
                    </c:choose>
                                    </div>
                </article>
            </section>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
