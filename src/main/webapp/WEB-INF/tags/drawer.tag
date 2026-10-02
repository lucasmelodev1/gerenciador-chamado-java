<%--
    Componente: drawer lateral (S23; casca fina sobre `ui:painel` desde S31).

    Painel que desliza da borda, em tres faixas:
        topo   -> titulo + descricao (+ botao X)
        meio   -> <jsp:doBody/>, o slot livre
        rodape -> Salvar (drawer de formulario) ou Fechar + a acao declarada (informativo)

    Duas formas, decididas por `acao`:

      - COM `acao`: e um formulario. O corpo fica dentro do <form> e o rodape so tem o
        Salvar. Fechar e o X do topo, o Esc e o clique fora (nao ha botao "Fechar").
      - SEM `acao`: e um painel INFORMATIVO (um detalhe, por exemplo). Nao ha formulario e
        o rodape passa a ter o botao **Fechar**; `rotuloAcao` acrescenta um segundo botao a
        esquerda, que pode abrir outro painel (ver `painelAcao`/`metodoAcao` no `ui:painel`).

    Uso:
        <ui:drawer id="drawer-area" titulo="Nova area"
                   descricao="Cadastre um espaco do condominio."
                   acao="${ctx}/admin/areas" rotuloSalvar="Cadastrar">
            <label class="field">
                <span>Nome</span>
                <input class="input w-full" name="nome" required>
            </label>
        </ui:drawer>

    O esqueleto (backdrop, topo, corpo, form com CSRF e rodape) vive em `ui:painel`; este
    tag so encaminha os atributos para manter o nome e o contrato das telas. As regras de
    posicionamento (FORA de `.page-content`), CSRF, campos travados e o protocolo com o
    `drawer.js` estao documentadas em `painel.tag`.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="ui" tagdir="/WEB-INF/tags" %>
<%@ attribute name="id" required="true" description="id do painel; tambem nomeia o form interno" %>
<%@ attribute name="titulo" required="true" %>
<%@ attribute name="descricao" required="false" %>
<%@ attribute name="acao" required="false" description="action do form; sem ela o drawer e informativo" %>
<%@ attribute name="metodo" required="false" description="method do form (padrao: post)" %>
<%@ attribute name="tamanho" required="false" description="sm (padrao, estreito), md ou lg" %>
<%@ attribute name="lado" required="false" description="end (padrao, direita) ou start (esquerda)" %>
<%@ attribute name="rotuloSalvar" required="false" %>
<%@ attribute name="rotuloFechar" required="false" %>
<%@ attribute name="aberto" required="false" description="true abre o drawer no carregamento" %>
<%@ attribute name="travar" required="false" description="campos separados por virgula que a EDICAO nao pode mudar; a criacao pode" %>
<%@ attribute name="rotuloAcao" required="false" description="segundo botao do rodape do drawer informativo (a esquerda do Fechar)" %>
<%@ attribute name="iconeAcao" required="false" description="alias de ui:icone para o botao da acao" %>
<%@ attribute name="varianteAcao" required="false" description="primary (padrao) ou error (vermelho)" %>
<%@ attribute name="painelAcao" required="false" description="id do painel que a acao abre (protocolo data-drawer-editar)" %>
<%@ attribute name="metodoAcao" required="false" description="valor de _method que o painel aberto recebe (ex.: delete)" %>

<ui:painel forma="drawer"
           id="${id}" titulo="${titulo}" descricao="${descricao}"
           acao="${acao}" metodo="${metodo}" tamanho="${tamanho}" lado="${lado}"
           aberto="${aberto}" travar="${travar}"
           rotuloSalvar="${rotuloSalvar}" rotuloFechar="${rotuloFechar}"
           rotuloAcao="${rotuloAcao}" iconeAcao="${iconeAcao}" varianteAcao="${varianteAcao}"
           painelAcao="${painelAcao}" metodoAcao="${metodoAcao}"><jsp:doBody /></ui:painel>
