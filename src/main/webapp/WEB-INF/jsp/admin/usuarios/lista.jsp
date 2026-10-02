<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jsp/fragments/taglibs.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<%@ include file="/WEB-INF/jsp/fragments/head.jspf" %>
<body data-page="admin-usuarios">
<div class="drawer lg:drawer-open">
    <%@ include file="/WEB-INF/jsp/fragments/sidebar.jspf" %>
    <div class="drawer-content">
        <%@ include file="/WEB-INF/jsp/fragments/topbar.jspf" %>
        <main id="conteudo-principal" class="page-content">
            <%@ include file="/WEB-INF/jsp/fragments/alerts.jspf" %>

            <%-- Criar e editar no mesmo drawer. "Gerenciar" continua levando ao detalhe,
                 que e onde ficam os vinculos de morador e os tipos do colaborador. --%>
            <section class="card">
                <div class="card-body">
                    <ui:card-head titulo="Usuarios" descricao="Gestao de acesso">
                        <button type="button" class="btn btn-primary btn-sm" data-drawer-abrir="drawer-usuario">
                            Novo usuario
                        </button>
                    </ui:card-head>

                    <div class="app-card-filtros">
                        <ui:busca alvo="usuarios-table" rotulo="Pesquisar usuarios" />
                    </div>

                    <c:choose>
                        <c:when test="${empty usuarios}">
                            <ui:vazio titulo="Nenhum usuario encontrado" mensagem="Cadastre administradores, colaboradores e moradores para iniciar a operacao." />
                        </c:when>
                        <c:otherwise>
                            <div class="overflow-x-auto">
                                <table class="table table-zebra" data-filter-table="usuarios-table">
                                    <thead>
                                    <tr>
                                        <th>Nome</th>
                                        <th>Email</th>
                                        <th>Perfil</th>
                                        <th><span class="sr-only">Ações</span></th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    <c:forEach items="${usuarios}" var="usuario">
                                        <tr>
                                            <td>${usuario.nome}</td>
                                            <td>${usuario.email}</td>
                                            <td><ui:badge variante="neutral">${usuario.tipo}</ui:badge></td>
                                            <td class="cell-actions app-tabela-acoes">
                                                <%-- `tipo` e travado no drawer: o PATCH deriva o perfil do
                                                     papel persistido e recusa a troca. O gatilho manda a
                                                     CHAVE (usuario.tipo e o rotulo), extraida do role. --%>
                                                <ui:acao-editar drawer="drawer-usuario" titulo="Editar usuario"
                                                                acao="${ctx}/admin/usuarios/${usuario.id}">
                                                    <input type="hidden" data-campo="nome" value="${fn:escapeXml(usuario.nome)}">
                                                    <input type="hidden" data-campo="email" value="${fn:escapeXml(usuario.email)}">
                                                    <input type="hidden" data-campo="tipo" value="${fn:substringAfter(usuario.role, 'ROLE_')}">
                                                </ui:acao-editar>
                                                <ui:acao-link href="${ctx}/admin/usuarios/${usuario.id}"
                                                              icone="ver" rotulo="Gerenciar" />
                                                <ui:acao-form acao="${ctx}/admin/usuarios/${usuario.id}"
                                                              icone="remover" rotulo="Desativar" perigo="true"
                                                              confirmacao="Deseja desativar este usuario?" />
                                            </td>
                                        </tr>
                                    </c:forEach>
                                    </tbody>
                                </table>
                            </div>
                        </c:otherwise>
                    </c:choose>

                    <ui:paginacao pagina="${usuariosPage}" url="${ctx}/admin/usuarios" />
                </div>
            </section>
        </main>
    </div>
</div>

<%-- `travar="tipo"`: na edicao o perfil fica desabilitado e um espelho escondido envia
     o valor atual — o servidor recusa a troca de tipo de qualquer forma.
     Fora de `.page-content`: o legado espremeria o backdrop. Ver custom.css > Drawer. --%>
<ui:drawer id="drawer-usuario"
           titulo="Novo usuario"
           descricao="Cadastre administradores, colaboradores e moradores."
           acao="${ctx}/admin/usuarios"
           travar="tipo">
    <label class="field">
        <span>Nome</span>
        <input class="input w-full" type="text" name="nome" value="${usuarioForm.nome}" maxlength="255" required>
    </label>

    <label class="field">
        <span>Email</span>
        <input class="input w-full" type="email" name="email" value="${usuarioForm.email}" maxlength="255" required>
    </label>

    <label class="field">
        <span>Perfil</span>
        <select class="select w-full" name="tipo" required>
            <option value="">Selecione</option>
            <c:forEach items="${tiposUsuario}" var="tipo">
                <option value="${tipo.key}" ${usuarioForm.tipo eq tipo.key ? 'selected' : ''}>${tipo.value}</option>
            </c:forEach>
        </select>
    </label>

    <label class="field">
        <span>Senha</span>
        <div class="password-field">
            <input class="input w-full" type="password" name="senha" maxlength="255" required data-password-input>
            <button type="button" class="btn btn-ghost" data-password-toggle>Mostrar</button>
        </div>
        <small class="field-hint">A senha e sempre redefinida: obrigatoria tambem ao editar.</small>
    </label>
</ui:drawer>

<%@ include file="/WEB-INF/jsp/fragments/scripts.jspf" %>
</body>
</html>
