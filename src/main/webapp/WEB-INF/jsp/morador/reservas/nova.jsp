<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="morador-reserva-nova" classeMain="app-page--estreito">

            <section class="card">
                <div class="card-body">
                <ui:card-head titulo="Solicitar reserva" descricao="Areas comuns" />

                <form method="post" action="${ctx}/morador/reservas" class="grid gap-4">
                    <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                    <ui:campo rotulo="Unidade">
                        <select class="select w-full" name="unidadeId" required>
                            <option value="">Selecione uma unidade</option>
                            <c:forEach items="${unidades}" var="unidade">
                                <option value="${unidade.id}">${unidade.identificacao} - ${unidade.blocoIdentificacao}</option>
                            </c:forEach>
                        </select>
                    </ui:campo>
                    <ui:campo rotulo="Area">
                        <select class="select w-full" name="areaId" required>
                            <option value="">Selecione uma area</option>
                            <c:forEach items="${areas}" var="area">
                                <option value="${area.id}">${area.nome}</option>
                            </c:forEach>
                        </select>
                    </ui:campo>
                    <ui:campo rotulo="Inicio">
                        <input class="input w-full" type="datetime-local" name="inicio" required>
                    </ui:campo>
                    <ui:campo rotulo="Fim">
                        <input class="input w-full" type="datetime-local" name="fim" required>
                    </ui:campo>
                    <div class="flex flex-wrap items-center gap-3">
                        <button type="submit" class="btn btn-primary">Solicitar reserva</button>
                        <a href="${ctx}/morador/reservas" class="btn">Cancelar</a>
                    </div>
                </form>
                            </div>
            </section>
</ui:shell>
<ui:shell-fim />
