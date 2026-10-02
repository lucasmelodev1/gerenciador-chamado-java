<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="morador-reserva-nova">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content narrow-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <section class="card">
                <div class="card-body">
                <div class="section-header">
                    <div>
                        <p class="eyebrow">Areas comuns</p>
                        <h2>Solicitar reserva</h2>
                    </div>
                </div>

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
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
