<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-usuario-detalhe">
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
                            <p class="eyebrow">Edicao</p>
                            <h2>${usuario.nome}</h2>
                        </div>
                        <span class="badge badge-neutral">${usuario.tipo}</span>
                    </div>

                    <form method="post" action="${ctx}/admin/usuarios/${usuario.id}" class="stack-form">
                        <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                        <input type="hidden" name="_method" value="patch">
                        <label class="field">
                            <span>Nome</span>
                            <input class="input w-full" type="text" name="nome" value="${usuarioForm.nome}" maxlength="255" required>
                        </label>
                        <label class="field">
                            <span>Email</span>
                            <input class="input w-full" type="email" name="email" value="${usuarioForm.email}" maxlength="255" required>
                        </label>
                        <label class="field">
                            <span>Perfil</span>
                            <input class="input w-full" type="text" value="${usuario.tipo}" disabled>
                            <input type="hidden" name="tipo" value="${usuarioForm.tipo}">
                        </label>
                        <label class="field">
                            <span>Nova senha</span>
                            <div class="password-field">
                                <input class="input w-full" type="password" name="senha" placeholder="Obrigatorio para salvar" maxlength="255" required data-password-input>
                                <button type="button" class="btn btn-ghost" data-password-toggle>Mostrar</button>
                            </div>
                        </label>
                        <div class="button-row">
                            <button type="submit" class="btn btn-primary">Salvar alteracoes</button>
                            <a href="${ctx}/admin/usuarios" class="btn">Voltar</a>
                        </div>
                    </form>

                    <form method="post" action="${ctx}/admin/usuarios/${usuario.id}" data-confirm="Remover este usuario? A acao nao pode ser desfeita." class="inline-form danger-zone">
                        <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                        <input type="hidden" name="_method" value="delete">
                        <button type="submit" class="btn btn-error">Remover usuario</button>
                    </form>
                                    </div>
                </article>

                <c:if test="${usuario.role eq 'ROLE_MORADOR'}">
                    <article class="card">
                        <div class="card-body">
                        <div class="section-header">
                            <div>
                                <p class="eyebrow">Vinculos</p>
                                <h2>Unidades do morador</h2>
                            </div>
                        </div>

                        <c:choose>
                            <c:when test="${empty unidadesMorador}">
                                <ui:vazio mensagem="Nenhuma unidade vinculada." compacto="true" />
                            </c:when>
                            <c:otherwise>
                                <div class="stack-list">
                                    <c:forEach items="${unidadesMorador}" var="unidade">
                                        <div class="list-row">
                                            <div>
                                                <strong>${unidade.identificacao}</strong>
                                                <span>${unidade.blocoIdentificacao} - Andar ${unidade.andar}</span>
                                            </div>
                                            <form method="post" action="${ctx}/admin/moradores/${usuario.id}/unidades/${unidade.id}" data-confirm="Desvincular esta unidade do morador?" class="inline-form">
                                                <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                                                <input type="hidden" name="_method" value="delete">
                                                <c:if test="${not empty blocoSelecionadoId}">
                                                    <input type="hidden" name="blocoId" value="${blocoSelecionadoId}">
                                                </c:if>
                                                <button type="submit" class="btn btn-error">Desvincular</button>
                                            </form>
                                        </div>
                                    </c:forEach>
                                </div>
                            </c:otherwise>
                        </c:choose>

                        <div class="divider"></div>

                        <form method="get" action="${ctx}/admin/usuarios/${usuario.id}" class="stack-form compact-form">
                            <label class="field">
                                <span>Selecionar bloco para vincular</span>
                                <select class="select w-full" name="blocoId" data-auto-submit>
                                    <option value="">Escolha um bloco</option>
                                    <c:forEach items="${blocosDisponiveis}" var="bloco">
                                        <option value="${bloco.id}" ${blocoSelecionadoId eq bloco.id ? 'selected' : ''}>
                                            ${bloco.identificacao}
                                        </option>
                                    </c:forEach>
                                </select>
                            </label>
                        </form>

                        <c:if test="${not empty unidadesBloco}">
                            <form method="post" action="${ctx}/admin/moradores/${usuario.id}/unidades" class="stack-form compact-form">
                                <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                                <input type="hidden" name="_method" value="put">
                                <input type="hidden" name="blocoId" value="${blocoSelecionadoId}">
                                <label class="field">
                                    <span>Selecionar unidade</span>
                                    <select class="select w-full" name="unidadeId" required>
                                        <option value="">Escolha uma unidade</option>
                                        <c:forEach items="${unidadesBloco}" var="unidade">
                                            <option value="${unidade.id}" ${unidade.vinculadaAoMorador ? 'disabled' : ''}>
                                                ${unidade.identificacao} - Andar ${unidade.andar}
                                                ${unidade.vinculadaAoMorador ? ' (ja vinculada)' : ''}
                                            </option>
                                        </c:forEach>
                                    </select>
                                </label>
                                <button type="submit" class="btn btn-primary">Vincular unidade</button>
                            </form>

                            <div class="overflow-x-auto">
                                <table class="table table-zebra table-sm">
                                    <thead>
                                    <tr>
                                        <th>Unidade</th>
                                        <th>Andar</th>
                                        <th>Status</th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    <c:forEach items="${unidadesBloco}" var="unidade">
                                        <tr>
                                            <td>${unidade.identificacao}</td>
                                            <td>${unidade.andar}</td>
                                            <td>
                                                <span class="badge ${unidade.vinculadaAoMorador ? 'badge-success' : 'badge-neutral'}">
                                                    ${unidade.vinculadaAoMorador ? 'Vinculada' : 'Disponivel'}
                                                </span>
                                            </td>
                                        </tr>
                                    </c:forEach>
                                    </tbody>
                                </table>
                            </div>
                        </c:if>
                                            </div>
                    </article>
                </c:if>

                <c:if test="${usuario.role eq 'ROLE_COLABORADOR'}">
                    <article class="card">
                        <div class="card-body">
                        <div class="section-header">
                            <div>
                                <p class="eyebrow">Escopo</p>
                                <h2>Tipos de chamado do colaborador</h2>
                            </div>
                        </div>

                        <c:choose>
                            <c:when test="${empty tiposChamadoColaborador}">
                                <ui:vazio mensagem="Nenhum tipo de chamado vinculado." compacto="true" />
                            </c:when>
                            <c:otherwise>
                                <div class="stack-list">
                                    <c:forEach items="${tiposChamadoColaborador}" var="tipoChamado">
                                        <div class="list-row">
                                            <div>
                                                <strong>${tipoChamado.titulo}</strong>
                                                <span>Prazo: ${tipoChamado.prazoHoras}h</span>
                                            </div>
                                            <form method="post" action="${ctx}/admin/colaboradores/${usuario.id}/tipos-chamado/${tipoChamado.id}" data-confirm="Desvincular este tipo de chamado do colaborador?" class="inline-form">
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

                        <form method="post" action="${ctx}/admin/colaboradores/${usuario.id}/tipos-chamado" class="stack-form compact-form">
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
                                            </div>
                    </article>
                </c:if>
            </section>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
