<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="admin-bloco-detalhe">

            <section class="relative overflow-hidden rounded-2xl border border-white/70 bg-base-100 p-6 transition duration-200 hover:-translate-y-0.5 hover:border-accent/20 hover:shadow-painel">
                <p class="mb-2 text-xs tracking-eyebrow text-base-content/60 uppercase">Estrutura fisica</p>
                <h2 class="font-display text-2xl font-semibold">${bloco.identificacao}</h2>
                <div class="flex flex-wrap gap-5">
                    <span class="text-base-content/60"><strong>${bloco.quantidadeAndares}</strong> andares</span>
                    <span class="text-base-content/60"><strong>${bloco.apartamentosPorAndar}</strong> apartamentos por andar</span>
                </div>
            </section>

            <section class="card">
                <div class="card-body">
                <ui:card-head titulo="Unidades do bloco" descricao="Geracao automatica">
                    <a href="${ctx}/admin/blocos" class="btn">Voltar</a>
                </ui:card-head>

                <c:choose>
                    <c:when test="${empty unidades}">
                        <ui:vazio titulo="Nenhuma unidade encontrada" mensagem="Verifique se o bloco foi gerado corretamente." />
                    </c:when>
                    <c:otherwise>
                        <div class="overflow-x-auto">
                            <table class="table table-zebra">
                                <thead>
                                <tr>
                                    <th>Identificacao</th>
                                    <th>Andar</th>
                                    <th>Moradores vinculados</th>
                                </tr>
                                </thead>
                                <tbody>
                                <c:forEach items="${unidades}" var="unidade">
                                    <tr>
                                        <td>${unidade.identificacao}</td>
                                        <td>${unidade.andar}</td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${empty unidade.moradores}">
                                                    <ui:badge>Sem moradores</ui:badge>
                                                </c:when>
                                                <c:otherwise>
                                                    <div class="grid gap-4">
                                                        <c:forEach items="${unidade.moradores}" var="morador">
                                                            <div>
                                                                <strong>${morador.nome}</strong>
                                                                <span>${morador.email}</span>
                                                            </div>
                                                        </c:forEach>
                                                    </div>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                    </tr>
                                </c:forEach>
                                </tbody>
                            </table>
                        </div>
                    </c:otherwise>
                </c:choose>

                <ui:paginacao pagina="${unidadesPage}" url="${ctx}/admin/blocos/${bloco.id}" />
                            </div>
            </section>
</ui:shell>
<ui:shell-fim />
