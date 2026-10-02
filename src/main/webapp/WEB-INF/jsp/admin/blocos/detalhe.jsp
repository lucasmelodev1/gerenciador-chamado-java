<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-bloco-detalhe">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <section class="hero-card">
                <p class="eyebrow">Estrutura fisica</p>
                <h2>${bloco.identificacao}</h2>
                <div class="hero-metrics">
                    <span><strong>${bloco.quantidadeAndares}</strong> andares</span>
                    <span><strong>${bloco.apartamentosPorAndar}</strong> apartamentos por andar</span>
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
                                                    <div class="stack-list">
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
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
