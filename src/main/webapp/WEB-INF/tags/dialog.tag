<%--
    Componente: dialogo central (S28; casca fina sobre `ui:painel` desde S31).

    Mesmo componente do `ui:drawer`, com a outra forma: em vez de deslizar da borda,
    aparece CENTRADO na tela, com leve fade e escala. As tres faixas sao as mesmas
    (topo / corpo / rodape); o que muda e o rodape, que aqui serve para CONFIRMAR:

        [ Cancelar (esmaecido) ]   [ Confirmar (primario ou vermelho) ]

    Uso (confirmacao com motivo):
        <ui:dialog id="dialog-negacao" titulo="Negar reserva"
                   descricao="Explique o motivo; ele fica visivel para o morador."
                   acao="${ctx}/admin/reservas" varianteConfirmar="error"
                   iconeConfirmar="negar" rotuloConfirmar="Negar"
                   rotuloCancelar="Voltar">
            <ui:campo rotulo="Motivo">
                <input class="input w-full" type="text" name="motivo" maxlength="255" required>
            </ui:campo>
        </ui:dialog>

    Uso (confirmacao simples, sem campos): so `titulo`, `descricao` e a acao.

    O esqueleto (backdrop, topo, corpo, form com CSRF e rodape) vive em `ui:painel`; este
    tag so encaminha os atributos para manter o nome e o contrato das telas. Backdrop, Esc,
    foco preso, trava de scroll e o conteudo dinamico (`data-drawer-editar`) sao o mesmo
    codigo do drawer — um dialogo e um drawer centralizado.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="ui" tagdir="/WEB-INF/tags" %>
<%@ attribute name="id" required="true" description="id do dialogo; tambem nomeia o form interno" %>
<%@ attribute name="titulo" required="true" %>
<%@ attribute name="descricao" required="false" %>
<%@ attribute name="acao" required="false" description="action do form; sem ela o dialogo e so informativo" %>
<%@ attribute name="metodo" required="false" description="method do form (padrao: post)" %>
<%@ attribute name="tamanho" required="false" description="sm, md (padrao) ou lg" %>
<%@ attribute name="rotuloConfirmar" required="false" %>
<%@ attribute name="varianteConfirmar" required="false" description="primary (padrao) ou error" %>
<%@ attribute name="iconeConfirmar" required="false" description="alias de ui:icone" %>
<%@ attribute name="rotuloCancelar" required="false" description="botao esmaecido que fecha; sem ele o rodape so confirma" %>
<%@ attribute name="aberto" required="false" description="true abre o dialogo no carregamento" %>

<ui:painel forma="dialog"
           id="${id}" titulo="${titulo}" descricao="${descricao}"
           acao="${acao}" metodo="${metodo}" tamanho="${tamanho}" aberto="${aberto}"
           rotuloConfirmar="${rotuloConfirmar}" varianteConfirmar="${varianteConfirmar}"
           iconeConfirmar="${iconeConfirmar}" rotuloCancelar="${rotuloCancelar}"><jsp:doBody /></ui:painel>
