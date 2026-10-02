<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="admin-usuario-detalhe">

            <section class="two-column-grid">
                <article class="card">
                    <div class="card-body">
                    <ui:card-head titulo="${usuario.nome}" descricao="Edicao">
                        <ui:badge>${usuario.tipo}</ui:badge>
                    </ui:card-head>

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

                    <ui:acao-form acao="${ctx}/admin/usuarios/${usuario.id}" texto="Remover usuario"
                                  variante="error" classe="inline-form danger-zone"
                                  confirmacao="Remover este usuario? A acao nao pode ser desfeita." />
                                    </div>
                </article>

                <c:if test="${usuario.role eq 'ROLE_MORADOR'}">
                    <article class="card">
                        <div class="card-body">
                        <ui:card-head titulo="Unidades do morador" descricao="Vinculos" />

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
                                            <ui:acao-form acao="${ctx}/admin/moradores/${usuario.id}/unidades/${unidade.id}"
                                                          texto="Desvincular" variante="error" classe="inline-form"
                                                          confirmacao="Desvincular esta unidade do morador?">
                                                <c:if test="${not empty blocoSelecionadoId}">
                                                    <input type="hidden" name="blocoId" value="${blocoSelecionadoId}">
                                                </c:if>
                                            </ui:acao-form>
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
                                                <ui:badge variante="${unidade.vinculadaAoMorador ? 'success' : 'neutral'}">${unidade.vinculadaAoMorador ? 'Vinculada' : 'Disponivel'}</ui:badge>
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
                        <ui:card-head titulo="Tipos de chamado do colaborador" descricao="Escopo" />

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
                                            <ui:acao-form acao="${ctx}/admin/colaboradores/${usuario.id}/tipos-chamado/${tipoChamado.id}"
                                                          texto="Desvincular" variante="error" classe="inline-form"
                                                          confirmacao="Desvincular este tipo de chamado do colaborador?" />
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
</ui:shell>
<ui:shell-fim />
