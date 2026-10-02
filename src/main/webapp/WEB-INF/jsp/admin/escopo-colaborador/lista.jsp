<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="admin-escopo-colaborador">

            <section class="two-column-grid">
                <article class="card">
                    <div class="card-body">
                    <ui:card-head titulo="Designar colaborador por tipo" descricao="Operacao" />

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
                                <ui:vazio mensagem="Este colaborador ainda nao possui tipos de chamado vinculados." compacto="true" />
                            </c:when>
                            <c:otherwise>
                                <div class="stack-list">
                                    <c:forEach items="${tiposChamadoColaborador}" var="tipoChamado">
                                        <div class="list-row">
                                            <div>
                                                <strong>${tipoChamado.titulo}</strong>
                                                <span>Prazo: ${tipoChamado.prazoHoras}h</span>
                                            </div>
                                            <ui:acao-form acao="${ctx}/admin/colaboradores/${colaboradorSelecionado.id}/tipos-chamado/${tipoChamado.id}?dashboard=true"
                                                          texto="Desvincular" variante="error" classe="inline-form"
                                                          confirmacao="Desvincular este tipo de chamado do colaborador?" />
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
                    <ui:card-head titulo="Colaboradores encontrados" descricao="Consulta" />

                    <c:choose>
                        <c:when test="${empty colaboradoresDisponiveis}">
                            <ui:vazio titulo="Nenhum colaborador encontrado" mensagem="Ajuste o prefixo do e-mail para localizar outro colaborador." />
                        </c:when>
                        <c:otherwise>
                            <div class="overflow-x-auto">
                                <table class="table table-zebra">
                                    <thead>
                                    <tr>
                                        <th>Nome</th>
                                        <th>Email</th>
                                        <th><span class="sr-only">Ações</span></th>
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
                                                <ui:acao-link href="${selecionarColaboradorUrl}" texto="Selecionar" />
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
</ui:shell>
<ui:shell-fim />
