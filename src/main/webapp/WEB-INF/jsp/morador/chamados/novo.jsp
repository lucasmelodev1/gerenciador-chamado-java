<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="morador-novo-chamado" classeMain="app-page--estreito">

            <section class="card">
                <div class="card-body">
                <ui:card-head titulo="Abrir chamado" descricao="Registro de ocorrencia" />

                <form method="post" action="${ctx}/morador/chamados" enctype="multipart/form-data" class="stack-form">
                    <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                    <label class="field">
                        <span>Unidade</span>
                        <select class="select w-full" name="unidadeId" required>
                            <option value="">Selecione uma unidade</option>
                            <c:forEach items="${unidades}" var="unidade">
                                <option value="${unidade.id}" ${abrirChamadoForm.unidadeId eq unidade.id ? 'selected' : ''}>
                                    ${unidade.identificacao} - ${unidade.blocoIdentificacao}
                                </option>
                            </c:forEach>
                        </select>
                    </label>
                    <label class="field">
                        <span>Tipo do chamado</span>
                        <select class="select w-full" name="tipoChamadoId" required>
                            <option value="">Selecione um tipo</option>
                            <c:forEach items="${tiposChamado}" var="tipo">
                                <option value="${tipo.id}" ${abrirChamadoForm.tipoChamadoId eq tipo.id ? 'selected' : ''}>
                                    ${tipo.titulo} - SLA ${tipo.prazoHoras}h
                                </option>
                            </c:forEach>
                        </select>
                    </label>
                    <label class="field">
                        <span>Descricao</span>
                        <textarea class="textarea w-full" name="descricao" rows="6" maxlength="255" required data-character-count>${abrirChamadoForm.descricao}</textarea>
                        <small class="field-hint" data-character-output>0 caracteres</small>
                    </label>
                    <label class="field">
                        <span>Anexo inicial</span>
                        <input class="file-input" type="file" name="arquivo">
                        <small class="field-hint">Opcional. Se enviado, sera anexado logo na abertura do chamado. Tamanho maximo: 5 MB.</small>
                    </label>
                    <div class="button-row">
                        <button type="submit" class="btn btn-primary">Registrar chamado</button>
                        <a href="${ctx}/morador/chamados" class="btn">Cancelar</a>
                    </div>
                </form>
                            </div>
            </section>
</ui:shell>
<ui:shell-fim />
