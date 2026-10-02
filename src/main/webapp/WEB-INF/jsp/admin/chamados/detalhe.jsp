<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-chamado-detalhe">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <section class="detail-grid">
                <article class="card">
                    <div class="card-body">
                    <div class="section-header">
                        <div>
                            <p class="eyebrow">Chamado</p>
                            <h2>${chamado.tipoChamadoTitulo}</h2>
                        </div>
                        <span class="badge badge-ghost">${chamado.statusNome}</span>
                    </div>

                    <div class="detail-list">
                        <div><span>Morador</span><strong>${chamado.moradorNome}</strong></div>
                        <div><span>Unidade</span><strong>${chamado.unidadeIdentificacao}</strong></div>
                        <div><span>Bloco</span><strong>${chamado.blocoIdentificacao}</strong></div>
                        <div><span>Abertura</span><strong>${chamado.dataAberturaFormatada}</strong></div>
                        <div><span>Finalizacao</span><strong><c:out value="${empty chamado.dataFinalizacaoFormatada ? 'Ainda nao finalizado' : chamado.dataFinalizacaoFormatada}" /></strong></div>
                    </div>

                    <div class="description-box">
                        <span>Descricao</span>
                        <p>${chamado.descricao}</p>
                    </div>

                    <c:if test="${not chamado.finalizado}">
                        <form method="post" action="${ctx}/admin/chamados/${chamado.id}/status" class="inline-panel">
                            <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                            <input type="hidden" name="_method" value="patch">
                            <label class="field">
                                <span>Atualizar status</span>
                                <select class="select w-full" name="statusId" required>
                                    <option value="">Selecione</option>
                                    <c:forEach items="${statusDisponiveis}" var="status">
                                        <option value="${status.id}" ${chamado.statusId eq status.id ? 'selected' : ''}>${status.nome}</option>
                                    </c:forEach>
                                </select>
                            </label>
                            <button type="submit" class="btn btn-primary">Salvar status</button>
                        </form>
                    </c:if>
                                    </div>
                </article>

                <article class="card">
                    <div class="card-body">
                    <div class="section-header">
                        <div>
                            <p class="eyebrow">Historico</p>
                            <h2>Comentarios</h2>
                        </div>
                    </div>

                    <c:if test="${not chamado.finalizado}">
                        <form method="post" action="${ctx}/admin/chamados/${chamado.id}/comentarios" enctype="multipart/form-data" class="stack-form">
                            <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                            <label class="field">
                                <span>Novo comentario</span>
                                <textarea class="textarea w-full" name="mensagem" rows="4" maxlength="255" required data-character-count></textarea>
                                <small class="field-hint" data-character-output>0 caracteres</small>
                            </label>
                            <label class="field">
                                <span>Anexo do comentario</span>
                                <input class="file-input" type="file" name="arquivo">
                                <small class="field-hint">Opcional. O arquivo fica vinculado a este comentario do administrador. Tamanho maximo: 5 MB.</small>
                            </label>
                            <button type="submit" class="btn btn-primary">Adicionar comentario</button>
                        </form>
                    </c:if>
                    <c:if test="${chamado.finalizado}">
                        <ui:vazio mensagem="Chamados finalizados ficam bloqueados para novos comentarios." compacto="true" />
                    </c:if>

                    <c:choose>
                        <c:when test="${empty comentarios}">
                            <ui:vazio mensagem="Nenhum comentario registrado neste chamado." compacto="true" />
                        </c:when>
                        <c:otherwise>
                            <div class="timeline">
                                <c:forEach items="${comentarios}" var="comentario">
                                    <article class="timeline-item">
                                        <header>
                                            <strong>${comentario.autorNome}</strong>
                                            <span>${comentario.autorRole} • ${comentario.dataCriacaoFormatada}</span>
                                        </header>
                                        <p>${comentario.mensagem}</p>
                                        <c:if test="${not empty comentario.anexos}">
                                            <div class="stack-list">
                                                <c:forEach items="${comentario.anexos}" var="anexoComentario">
                                                    <div class="list-row">
                                                        <div>
                                                            <strong>${anexoComentario.nomeArquivo}</strong>
                                                            <span>${anexoComentario.contentType} • ${anexoComentario.tamanhoFormatado}</span>
                                                        </div>
                                                        <a href="${ctx}/admin/chamados/${chamado.id}/comentarios/${comentario.id}/anexos/${anexoComentario.id}" class="btn">Baixar anexo</a>
                                                    </div>
                                                </c:forEach>
                                            </div>
                                        </c:if>
                                    </article>
                                </c:forEach>
                            </div>
                        </c:otherwise>
                    </c:choose>
                                    </div>
                </article>

                <article class="card">
                    <div class="card-body">
                    <div class="section-header">
                        <div>
                            <p class="eyebrow">Arquivos</p>
                            <h2>Anexos</h2>
                        </div>
                    </div>

                    <c:choose>
                        <c:when test="${empty anexos}">
                            <ui:vazio mensagem="Nenhum anexo registrado neste chamado." compacto="true" />
                        </c:when>
                        <c:otherwise>
                            <div class="stack-list">
                                <c:forEach items="${anexos}" var="anexo">
                                    <div class="list-row">
                                        <div>
                                            <strong>${anexo.nomeArquivo}</strong>
                                            <span>${anexo.contentType} • ${anexo.tamanhoFormatado}</span>
                                        </div>
                                        <a href="${ctx}/admin/chamados/${chamado.id}/anexos/${anexo.id}" class="btn">Baixar</a>
                                    </div>
                                </c:forEach>
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
