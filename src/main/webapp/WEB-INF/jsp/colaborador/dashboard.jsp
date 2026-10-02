<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="colaborador-dashboard">

            <section class="grid grid-cols-1 gap-4.5 min-[981px]:grid-cols-3 min-[1201px]:grid-cols-5">
                    <ui:metrica rotulo="Chamados atrasados" valor="${totalChamadosAtrasados}" />
                    <ui:metrica rotulo="Chamados em atendimento" valor="${totalChamadosAbertos}" destaque="true" href="${ctx}/colaborador/chamados" rotuloLink="Abrir fila" classeLink="btn btn-primary" />
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
</ui:shell>
<ui:shell-fim />
