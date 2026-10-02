<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-vinculos-morador">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <%-- Os filtros da tela em duas listas: `vinculosFiltros` (prefixo de e-mail) e
                 `vinculosContexto` (o mesmo mais o morador/bloco selecionados). Antes cada
                 link e cada paginacao repetia os cinco `<c:param>`; agora a string e montada
                 uma vez e reaproveitada pelas paginacoes (`ui:paginacao`) e pelos links
                 "Selecionar". --%>
            <c:set var="vinculosFiltros" value="" />
            <c:if test="${not empty filtroMoradorEmail}">
                <c:set var="vinculosFiltros" value="${vinculosFiltros}&moradorEmail=${filtroMoradorEmail}" />
            </c:if>
            <c:if test="${not empty filtroCadastradosEmail}">
                <c:set var="vinculosFiltros" value="${vinculosFiltros}&cadastradosEmail=${filtroCadastradosEmail}" />
            </c:if>
            <c:if test="${not empty filtroSemUnidadeEmail}">
                <c:set var="vinculosFiltros" value="${vinculosFiltros}&semUnidadeEmail=${filtroSemUnidadeEmail}" />
            </c:if>

            <c:set var="vinculosContexto" value="${vinculosFiltros}" />
            <c:if test="${not empty moradorSelecionadoId}">
                <c:set var="vinculosContexto" value="${vinculosContexto}&moradorId=${moradorSelecionadoId}" />
            </c:if>
            <c:if test="${not empty blocoSelecionadoId}">
                <c:set var="vinculosContexto" value="${vinculosContexto}&blocoId=${blocoSelecionadoId}" />
            </c:if>

            <section class="two-column-grid">
                <article class="card">
                    <div class="card-body">
                    <ui:card-head titulo="Vincular morador a unidade" descricao="Operacao" />

                    <form method="get" action="${ctx}/admin/vinculos-morador" class="stack-form compact-form">
                        <label class="field">
                            <span>Buscar por e-mail</span>
                            <input class="input w-full" type="text" name="moradorEmail" value="${filtroMoradorEmail}" placeholder="Ex.: mar" />
                        </label>
                        <label class="field">
                            <span>Morador</span>
                            <select class="select w-full" name="moradorId" data-auto-submit>
                                <option value="">Escolha um morador</option>
                                <c:forEach items="${moradoresDisponiveis}" var="morador">
                                    <option value="${morador.id}" ${moradorSelecionadoId eq morador.id ? 'selected' : ''}>
                                        ${morador.nome} - ${morador.email}
                                    </option>
                                </c:forEach>
                            </select>
                        </label>
                        <div class="button-row">
                            <button type="submit" class="btn btn-primary">Buscar morador</button>
                            <a href="${ctx}/admin/vinculos-morador" class="btn">Limpar</a>
                        </div>

                        <c:if test="${not empty moradorSelecionadoId}">
                            <label class="field">
                                <span>Bloco</span>
                                <select class="select w-full" name="blocoId" data-auto-submit>
                                    <option value="">Escolha um bloco</option>
                                    <c:forEach items="${blocosDisponiveis}" var="bloco">
                                        <option value="${bloco.id}" ${blocoSelecionadoId eq bloco.id ? 'selected' : ''}>
                                            ${bloco.identificacao}
                                        </option>
                                    </c:forEach>
                                </select>
                            </label>
                        </c:if>
                    </form>

                    <c:if test="${not empty moradorSelecionado}">
                        <div class="divider"></div>
                        <div class="list-row">
                            <div>
                                <strong>${moradorSelecionado.nome}</strong>
                                <span>${moradorSelecionado.email}</span>
                            </div>
                            <a href="${ctx}/admin/usuarios/${moradorSelecionado.id}" class="btn">Abrir cadastro</a>
                        </div>

                        <c:choose>
                            <c:when test="${empty unidadesMorador}">
                                <ui:vazio mensagem="Este morador ainda nao possui unidades vinculadas." compacto="true" />
                            </c:when>
                            <c:otherwise>
                                <div class="stack-list">
                                    <c:forEach items="${unidadesMorador}" var="unidade">
                                        <div class="list-row">
                                            <div>
                                                <strong>${unidade.identificacao}</strong>
                                                <span>${unidade.blocoIdentificacao} - Andar ${unidade.andar}</span>
                                            </div>
                                            <ui:acao-form acao="${ctx}/admin/moradores/${moradorSelecionadoId}/unidades/${unidade.id}?dashboard=true"
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

                        <c:if test="${not empty unidadesBloco}">
                            <div class="divider"></div>
                            <form method="post" action="${ctx}/admin/moradores/${moradorSelecionadoId}/unidades?dashboard=true" class="stack-form compact-form">
                                <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                                <input type="hidden" name="_method" value="put">
                                <input type="hidden" name="blocoId" value="${blocoSelecionadoId}">
                                <label class="field">
                                    <span>Unidade do bloco selecionado</span>
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
                                <button type="submit" class="btn btn-primary">Vincular morador</button>
                            </form>
                        </c:if>
                    </c:if>
                                    </div>
                </article>

                <div class="stack-list">
                    <article class="card">
                        <div class="card-body">
                        <ui:card-head titulo="Moradores cadastrados" descricao="Base cadastrada" />

                        <form method="get" action="${ctx}/admin/vinculos-morador" class="stack-form compact-form">
                            <c:if test="${not empty moradorSelecionadoId}">
                                <input type="hidden" name="moradorId" value="${moradorSelecionadoId}" />
                            </c:if>
                            <c:if test="${not empty blocoSelecionadoId}">
                                <input type="hidden" name="blocoId" value="${blocoSelecionadoId}" />
                            </c:if>
                            <c:if test="${not empty filtroMoradorEmail}">
                                <input type="hidden" name="moradorEmail" value="${filtroMoradorEmail}" />
                            </c:if>
                            <c:if test="${not empty filtroSemUnidadeEmail}">
                                <input type="hidden" name="semUnidadeEmail" value="${filtroSemUnidadeEmail}" />
                            </c:if>
                            <label class="field">
                                <span>Buscar moradores por e-mail</span>
                                <input class="input w-full" type="text" name="cadastradosEmail" value="${filtroCadastradosEmail}" placeholder="Ex.: mar" />
                            </label>
                            <div class="button-row">
                                <button type="submit" class="btn btn-primary">Buscar moradores</button>
                            </div>
                        </form>

                        <c:choose>
                            <c:when test="${empty moradoresCadastrados}">
                                <ui:vazio titulo="Nenhum morador encontrado" mensagem="Refine o filtro para localizar um morador cadastrado." />
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
                                        <c:forEach items="${moradoresCadastrados}" var="morador">
                                            <tr>
                                                <td>${morador.nome}</td>
                                                <td>${morador.email}</td>
                                                <td class="cell-actions">
                                                    <ui:acao-link href="${ctx}/admin/vinculos-morador?moradorId=${morador.id}${fn:escapeXml(vinculosFiltros)}" texto="Selecionar" />
                                                </td>
                                            </tr>
                                        </c:forEach>
                                        </tbody>
                                    </table>
                                </div>
                            </c:otherwise>
                        </c:choose>

                        <ui:paginacao pagina="${moradoresCadastradosPage}" url="${ctx}/admin/vinculos-morador"
                                      paramPagina="cadastradosPage" paramTamanho="cadastradosSize"
                                      parametros="${vinculosContexto}" />
                                            </div>
                    </article>

                    <article class="card">
                        <div class="card-body">
                        <ui:card-head titulo="Moradores sem unidade" descricao="Pendencias" />

                        <form method="get" action="${ctx}/admin/vinculos-morador" class="stack-form compact-form">
                            <c:if test="${not empty moradorSelecionadoId}">
                                <input type="hidden" name="moradorId" value="${moradorSelecionadoId}" />
                            </c:if>
                            <c:if test="${not empty blocoSelecionadoId}">
                                <input type="hidden" name="blocoId" value="${blocoSelecionadoId}" />
                            </c:if>
                            <c:if test="${not empty filtroMoradorEmail}">
                                <input type="hidden" name="moradorEmail" value="${filtroMoradorEmail}" />
                            </c:if>
                            <c:if test="${not empty filtroCadastradosEmail}">
                                <input type="hidden" name="cadastradosEmail" value="${filtroCadastradosEmail}" />
                            </c:if>
                            <label class="field">
                                <span>Buscar pendentes por e-mail</span>
                                <input class="input w-full" type="text" name="semUnidadeEmail" value="${filtroSemUnidadeEmail}" placeholder="Ex.: mar" />
                            </label>
                            <div class="button-row">
                                <button type="submit" class="btn btn-primary">Buscar pendentes</button>
                            </div>
                        </form>

                        <c:choose>
                            <c:when test="${empty moradoresSemUnidade}">
                                <ui:vazio titulo="Nenhum morador pendente" mensagem="Todos os moradores desta consulta ja possuem unidade vinculada." />
                            </c:when>
                            <c:otherwise>
                                <div class="overflow-x-auto">
                                    <table class="table table-zebra" data-filter-table="moradores-sem-unidade-table">
                                        <thead>
                                        <tr>
                                            <th>Nome</th>
                                            <th>Email</th>
                                            <th><span class="sr-only">Ações</span></th>
                                        </tr>
                                        </thead>
                                        <tbody>
                                        <c:forEach items="${moradoresSemUnidade}" var="morador">
                                            <tr>
                                                <td>${morador.nome}</td>
                                                <td>${morador.email}</td>
                                                <td class="cell-actions">
                                                    <ui:acao-link href="${ctx}/admin/vinculos-morador?moradorId=${morador.id}${fn:escapeXml(vinculosFiltros)}" texto="Selecionar" />
                                                </td>
                                            </tr>
                                        </c:forEach>
                                        </tbody>
                                    </table>
                                </div>
                            </c:otherwise>
                        </c:choose>

                        <ui:paginacao pagina="${moradoresSemUnidadePage}" url="${ctx}/admin/vinculos-morador"
                                      paramPagina="semUnidadePage" paramTamanho="semUnidadeSize"
                                      parametros="${vinculosContexto}" />
                                            </div>
                    </article>
                </div>
            </section>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
