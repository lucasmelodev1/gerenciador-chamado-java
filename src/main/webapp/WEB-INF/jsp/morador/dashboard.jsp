<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="morador-dashboard">

            <section class="stats-grid">
                <article class="stat-card">
                    <span>Minhas unidades</span>
                    <strong>${totalUnidades}</strong>
                </article>
                <article class="stat-card">
                    <span>Meus chamados</span>
                    <strong>${totalChamados}</strong>
                </article>
                <article class="stat-card stat-card-wide">
                    <span>Novo atendimento</span>
                    <strong>Abrir chamado</strong>
                    <a href="${ctx}/morador/chamados/novo" class="btn btn-primary">Registrar agora</a>
                </article>
            </section>

            <section class="two-column-grid">
                <article class="card">
                    <div class="card-body">
                    <ui:card-head titulo="Minhas unidades" descricao="Acesso vinculado" />
                    <c:choose>
                        <c:when test="${empty minhasUnidades}">
                            <ui:vazio mensagem="Nenhuma unidade vinculada ao seu acesso." compacto="true" />
                        </c:when>
                        <c:otherwise>
                            <div class="stack-list">
                                <c:forEach items="${minhasUnidades}" var="unidade">
                                    <div class="list-row">
                                        <div>
                                            <strong>${unidade.identificacao}</strong>
                                            <span>${unidade.blocoIdentificacao} - Andar ${unidade.andar}</span>
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
                            <div class="stack-list">
                                <c:forEach items="${meusChamados}" var="chamado">
                                    <a href="${ctx}/morador/chamados/${chamado.id}" class="list-row link-row">
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
