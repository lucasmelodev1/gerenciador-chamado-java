<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<ui:shell dataPagina="morador-reserva-nova" classeMain="narrow-content">

            <section class="card">
                <div class="card-body">
                <ui:card-head titulo="Solicitar reserva" descricao="Areas comuns" />

                <form method="post" action="${ctx}/morador/reservas" class="stack-form">
                    <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                    <label class="field">
                        <span>Unidade</span>
                        <select class="select w-full" name="unidadeId" required>
                            <option value="">Selecione uma unidade</option>
                            <c:forEach items="${unidades}" var="unidade">
                                <option value="${unidade.id}">${unidade.identificacao} - ${unidade.blocoIdentificacao}</option>
                            </c:forEach>
                        </select>
                    </label>
                    <label class="field">
                        <span>Area</span>
                        <select class="select w-full" name="areaId" required>
                            <option value="">Selecione uma area</option>
                            <c:forEach items="${areas}" var="area">
                                <option value="${area.id}">${area.nome}</option>
                            </c:forEach>
                        </select>
                    </label>
                    <label class="field">
                        <span>Inicio</span>
                        <input class="input w-full" type="datetime-local" name="inicio" required>
                    </label>
                    <label class="field">
                        <span>Fim</span>
                        <input class="input w-full" type="datetime-local" name="fim" required>
                    </label>
                    <div class="button-row">
                        <button type="submit" class="btn btn-primary">Solicitar reserva</button>
                        <a href="${ctx}/morador/reservas" class="btn">Cancelar</a>
                    </div>
                </form>
                            </div>
            </section>
</ui:shell>
<ui:shell-fim />
