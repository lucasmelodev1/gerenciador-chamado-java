<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<%-- Pagina publica: shell proprio (sem drawer) e, por isso, o unico `<body>` que nao vem do
     `ui:shell`. As classes utilitarias substituem `.auth-body`/`.auth-layout`/`.auth-panel`/
     `.auth-brand`/`.auth-form-panel`/`.feature-list`/`.eyebrow` do CSS legado (S33, F2):
       - `.auth-body`        -> grid + place-items-center + p-[18px] sm:p-8 (+ fundo/cor do shell)
       - `.auth-layout`      -> grid w-full max-w-[1140px] gap-8, 1.1fr/0.9fr a partir de 980px
       - `.auth-panel`       -> rounded-[20px] p-10, borda clara, `shadow-painel` (a `--shadow`)
       - `.auth-brand`       -> bg-primary-strong + text-primary-content (a marca escura)
       - `.auth-form-panel`  -> flex items-center, superficie translucida + backdrop-blur
       - `.feature-list`     -> grid gap-4 pl-5 com marcador de lista
       - `.eyebrow`          -> text-xs uppercase + `tracking-eyebrow` (0.12em) + mb-2
     O `eyebrow` da marca usa `text-primary-content/70`: no legado ele saia com a cor de texto
     secundaria (`--muted`) sobre o fundo escuro — contraste baixo. E a unica diferenca
     visual intencional desta tela. --%>
<body class="grid min-h-screen place-items-center bg-base-200 p-[18px] text-base-content sm:p-8" data-page="login">
<main class="grid w-full max-w-[1140px] items-stretch gap-8 min-[980px]:grid-cols-[1.1fr_0.9fr]">
    <section class="relative overflow-hidden rounded-[20px] border border-white/60 bg-primary-strong p-[18px] text-primary-content shadow-painel sm:p-10 max-[640px]:rounded-[14px]">
        <p class="mb-2 text-xs tracking-eyebrow text-primary-content/70 uppercase">Gerenciamento de chamados</p>
        <h1 class="font-display">${appName}</h1>
        <p>
            Controle blocos, moradores, fluxo de atendimento e historico de interacoes
            em uma unica interface.
        </p>
        <ul class="grid list-disc gap-4 pl-5">
            <li class="mb-2.5">Abertura de chamados por unidade</li>
            <li class="mb-2.5">Fluxo com status e SLA configuraveis</li>
            <li class="mb-2.5">Historico de comentarios por perfil</li>
        </ul>
    </section>

    <section class="flex items-center rounded-[20px] border border-white/60 bg-base-100/90 p-[18px] shadow-painel backdrop-blur sm:p-10 max-[640px]:rounded-[14px]">
        <div class="card w-full">
            <div class="card-body">
            <p class="mb-2 text-xs tracking-eyebrow text-base-content/60 uppercase">Acesso</p>
            <h2>Entrar</h2>

            <c:if test="${param.error eq 'true'}">
                <div role="alert" class="alert alert-error" data-alert>
                    <span>Email ou senha invalidos.</span>
                    <button type="button" class="btn btn-sm btn-ghost" data-dismiss-alert aria-label="Fechar">×</button>
                </div>
            </c:if>

            <c:if test="${param.logout eq 'true'}">
                <div role="alert" class="alert alert-success" data-alert>
                    <span>Sessao encerrada com sucesso.</span>
                    <button type="button" class="btn btn-sm btn-ghost" data-dismiss-alert aria-label="Fechar">×</button>
                </div>
            </c:if>

            <form method="post" action="${ctx}/login" class="stack-form">
                <%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>
                <label class="field">
                    <span>Email</span>
                    <input class="input w-full" type="email" name="username" placeholder="voce@condominio.com" required autofocus>
                </label>

                <label class="field">
                    <span>Senha</span>
                    <div class="password-field">
                        <input class="input w-full" type="password" name="password" placeholder="Informe sua senha" required data-password-input>
                        <button type="button" class="btn btn-ghost" data-password-toggle>Mostrar</button>
                    </div>
                </label>

                <button type="submit" class="btn btn-primary btn-block">Entrar</button>
            </form>
                    </div>
        </div>
    </section>
</main>
<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
