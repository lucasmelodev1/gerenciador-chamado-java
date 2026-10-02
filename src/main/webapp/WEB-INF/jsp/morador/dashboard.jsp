<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="morador-dashboard">

            <section class="grid grid-cols-1 gap-4.5 min-[981px]:grid-cols-3 min-[1201px]:grid-cols-5">
                    <ui:metrica rotulo="Minhas unidades" valor="${totalUnidades}" />
                    <ui:metrica rotulo="Meus chamados" valor="${totalChamados}" />
                    <ui:metrica rotulo="Novo atendimento" valor="Abrir chamado" destaque="true" href="${ctx}/morador/chamados/novo" rotuloLink="Registrar agora" classeLink="btn btn-primary" />
            </section>

            <section class="app-grade-lateral">
                <article class="card">
                    <div class="card-body">
                    <ui:card-head titulo="Minhas unidades" descricao="Acesso vinculado" />
                    <c:choose>
                        <c:when test="${empty minhasUnidades}">
                            <ui:vazio mensagem="Nenhuma unidade vinculada ao seu acesso." compacto="true" />
                        </c:when>
                        <c:otherwise>
                            <div class="grid gap-4">
                                <c:forEach items="${minhasUnidades}" var="unidade">
                                    <div class="flex items-center justify-between gap-3 rounded-xl border border-base-content/10 bg-base-100 px-4.5 py-4 transition duration-200">
                                        <div>
                                            <strong>${unidade.identificacao}</strong>
                                            <span class="text-base-content/60">${unidade.blocoIdentificacao} - Andar ${unidade.andar}</span>
                                        </div>
                                    </div>
                                </c:forEach>
                            </div>
                        </c:otherwise>
                    </c:choose>
                                    </div>
                </article>

                <article class="card">
                    <div class="card-body">
                    <ui:card-head titulo="Chamados recentes" descricao="Acompanhamento">
                        <a href="${ctx}/morador/chamados" class="btn">Ver todos</a>
                    </ui:card-head>
                    <c:choose>
                        <c:when test="${empty meusChamados}">
                            <ui:vazio mensagem="Voce ainda nao abriu chamados." compacto="true" />
                        </c:when>
                        <c:otherwise>
                            <div class="grid gap-4">
                                <c:forEach items="${meusChamados}" var="chamado">
                                    <a href="${ctx}/morador/chamados/${chamado.id}" class="flex items-center justify-between gap-3 rounded-xl border border-base-content/10 bg-base-100 px-4.5 py-4 transition duration-200 hover:border-primary/30 hover:translate-x-0.5 hover:shadow-soft">
                                        <div>
                                            <strong>${chamado.tipoChamadoTitulo}</strong>
                                            <span>${chamado.unidadeIdentificacao} - ${chamado.dataAberturaFormatada}</span>
                                        </div>
                                        <ui:badge variante="ghost">${chamado.statusNome}</ui:badge>
                                    </a>
                                </c:forEach>
                            </div>
                        </c:otherwise>
                    </c:choose>
                                    </div>
                </article>
            </section>
</ui:shell>
<ui:shell-fim />
