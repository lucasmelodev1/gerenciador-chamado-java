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

            <div class="mb-4.5 grid grid-cols-2 gap-4">
                <c:if test="${mostrarMorador eq 'true'}">
                    <div class="grid gap-1 rounded-[10px] border border-primary/5 bg-white/75 p-3.5"><span class="text-base-content/60">Morador</span><strong>${chamado.moradorNome}</strong></div>
                </c:if>
                <div class="grid gap-1 rounded-[10px] border border-primary/5 bg-white/75 p-3.5"><span class="text-base-content/60">Unidade</span><strong>${chamado.unidadeIdentificacao}</strong></div>
                <div class="grid gap-1 rounded-[10px] border border-primary/5 bg-white/75 p-3.5"><span class="text-base-content/60">Bloco</span><strong>${chamado.blocoIdentificacao}</strong></div>
                <div class="grid gap-1 rounded-[10px] border border-primary/5 bg-white/75 p-3.5"><span class="text-base-content/60">Abertura</span><strong>${chamado.dataAberturaFormatada}</strong></div>
                <div class="grid gap-1 rounded-[10px] border border-primary/5 bg-white/75 p-3.5"><span class="text-base-content/60">Finalizacao</span><strong><c:out value="${empty chamado.dataFinalizacaoFormatada ? avisoFinal : chamado.dataFinalizacaoFormatada}" /></strong></div>
            </div>

            <div class="grid gap-2 rounded-xl border border-accent/15 bg-accent/15 p-4.5">
                <span>Descricao</span>
                <p class="whitespace-pre-wrap">${chamado.descricao}</p>
            </div>

            <c:if test="${modo eq 'gestao' and not chamado.finalizado}">
                <form method="post" action="${base}/${chamado.id}/status" class="flex flex-wrap items-end gap-3 mt-5">
                    <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                    <input type="hidden" name="_method" value="patch">
                    <ui:campo rotulo="Atualizar status" classe="flex-1 basis-60">
                        <select class="select w-full" name="statusId" required>
                            <option value="">Selecione</option>
                            <c:forEach items="${statusDisponiveis}" var="status">
                                <option value="${status.id}" ${chamado.statusId eq status.id ? 'selected' : ''}>${status.nome}</option>
                            </c:forEach>
                        </select>
                    </ui:campo>
                    <button type="submit" class="btn btn-primary">Salvar status</button>
                </form>
            </c:if>

            <c:if test="${modo eq 'morador' and chamado.finalizado}">
                <ui:acao-form acao="${base}/${chamado.id}/reabrir" metodo="patch" texto="Reabrir chamado"
                              variante="primary" classe="flex flex-wrap items-center gap-3"
                              confirmacao="Reabrir este chamado?" />
            </c:if>
        </div>
    </article>

    <article class="card">
        <div class="card-body">
            <ui:card-head titulo="Comentarios" descricao="${eyebrowComentarios}" />

            <c:if test="${not chamado.finalizado}">
                <form method="post" action="${base}/${chamado.id}/comentarios" enctype="multipart/form-data" class="grid gap-4">
                    <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                    <ui:campo rotulo="Novo comentario">
                        <textarea class="textarea w-full" name="mensagem" rows="4" maxlength="255" required data-character-count></textarea>
                        <small class="text-base-content/60" data-character-output>0 caracteres</small>
                    </ui:campo>
                    <ui:campo rotulo="Anexo do comentario">
                        <input class="file-input" type="file" name="arquivo">
                        <small class="text-base-content/60">${dicaAnexo}</small>
                    </ui:campo>
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
                    <div class="app-linha-tempo">
                        <c:forEach items="${comentarios}" var="comentario">
                            <article class="app-linha-tempo-item">
                                <header>
                                    <strong>${comentario.autorNome}</strong>
                                    <span>${comentario.autorRole} • ${comentario.dataCriacaoFormatada}</span>
                                </header>
                                <p>${comentario.mensagem}</p>
                                <c:if test="${not empty comentario.anexos}">
                                    <div class="grid gap-4">
                                        <c:forEach items="${comentario.anexos}" var="anexoComentario">
                                            <div class="flex items-center justify-between gap-3 rounded-xl border border-base-content/10 bg-base-100 px-4.5 py-4 transition duration-200">
                                                <div>
                                                    <strong>${anexoComentario.nomeArquivo}</strong>
                                                    <span class="text-base-content/60">${anexoComentario.contentType} • ${anexoComentario.tamanhoFormatado}</span>
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
                        <form method="post" action="${base}/${chamado.id}/anexos" enctype="multipart/form-data" class="grid gap-4">
                            <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                            <ui:campo rotulo="Adicionar arquivo">
                                <input class="file-input" type="file" name="arquivo" required>
                            </ui:campo>
                            <small class="text-base-content/60">Tamanho maximo: 5 MB.</small>
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
                    <div class="grid gap-4">
                        <c:forEach items="${anexos}" var="anexo">
                            <div class="flex items-center justify-between gap-3 rounded-xl border border-base-content/10 bg-base-100 px-4.5 py-4 transition duration-200">
                                <div>
                                    <strong>${anexo.nomeArquivo}</strong>
                                    <span class="text-base-content/60">${anexo.contentType} • ${anexo.tamanhoFormatado}</span>
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
