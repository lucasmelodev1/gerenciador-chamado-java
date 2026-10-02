<%--
    Componente: tela de detalhe do chamado (S31).

    As tres telas (admin, colaborador e morador) eram o mesmo arquivo de ~161 linhas: o
    admin e o colaborador diferiam em 20 linhas, e as diferencas eram o rotulo do eyebrow, a
    linha do morador, a dica do anexo e quem pode mudar o status. O corpo comum vive aqui; a
    pagina declara so o que e dela.

    Uso (admin):
        <ui:detalhe-chamado base="${ctx}/admin/chamados" eyebrow="Chamado"
                            eyebrowComentarios="Historico" avisoFinal="Ainda nao finalizado"
                            mostrarMorador="true" modo="gestao"
                            dicaAnexo="Opcional. ... administrador. Tamanho maximo: 5 MB." />

    Uso (morador):
        <ui:detalhe-chamado base="${ctx}/morador/chamados" eyebrow="Acompanhamento"
                            eyebrowComentarios="Interacoes" avisoFinal="Em andamento"
                            modo="morador" podeAnexarAvulso="true"
                            dicaAnexo="Opcional. ... enviado pelo morador. Tamanho maximo: 5 MB." />

    Atributos:
        base              obrigatorio — URL do recurso, sem o id (`${base}/${id}/comentarios`)
        eyebrow           obrigatorio — a descricao do cabecalho do primeiro card
        eyebrowComentarios obrigatorio — a descricao do cabecalho dos comentarios
        avisoFinal        obrigatorio — texto da linha Finalizacao enquanto o chamado esta aberto
        modo              obrigatorio — `gestao` (form de status, admin/colaborador) ou
                          `morador` (form de reabertura)
        mostrarMorador    opcional — linha Morador no detalhe (padrao: false)
        podeAnexarAvulso  opcional — formulario de anexo na lista de anexos (padrao: false)
        dicaAnexo         obrigatorio — a dica abaixo do campo de anexo do comentario

    Os textos dos estados vazios e os rotulos do formulario de comentario foram unificados
    entre os tres perfis ("Nenhum comentario registrado.", "Nenhum anexo registrado.",
    "Chamados finalizados ficam bloqueados para novos comentarios."): a diferenca nunca foi
    intencional e era so a copia de cada tela.

    `chamado`, `comentarios`, `anexos` e `statusDisponiveis` vem do controller
    (`WebControllerSupport`); o fragmento nao muda o contrato com os testes.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="ui" tagdir="/WEB-INF/tags" %>
<%@ attribute name="base" required="true" %>
<%@ attribute name="eyebrow" required="true" %>
<%@ attribute name="eyebrowComentarios" required="true" %>
<%@ attribute name="avisoFinal" required="true" %>
<%@ attribute name="modo" required="true" description="gestao | morador" %>
<%@ attribute name="mostrarMorador" required="false" %>
<%@ attribute name="podeAnexarAvulso" required="false" %>
<%@ attribute name="dicaAnexo" required="true" %>

<section class="detail-grid">
    <article class="card">
        <div class="card-body">
            <ui:card-head titulo="${chamado.tipoChamadoTitulo}" descricao="${eyebrow}">
                <ui:badge variante="ghost">${chamado.statusNome}</ui:badge>
            </ui:card-head>

            <div class="detail-list">
                <c:if test="${mostrarMorador eq 'true'}">
                    <div><span>Morador</span><strong>${chamado.moradorNome}</strong></div>
                </c:if>
                <div><span>Unidade</span><strong>${chamado.unidadeIdentificacao}</strong></div>
                <div><span>Bloco</span><strong>${chamado.blocoIdentificacao}</strong></div>
                <div><span>Abertura</span><strong>${chamado.dataAberturaFormatada}</strong></div>
                <div><span>Finalizacao</span><strong><c:out value="${empty chamado.dataFinalizacaoFormatada ? avisoFinal : chamado.dataFinalizacaoFormatada}" /></strong></div>
            </div>

            <div class="description-box">
                <span>Descricao</span>
                <p>${chamado.descricao}</p>
            </div>

            <c:if test="${modo eq 'gestao' and not chamado.finalizado}">
                <form method="post" action="${base}/${chamado.id}/status" class="inline-panel">
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

            <c:if test="${modo eq 'morador' and chamado.finalizado}">
                <ui:acao-form acao="${base}/${chamado.id}/reabrir" metodo="patch" texto="Reabrir chamado"
                              variante="primary" classe="inline-form"
                              confirmacao="Reabrir este chamado?" />
            </c:if>
        </div>
    </article>

    <article class="card">
        <div class="card-body">
            <ui:card-head titulo="Comentarios" descricao="${eyebrowComentarios}" />

            <c:if test="${not chamado.finalizado}">
                <form method="post" action="${base}/${chamado.id}/comentarios" enctype="multipart/form-data" class="stack-form">
                    <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                    <label class="field">
                        <span>Novo comentario</span>
                        <textarea class="textarea w-full" name="mensagem" rows="4" maxlength="255" required data-character-count></textarea>
                        <small class="field-hint" data-character-output>0 caracteres</small>
                    </label>
                    <label class="field">
                        <span>Anexo do comentario</span>
                        <input class="file-input" type="file" name="arquivo">
                        <small class="field-hint">${dicaAnexo}</small>
                    </label>
                    <button type="submit" class="btn btn-primary">Adicionar comentario</button>
                </form>
            </c:if>
            <c:if test="${chamado.finalizado}">
                <ui:vazio mensagem="Chamados finalizados ficam bloqueados para novos comentarios." compacto="true" />
            </c:if>

            <c:choose>
                <c:when test="${empty comentarios}">
                    <ui:vazio mensagem="Nenhum comentario registrado." compacto="true" />
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
                                                <a href="${base}/${chamado.id}/comentarios/${comentario.id}/anexos/${anexoComentario.id}" class="btn">Baixar anexo</a>
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
            <ui:card-head titulo="Anexos" descricao="Arquivos" />

            <c:if test="${podeAnexarAvulso eq 'true'}">
                <c:choose>
                    <c:when test="${chamado.finalizado}">
                        <ui:vazio mensagem="Chamados finalizados nao aceitam novos anexos ate serem reabertos." compacto="true" />
                    </c:when>
                    <c:otherwise>
                        <form method="post" action="${base}/${chamado.id}/anexos" enctype="multipart/form-data" class="stack-form">
                            <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                            <label class="field">
                                <span>Adicionar arquivo</span>
                                <input class="file-input" type="file" name="arquivo" required>
                            </label>
                            <small class="field-hint">Tamanho maximo: 5 MB.</small>
                            <button type="submit" class="btn btn-primary">Enviar anexo</button>
                        </form>
                    </c:otherwise>
                </c:choose>
            </c:if>

            <c:choose>
                <c:when test="${empty anexos}">
                    <ui:vazio mensagem="Nenhum anexo registrado." compacto="true" />
                </c:when>
                <c:otherwise>
                    <div class="stack-list">
                        <c:forEach items="${anexos}" var="anexo">
                            <div class="list-row">
                                <div>
                                    <strong>${anexo.nomeArquivo}</strong>
                                    <span>${anexo.contentType} • ${anexo.tamanhoFormatado}</span>
                                </div>
                                <a href="${base}/${chamado.id}/anexos/${anexo.id}" class="btn">Baixar</a>
                            </div>
                        </c:forEach>
                    </div>
                </c:otherwise>
            </c:choose>
        </div>
    </article>
</section>
