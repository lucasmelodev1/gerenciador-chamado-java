# src/main/webapp/WEB-INF/jsp

Views JSP/JSTL dos controllers web; prefixo/sufixo em `application.properties`.

## Shell (daisyUI, desde P2; layout do `dashboard-01` do shadcn desde S19)
- `fragments/head.jspf`: carrega `app.build.css` + `custom.css` e, **depois**, o CSS legado (transitório).
  A ordem importa: o legado não está em cascade layer, então vence a daisyUI onde ambos definem a mesma classe.
  **Também materializa `${_csrf.token}` aqui, no `<head>`.** Não remova: o `CookieCsrfTokenRepository` só
  escreve o cookie `XSRF-TOKEN` quando o token é resolvido, e se isso acontecer depois de a resposta passar do
  buffer de 8 KB do Tomcat o `Set-Cookie` se perde e **todo POST autenticado vira 403** (ver EVIDENCE.md > S19).
- `fragments/sidebar.jspf`: `drawer` no formato do bloco `dashboard-01` — cabeçalho (marca + ícone), conteúdo
  (grupos com rótulo + `menu` de itens com ícone) e rodapé com o **cartão do usuário** (`avatar` + `dropdown`
  com o logout). Variante *inset*: `.drawer-side` com `p-2 lg:p-3` e painel `rounded-box`.
  Estado ativo resolvido **no servidor** (`jakarta.servlet.forward.request_uri` + `aria-current`), por prefixo
  mais longo; a navegação vive em `navGroups` (`Grupo@href|Rótulo|ícone#...`).
- `fragments/topbar.jspf`: `navbar` no formato do `SiteHeader` — linha única com `border-b`, gatilho do drawer,
  separador e título da tela. Perfil e logout **não** ficam aqui (migraram para a lateral).
- `fragments/icone.jspf`: ícones Tabler (outline, 3.31.0) como markup. Contrato: quem inclui define `icone`
  (alias) e `iconeClasse` (ex.: `size-4`); `currentColor` faz o item ativo recolorear o ícone.
- `fragments/alerts.jspf`: flash pós-redirect (`alert alert-success|alert-error`).
- `fragments/scripts.jspf`: `layout.js` não é mais carregado.
- `scripts/ui-shell.sh` verifica o shell (estrutura, ícones, grupos, item ativo, cartão do usuário) sobre o
  HTML de `baseline/html-shell/`; roda depois de `scripts/ui-routes.sh shell`.

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
