<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="morador-reserva-nova">
<div class="app-shell">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="app-main">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main class="page-content narrow-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <section class="card">
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
                        <select name="unidadeId" required>
                            <option value="">Selecione uma unidade</option>
                            <c:forEach items="${unidades}" var="unidade">
                                <option value="${unidade.id}">${unidade.identificacao} - ${unidade.blocoIdentificacao}</option>
                            </c:forEach>
                        </select>
                    </label>
                    <label class="field">
                        <span>Area</span>
                        <select name="areaId" required>
                            <option value="">Selecione uma area</option>
                            <c:forEach items="${areas}" var="area">
                                <option value="${area.id}">${area.nome}</option>
                            </c:forEach>
                        </select>
                    </label>
                    <label class="field">
                        <span>Inicio</span>
                        <input type="datetime-local" name="inicio" required>
                    </label>
                    <label class="field">
                        <span>Fim</span>
                        <input type="datetime-local" name="fim" required>
                    </label>
                    <div class="button-row">
                        <button type="submit" class="btn btn-primary">Solicitar reserva</button>
                        <a href="${ctx}/morador/reservas" class="btn btn-secondary">Cancelar</a>
                    </div>
                </form>
            </section>
        </main>
    </div>
</div>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
