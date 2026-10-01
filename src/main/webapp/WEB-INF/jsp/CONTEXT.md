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
  com o logout). A lateral fica **sobre o fundo da página**, sem superfície própria: nada de `bg-base-100`,
  borda, `rounded-box` ou sombra no `<aside>`. Ela só é opaca abaixo de `lg` (`bg-base-200`), porque aí o
  `.drawer-overlay` escurece a página atrás; de `lg` para cima é `lg:bg-transparent`.
  Por isso os hovers do cabeçalho e do cartão usam `bg-base-content/10` (e não `bg-base-200`, que seria
  invisível sobre o próprio fundo). `scripts/ui-shell.sh` falha se o `<aside>` voltar a ser uma ilha.
  O inset do conteúdo é `.drawer-side` com `p-1.5 lg:p-2` + margem/raio no `.drawer-content` (custom.css).
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

## Componentes próprios (`WEB-INF/tags`, prefixo `ui`)
- `ui:drawer` — painel lateral que desliza da borda: topo (título + descrição + X), slot
  livre no meio (`<jsp:doBody/>`) e rodapé (Salvar + Fechar). Declarado em
  `WEB-INF/tags/drawer.tag` e liberado pelo prefixo `ui` em `fragments/taglibs.jspf`.
  Comportamento em `static/js/drawer.js` (`AppDrawer`, evento `drawer:fechado`).
  **Precisa ser incluído fora de `.page-content`** (filho direto do `<body>`).
  Hoje usado em uma única tela: `admin/areas/lista.jsp`.

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
