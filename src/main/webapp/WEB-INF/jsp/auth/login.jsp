<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body class="auth-body" data-page="login">
<main class="auth-layout">
    <section class="auth-panel auth-brand">
        <p class="eyebrow">Gerenciamento de chamados</p>
        <h1>${appName}</h1>
        <p>
            Controle blocos, moradores, fluxo de atendimento e historico de interacoes
            em uma unica interface.
        </p>
        <ul class="feature-list">
            <li>Abertura de chamados por unidade</li>
            <li>Fluxo com status e SLA configuraveis</li>
            <li>Historico de comentarios por perfil</li>
        </ul>
    </section>

    <section class="auth-panel auth-form-panel">
        <div class="card">
            <div class="card-body">
            <p class="eyebrow">Acesso</p>
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
