<%--
    Componente: linha de lista de detalhes (S30).

    Uma linha de "rotulo a esquerda, valor em negrito a direita". Quem usa declara o
    `<dl class="app-detalhe-lista">` em volta: o tag nao pode abrir a lista, porque a
    lista e a COMPOSICAO de varias linhas irmaos.

    Uso com valor vindo do servidor:
        <dl class="app-detalhe-lista">
            <ui:detalhe-linha rotulo="Aberta em">${area.criadoEm}</ui:detalhe-linha>
        </dl>

    Uso com valor preenchido pelo JS (o `campo` e o gancho `data-detalhe`):
        <ui:detalhe-linha rotulo="Area" campo="area" />

    Atributos: `rotulo` (obrigatorio); `campo` (opcional) — quando informado, o `<dd>`
    sai com `data-detalhe="<campo>"` para o JS preencher; sem ele a linha e estatica e o
    valor vem do corpo.
--%>
<%@ tag pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ attribute name="rotulo" required="true" %>
<%@ attribute name="campo" required="false" description="gancho data-detalhe para o JS preencher o valor" %>

<div class="app-detalhe-linha">
    <dt class="app-detalhe-rotulo">${rotulo}</dt>
    <dd class="app-detalhe-valor"<c:if test="${not empty campo}"> data-detalhe="${campo}"</c:if>><jsp:doBody /></dd>
</div>
