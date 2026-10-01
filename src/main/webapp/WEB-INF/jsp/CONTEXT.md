# src/main/webapp/WEB-INF/jsp

Views JSP/JSTL dos controllers web; prefixo/sufixo em `application.properties`.

## Shell (daisyUI, desde P2)
- `fragments/head.jspf`: carrega `app.build.css` + `custom.css` e, **depois**, o CSS legado (transitório).
  A ordem importa: o legado não está em cascade layer, então vence a daisyUI onde ambos definem a mesma classe.
- `fragments/sidebar.jspf`: navegação como `drawer` + `menu`; estado ativo resolvido **no servidor**
  (`jakarta.servlet.forward.request_uri` + `aria-current`), não mais por JS.
- `fragments/topbar.jspf`: `navbar` + hambúrguer (`label for="app-drawer"`) que aciona o drawer.
- `fragments/alerts.jspf`: flash pós-redirect (`alert alert-success|alert-error`).
- `fragments/scripts.jspf`: `layout.js` não é mais carregado.

## Fragmentos de conteúdo
- `vazio.jspf`: estado vazio — `vazioTitulo` (opcional), `vazioMensagem`, `vazioCompacto`.
- `reserva-status.jspf`: badge de status de reserva com cor semântica — `reservaStatus`.
- `reservas-agenda.jspf`: calendário compartilhado (admin/morador); toolbar em `join` + `tabs`.

## Contrato com o JS (não renomear)
Ids/classes consumidos por `calendar.js`: `#calendar`, `#reservas-data`, `.reserva-data`,
`#reserva-detalhe`, `.reserva-titulo|meta|motivo`, `#form-aprovar|negar|cancelar`, `#filtro-area`,
`#reserva-fechar`; e os hooks `data-*` de `forms.js`/`tables.js`/`alerts.js`.
`scripts/ui-invariants.sh` verifica todos eles.

- `auth/`: `login.jsp`.
- `morador/`, `admin/`, `colaborador/`: páginas por perfil (`chamados/`, `reservas/`, cadastros do admin).
- Os controllers enviam mapas prontos (`WebControllerSupport`); atributos comuns vêm de `WebModelAttributeAdvice`.
