<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<%-- Pagina publica: shell proprio (sem drawer) e, por isso, o unico `<body>` que nao vem do
     `ui:shell`.

     Layout do bloco `login-02` do shadcn: duas colunas a partir de `lg` — a esquerda com a
     marca no topo e o formulario centralizado, a direita com o painel decorativo. No bloco
     original essa coluna e uma imagem; aqui e o padrao `.app-padrao-login` (custom.css), sem
     asset novo. Abaixo de `lg` o painel nao e renderizado (`hidden lg:block`) e sobra a coluna
     do formulario.

     A marca fica FORA do fluxo (`absolute`): como linha no topo ela entraria na conta do
     `items-center` e o card cairia abaixo do meio da pagina. Ancorada, o card fica no centro
     da viewport e a marca flutua sobre o canto.

     O formulario esta no `card`/`card-body` da daisyUI (com `bg-base-100`), limitado a
     `max-w-88` (22rem = 352px, um pouco mais estreito que os 24rem de antes; o `card-body`
     ainda come 1.25rem de cada lado, entao o campo fica com 312px). O relevo e do
     `border-base-content/10` (fio claro) + `shadow-cartao` (o token do app.css), no lugar da
     sombra larga do `shadow-painel`.

     Os componentes daisyUI (`input`, `btn btn-primary btn-block`, `alert`) e os tags
     `ui:campo`/`ui:campo-senha`/`ui:icone` continuam os mesmos.

     O contrato com `scripts/ui-routes.sh` (marcador pos-rewrite) e o `data-page="login"`. --%>
<body class="bg-base-200 text-base-content" data-page="login">
<main class="grid min-h-svh grid-cols-1 lg:grid-cols-2">
    <section class="relative flex min-h-svh items-center justify-center p-6 md:p-10">
        <%-- Mesmo alinhamento do bloco (`justify-center md:justify-start`), so que ancorado:
             `left-1/2 -translate-x-1/2` no celular, `left-10` do `md` para cima. --%>
        <div class="absolute top-6 left-1/2 flex -translate-x-1/2 items-center gap-2 md:top-10 md:left-10 md:translate-x-0">
            <span class="flex size-8 items-center justify-center rounded-md bg-primary-strong text-primary-content">
                <ui:icone nome="chamados" classe="size-5" />
            </span>
            <span class="font-display text-lg font-semibold">${appName}</span>
        </div>

        <div class="card w-full max-w-88 border border-base-content/10 bg-base-100 shadow-cartao">
            <div class="card-body">
                <h2 class="text-center font-display text-2xl font-bold">Entrar</h2>

                <c:if test="${param.error eq 'true'}">
                    <div role="alert" class="alert alert-error mt-4" data-alert>
                        <span>Email ou senha invalidos.</span>
                        <button type="button" class="btn btn-sm btn-ghost" data-dismiss-alert aria-label="Fechar">×</button>
                    </div>
                </c:if>

                <c:if test="${param.logout eq 'true'}">
                    <div role="alert" class="alert alert-success mt-4" data-alert>
                        <span>Sessao encerrada com sucesso.</span>
                        <button type="button" class="btn btn-sm btn-ghost" data-dismiss-alert aria-label="Fechar">×</button>
                    </div>
                </c:if>

                <form method="post" action="${ctx}/login" class="mt-6 grid gap-6">
                    <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                    <ui:campo rotulo="Email">
                        <input class="input w-full" type="email" name="username" placeholder="voce@condominio.com" required autofocus>
                    </ui:campo>

                    <ui:campo-senha rotulo="Senha" nome="password" placeholder="Informe sua senha" />

                    <button type="submit" class="btn btn-primary btn-block">Entrar</button>
                </form>
            </div>
        </div>
    </section>

    <%-- Coluna decorativa do `login-02` (no bloco original, a imagem): o padrao CSS do
         `.app-padrao-login`. `aria-hidden` porque e puramente visual. --%>
    <div class="app-padrao-login hidden lg:block" aria-hidden="true"></div>
</main>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
