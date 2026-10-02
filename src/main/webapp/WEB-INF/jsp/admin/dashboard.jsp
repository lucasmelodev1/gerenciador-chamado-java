<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="admin-dashboard">

            <section class="grid grid-cols-1 gap-4.5 min-[981px]:grid-cols-3 min-[1201px]:grid-cols-5">
                    <ui:metrica rotulo="Blocos" valor="${totalBlocos}" />
                    <ui:metrica rotulo="Usuarios" valor="${totalUsuarios}" />
                    <ui:metrica rotulo="Tipos de Chamado" valor="${totalTiposChamado}" />
                    <ui:metrica rotulo="Status" valor="${totalStatus}" />
                    <ui:metrica rotulo="Chamados atrasados" valor="${totalChamadosAtrasados}" />
                    <ui:metrica rotulo="Chamados monitorados" valor="${totalChamados}" destaque="true" href="${ctx}/admin/chamados" rotuloLink="Abrir fila completa" />
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
</ui:shell>
<ui:shell-fim />
