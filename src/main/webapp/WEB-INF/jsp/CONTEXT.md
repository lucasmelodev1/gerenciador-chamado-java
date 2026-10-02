# src/main/webapp/WEB-INF/jsp

Views JSP/JSTL dos controllers web; prefixo/sufixo em `application.properties`.

## Shell (daisyUI, desde P2; layout do `dashboard-01` do shadcn desde S19)
- **Toda página começa com `<%@ page pageEncoding="UTF-8" %>`.** Não é enfeite: a diretiva vale
  para o **arquivo em que aparece**, então a que está em `taglibs.jspf` (que é *incluído*) não
  vale para a página que o inclui. Sem ela o Jasper lê o arquivo como ISO-8859-1 e **todo
  acento sai duplicado** (`Ãº` no lugar de `ú`). Foi por isso que o projeto passou anos sem
  acento em texto de JSP. `scripts/ui-shell.sh` reprova página que inclua `taglibs.jspf` e não
  declare isso na primeira linha. `taglibs.jspf` mantém a sua (vale para os `.jspf`).
- **O mesmo vale para o fragmento incluído, e a diretiva tem de ser a primeira linha dele.** O
  `pageEncoding` da página que inclui não vale para o `<%@ include %>`: o Jasper lê o `.jspf` como
  ISO-8859-1 e o texto não-ASCII vira mojibake. A S30 encontrou dois casos reais disso — o `×` do
  `alerts.jspf` (saía `Ã`) e os acentos novos de `reservas-agenda.jspf`. Por isso `alerts.jspf`,
  `reservas-agenda.jspf` e `reservas-agenda-paineis.jspf` começam com a diretiva, e o
  `ui-shell.sh` reprova **qualquer** arquivo de markup (`.jsp`, `.jspf`, `.tag`) cujo primeiro
  byte não-ASCII venha antes da declaração de encoding. Texto não-ASCII dentro de comentário JSP
  não conta: sai na tradução.
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
  Estado ativo resolvido **no servidor** (`jakarta.servlet.forward.request_uri` + `aria-current`): o
  primeiro item que casa vence, e cada grupo lista os caminhos do mais específico para o mais genérico.
  A navegação é markup (`ui:nav-grupo`/`ui:nav-item`) desde a S32 — antes era a string `navGroups`
  (`Grupo@href|Rótulo|ícone#...`), que corrompia o menu se um rótulo tivesse um dos separadores.
- `fragments/topbar.jspf`: `navbar` no formato do `SiteHeader` — linha única com `border-b`, gatilho do drawer,
  separador e título da tela. Perfil e logout **não** ficam aqui (migraram para a lateral).
- `fragments/icone.jspf` **não existe mais** (S31): os ícones Tabler (outline, 3.31.0) são o
  tag `ui:icone` (`nome` + `classe`). `currentColor` faz o item ativo recolorear o ícone; alias
  desconhecido cai num círculo de fallback, que `ui-shell.sh`/`ui-tabelas.sh` reprovam.
- `fragments/alerts.jspf` **não existe mais** (S31): as mensagens de redirect são o tag
  `ui:flash` (`alert alert-success|alert-error`), chamado pelo `ui:shell`.
- `fragments/scripts.jspf`: `layout.js` não é mais carregado; é incluído pelo `ui:shell-fim`.
- `head.jspf`, `sidebar.jspf` e `topbar.jspf` são incluídos pelo `ui:shell` (S31), não pelas
  páginas: por isso o `ui:shell` define `${ctx}` antes de incluí-los.
- `scripts/ui-shell.sh` verifica o shell (estrutura, ícones, grupos, item ativo, cartão do usuário) sobre o
  HTML de `baseline/html-shell/`; roda depois de `scripts/ui-routes.sh shell`.

## Componentes próprios (`WEB-INF/tags`, prefixo `ui`)
Índice completo, atributos e exemplos em **`WEB-INF/tags/CONTEXT.md`** — leia antes de
escrever uma tela.

- **Casca (S31)**: `ui:shell` (abre doctype/`head`/drawer/lateral/topbar/`<main>`/flash e
  recebe o conteúdo) + `ui:shell-fim` (scripts e fecha o documento). São dois tags porque os
  paineis precisam nascer entre `</main>` e o fim do `<body>`; cada página declara
  `dataPagina` (+ `classeMain` no formulário estreito). O login tem shell próprio.
- **Listagens**: `ui:card-head` (com `subtitulo`), `ui:busca`, `ui:badge`, `ui:paginacao`
  (`pagina`/`url`/`parametros`, este último escapado) e as ações `ui:acao-link`
  (`texto` opcional), `ui:acao-painel`, `ui:acao-form` (mesmo `texto` opcional, `variante` e
  `classe` — é o dono do trio form + CSRF + `_method`).
- **Chamados**: `ui:tabela-chamados` (as 5 tabelas: 3 listas + 2 paineis) e
  `ui:detalhe-chamado` (as 3 telas de detalhe, por `base`/`modo`/flags).
- **Paineis**: `ui:painel` é a implementação única; `ui:drawer` (lateral) e `ui:dialog`
  (central) são cascas finas que encaminham atributos. **Precisam ficar fora de
  `.page-content`**, como filho direto do `<body>`; as telas não guardam estado de edição do
  servidor (os gatilhos `data-drawer-abrir`/`data-drawer-editar` preenchem e abrem).
  Comportamento em `static/js/drawer.js` (`AppDrawer`, evento `drawer:fechado`).
- **Utilitários**: `ui:icone` (alias + `classe`), `ui:vazio`, `ui:reserva-status` e
  `ui:flash` (mensagens de redirect).

## Telas de tabela (S24/S25, extraídas para tags em S26)

As sete telas de listagem do admin seguem o mesmo desenho, montado com os tags de
`WEB-INF/tags`: **reservas**, **areas**, **blocos**, **chamados** (só leitura),
**status-chamado**, **tipos-chamado** e **usuarios**. O contrato do desenho — cabeçalho com filete, faixa de filtros, coluna de ações
encostada na direita, badges e ações só com ícone + tooltip — está documentado em
`WEB-INF/tags/CONTEXT.md`, junto do esqueleto de uma tela nova.

O que é específico de cada tela fica no JSP: títulos, colunas, o mapeamento de cada badge e os
valores de cada linha.

- **Criar/editar** vai para o `ui:drawer` nas cinco telas que escrevem. O `perfil` do usuário
  é o único campo travado (`travar="tipo"`): o servidor recusa a troca.
- **Filtros**: a busca local (`ui:busca`) em areas, blocos, status-chamado, tipos-chamado e usuarios;
  chamados usa um `<form method="get">` na própria faixa (classe `app-card-filtros--campos`),
  porque seus três filtros vão ao servidor. Reservas é a única sem faixa de filtros.
- **Ações**: `ui:acao-form` (remover/desativar/definir padrão), `ui:acao-painel` (abre o
  painel) e `ui:acao-link` (Detalhar / Gerenciar / Ver unidades). Tipos de chamado só tem
  `ui:acao-painel` e blocos só tem `ui:acao-link` — são as telas sem endpoint de remoção.
- **status-chamado** era um `stack-list` de `.list-row` e virou tabela, para compartilhar a
  mesma coluna de ações.
- **reservas** decide no `ui:dialog` (centrado), não no `ui:drawer`: aprovar é direto
  (`ui:acao-form`), negar abre o diálogo pedindo o motivo, cancelar abre um diálogo de
  confirmação. Os dois diálogos são únicos e reaproveitados por todas as linhas.
- Os `GET` com `?areaId=`/`?statusId=`/`?tipoId=` continuam nos controllers, mas nenhuma tela
  aponta para eles: o drawer substitui aquele estado de edição. **Não remova sem remover o
  parâmetro no controller**, que é código congelado pelo `ui-invariants.sh`.
- Contrato com o JS inalterado: `data-filter-input` + `data-filter-target`, filtro local do
  `tables.js`. Nenhuma listagem de cadastro ganhou parâmetro de busca no servidor.

## S31 — o resto das telas entrou no mesmo desenho
- As três listas de chamados (admin/morador/colaborador) e os dois paineis usam
  `ui:tabela-chamados`; o formulário de filtro é `app-card-filtros--campos` e a paginação é
  `ui:paginacao` com `parametros` (que passa por `fn:escapeXml` — antes os filtros entravam
  crus no `href`).
- As três telas de detalhe do chamado são `ui:detalhe-chamado`, parametrizado por `base`,
  `eyebrow`, `avisoFinal`, `modo` (`gestao`/`morador`) e flags.
- **Não existe mais `<div class="section-header">`**: todas as telas passam pelo
  `ui:card-head` (que ganhou `subtitulo`). `ui:card-head`/`ui:card-head__texto` vivem em
  `custom.css`; o `responsive.css` não empilha mais esse bloco.
- Forms mutantes escritos à mão (csrf + `_method` + `data-confirm`) viraram `ui:acao-form`
  com `texto`/`variante`/`classe` — inclusive os "Desvincular" de usuarios e vinculos.
- Textos que divergiam por cópia foram unificados no componente: estados vazios do detalhe do
  chamado e rótulos do formulário de comentário.

## Fragmentos de conteúdo
- `reservas-agenda.jspf`: calendário compartilhado (admin/morador); toolbar em `join` + `tabs`.
  Traz o `#calendar` + os `.reserva-data`; **nada de painel de detalhe** (ver o próximo).
- `reservas-agenda-paineis.jspf`: os painéis da agenda (S30) — o `ui:drawer` informativo com a
  lista `ui:detalhe-linha` e o `ui:dialog` de cancelamento. Cada agenda inclui este fragmento
  **depois de `</main>`**, senão o `.page-content` espremeria o backdrop.
- Desde a S31 não há mais `vazio.jspf`, `icone.jspf`, `reserva-status.jspf` nem
  `alerts.jspf`: viraram `ui:vazio`, `ui:icone`, `ui:reserva-status` e `ui:flash`. As telas
  não escrevem mais `<div class="section-header">` — todas passam pelo `ui:card-head`.

## Contrato com o JS (não renomear)
`calendar.js`: `#calendar` (com `data-painel-detalhe`, que diz qual painel de detalhe o
calendário abre — o JS não conhece o id `drawer-reserva`), `#reservas-data`, `.reserva-data`
(com os `data-*` do evento), `#filtro-area` e o `dd[data-detalhe]` de cada linha; o
cancelamento é o botão que o `ui:drawer` gera a partir de `painelAcao="dialog-cancelamento"`
(`data-drawer-editar`), achado DENTRO do painel, com `_method=delete`. Mais os hooks `data-*` de
`forms.js`/`tables.js`/`alerts.js`/`drawer.js`.
`scripts/ui-invariants.sh` verifica todos eles.

Antes da S30 o detalhe era um `<section id="reserva-detalhe">` no fim da página, com os três
`<form>` escondidos (`#form-aprovar`, `#form-negar`, `#form-cancelar`): aprovar/negar saíram da
agenda (a decisão é na lista de reservas) e o cancelamento virou diálogo central.

- `auth/`: `login.jsp`.
- `morador/`, `admin/`, `colaborador/`: páginas por perfil (`chamados/`, `reservas/`, cadastros do admin).
- Os controllers enviam mapas prontos (`WebControllerSupport`); atributos comuns vêm de `WebModelAttributeAdvice`.
