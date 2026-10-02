<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="admin-escopo-colaborador">

            <section class="app-grade-lateral">
                <article class="card">
                    <div class="card-body">
                    <ui:card-head titulo="Designar colaborador por tipo" descricao="Operacao" />

                    <form method="get" action="${ctx}/admin/escopo-colaborador" class="grid gap-4 mt-4">
                        <ui:campo rotulo="Buscar por e-mail">
                            <input class="input w-full" type="text" name="colaboradorEmail" value="${filtroColaboradorEmail}" placeholder="Ex.: ana" />
                        </ui:campo>
                        <ui:campo rotulo="Colaborador">
                            <select class="select w-full" name="colaboradorId" data-auto-submit>
                                <option value="">Escolha um colaborador</option>
                                <c:forEach items="${colaboradoresDisponiveis}" var="colaborador">
                                    <option value="${colaborador.id}" ${colaboradorSelecionadoId eq colaborador.id ? 'selected' : ''}>
                                        ${colaborador.nome} - ${colaborador.email}
                                    </option>
                                </c:forEach>
                            </select>
                        </ui:campo>
                        <div class="flex flex-wrap items-center gap-3">
                            <button type="submit" class="btn btn-primary">Buscar colaborador</button>
                            <a href="${ctx}/admin/escopo-colaborador" class="btn">Limpar</a>
                        </div>
                    </form>

                    <c:if test="${not empty colaboradorSelecionado}">
                        <div class="divider"></div>
                        <div class="flex items-center justify-between gap-3 rounded-xl border border-base-content/10 bg-base-100 px-4.5 py-4 transition duration-200">
                            <div>
                                <strong>${colaboradorSelecionado.nome}</strong>
                                <span class="text-base-content/60">${colaboradorSelecionado.email}</span>
                            </div>
                            <a href="${ctx}/admin/usuarios/${colaboradorSelecionado.id}" class="btn">Abrir cadastro</a>
                        </div>

                        <c:choose>
                            <c:when test="${empty tiposChamadoColaborador}">
                                <ui:vazio mensagem="Este colaborador ainda nao possui tipos de chamado vinculados." compacto="true" />
                            </c:when>
                            <c:otherwise>
                                <div class="grid gap-4">
                                    <c:forEach items="${tiposChamadoColaborador}" var="tipoChamado">
                                        <div class="flex items-center justify-between gap-3 rounded-xl border border-base-content/10 bg-base-100 px-4.5 py-4 transition duration-200">
                                            <div>
                                                <strong>${tipoChamado.titulo}</strong>
                                                <span class="text-base-content/60">Prazo: ${tipoChamado.prazoHoras}h</span>
                                            </div>
                                            <ui:acao-form acao="${ctx}/admin/colaboradores/${colaboradorSelecionado.id}/tipos-chamado/${tipoChamado.id}?dashboard=true"
                                                          texto="Desvincular" variante="error" classe="flex flex-wrap items-center gap-3"
                                                          confirmacao="Desvincular este tipo de chamado do colaborador?" />
                                        </div>
                                    </c:forEach>
                                </div>
                            </c:otherwise>
                        </c:choose>

                        <div class="divider"></div>

                        <form method="post" action="${ctx}/admin/colaboradores/${colaboradorSelecionado.id}/tipos-chamado?dashboard=true" class="grid gap-4 mt-4">
                            <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                            <input type="hidden" name="_method" value="put">
                            <ui:campo rotulo="Selecionar tipo de chamado">
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
                            </ui:campo>
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
                                            <td class="app-tabela-acoes">
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
