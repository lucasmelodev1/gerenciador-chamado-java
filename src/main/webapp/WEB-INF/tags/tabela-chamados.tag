<%--
    Componente: tabela de chamados (S31).

    As cinco telas que listam chamados (as tres listas e os dois paineis) desenhavam a mesma
    tabela com o mesmo badge e tres formas diferentes de acao (`btn-link` com texto para
    algumas, icone + tooltip para o admin, celula com e sem `.app-tabela-acoes`). A tela so
    declara o que e dela: a lista, a base da URL da acao e quais colunas aparecem.

    Uso:
        <ui:tabela-chamados itens="${chamados}" base="${ctx}/admin/chamados"
                            mostrarMorador="true" acaoIcone="ver" acaoRotulo="Detalhar" />

        <ui:tabela-chamados itens="${chamados}" base="${ctx}/colaborador/chamados"
                            mostrarMorador="true" acaoTexto="Detalhar" acaoRotulo="Detalhar" />

    Atributos:
        itens            obrigatorio — a colecao de chamados da pagina
        base             obrigatorio — URL da acao da linha, sem o id (`${base}/${id}`)
        mostrarMorador   opcional — coluna Morador (padrao: false)
        mostrarAbertura  opcional — coluna Abertura (padrao: true)
        acaoTexto        opcional — rotulo visivel da acao; sem ele a acao sai so com icone
        acaoRotulo       obrigatorio no modo icone — tooltip e nome acessivel
        acaoIcone        opcional — alias de ui:icone no modo icone (padrao: ver)

    A celula de acao preserva a classe que cada tela ja usava: `cell-actions` no modo texto e
    `cell-actions app-tabela-acoes` no modo icone. O cabecalho usa `<span class="sr-only">Acoes</span>`
    em todas — sem efeito visual e o que faltava nas listas que tinham a coluna vazia.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="ui" tagdir="/WEB-INF/tags" %>
<%@ attribute name="itens" required="true" type="java.lang.Object" %>
<%@ attribute name="base" required="true" %>
<%@ attribute name="mostrarMorador" required="false" %>
<%@ attribute name="mostrarAbertura" required="false" %>
<%@ attribute name="acaoTexto" required="false" %>
<%@ attribute name="acaoRotulo" required="false" %>
<%@ attribute name="acaoIcone" required="false" %>

<c:set var="acaoComTexto" value="${not empty acaoTexto}" />
<c:set var="mostrarAberturaColuna" value="${mostrarAbertura ne 'false'}" />
<c:set var="celulaAcaoClasse" value="cell-actions${acaoComTexto ? '' : ' app-tabela-acoes'}" />

<div class="overflow-x-auto">
    <table class="table table-zebra">
        <thead>
        <tr>
            <th>Unidade</th>
            <c:if test="${mostrarMorador eq 'true'}">
                <th>Morador</th>
            </c:if>
            <th>Tipo</th>
            <th>Status</th>
            <c:if test="${mostrarAberturaColuna}">
                <th>Abertura</th>
            </c:if>
            <th><span class="sr-only">Ações</span></th>
        </tr>
        </thead>
        <tbody>
        <c:forEach items="${itens}" var="chamado">
            <tr>
                <td>${chamado.unidadeIdentificacao}</td>
                <c:if test="${mostrarMorador eq 'true'}">
                    <td>${chamado.moradorNome}</td>
                </c:if>
                <td>${chamado.tipoChamadoTitulo}</td>
                <td><ui:badge variante="ghost">${chamado.statusNome}</ui:badge></td>
                <c:if test="${mostrarAberturaColuna}">
                    <td>${chamado.dataAberturaFormatada}</td>
                </c:if>
                <td class="${celulaAcaoClasse}">
                    <ui:acao-link href="${base}/${chamado.id}"
                                  texto="${acaoTexto}"
                                  icone="${empty acaoIcone ? 'ver' : acaoIcone}"
                                  rotulo="${acaoRotulo}" />
                </td>
            </tr>
        </c:forEach>
        </tbody>
    </table>
</div>
