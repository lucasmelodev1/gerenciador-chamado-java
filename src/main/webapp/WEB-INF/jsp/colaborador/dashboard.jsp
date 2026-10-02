<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="colaborador-dashboard">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <section class="stats-grid">
                <article class="stat-card">
                    <span>Chamados atrasados</span>
                    <strong>${totalChamadosAtrasados}</strong>
                </article>
                <article class="stat-card stat-card-wide">
                    <span>Chamados em atendimento</span>
                    <strong>${totalChamadosAbertos}</strong>
                    <a href="${ctx}/colaborador/chamados" class="btn btn-primary">Abrir fila</a>
                </article>
            </section>

            <section class="card">
                <div class="card-body">
                    <ui:card-head titulo="Chamados recentes" descricao="Fila imediata" />

                    <c:choose>
                        <c:when test="${empty chamados}">
                            <ui:vazio titulo="Nenhum chamado disponivel no seu escopo" mensagem="Quando surgirem novos atendimentos eles aparecerao aqui." />
                        </c:when>
                        <c:otherwise>
                            <ui:tabela-chamados itens="${chamados}" base="${ctx}/colaborador/chamados"
                                                mostrarAbertura="false" acaoTexto="Atender" acaoRotulo="Atender" />
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
