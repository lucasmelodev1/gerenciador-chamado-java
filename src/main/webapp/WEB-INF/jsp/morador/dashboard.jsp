<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="morador-dashboard">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

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
                    <div class="section-header">
                        <div>
                            <p class="eyebrow">Acesso vinculado</p>
                            <h2>Minhas unidades</h2>
                        </div>
                    </div>
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
                                    </div>
                </article>

                <article class="card">
                    <div class="card-body">
                    <div class="section-header">
                        <div>
                            <p class="eyebrow">Acompanhamento</p>
                            <h2>Chamados recentes</h2>
                        </div>
                        <a href="${ctx}/morador/chamados" class="btn">Ver todos</a>
                    </div>
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
                                        <span class="badge badge-ghost">${chamado.statusNome}</span>
                                    </a>
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
