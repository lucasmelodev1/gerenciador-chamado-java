<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-dashboard">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <section class="stats-grid">
                <article class="stat-card">
                    <span>Blocos</span>
                    <strong>${totalBlocos}</strong>
                </article>
                <article class="stat-card">
                    <span>Usuarios</span>
                    <strong>${totalUsuarios}</strong>
                </article>
                <article class="stat-card">
                    <span>Tipos de Chamado</span>
                    <strong>${totalTiposChamado}</strong>
                </article>
                <article class="stat-card">
                    <span>Status</span>
                    <strong>${totalStatus}</strong>
                </article>
                <article class="stat-card">
                    <span>Chamados atrasados</span>
                    <strong>${totalChamadosAtrasados}</strong>
                </article>
                <article class="stat-card stat-card-wide">
                    <span>Chamados monitorados</span>
                    <strong>${totalChamados}</strong>
                    <a href="${ctx}/admin/chamados" class="btn">Abrir fila completa</a>
                </article>
            </section>

            <section class="card">
                <div class="card-body">
                    <ui:card-head titulo="Chamados recentes" descricao="Visao operacional">
                        <a href="${ctx}/admin/chamados" class="btn btn-primary">Ver todos</a>
                    </ui:card-head>

                    <c:choose>
                        <c:when test="${empty chamadosRecentes}">
                            <ui:vazio titulo="Nenhum chamado registrado" mensagem="Assim que moradores abrirem chamados eles aparecerao aqui." />
                        </c:when>
                        <c:otherwise>
                            <ui:tabela-chamados itens="${chamadosRecentes}" base="${ctx}/admin/chamados"
                                                acaoTexto="Detalhar" acaoRotulo="Detalhar" />
                        </c:otherwise>
                    </c:choose>
                </div>
            </section>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
