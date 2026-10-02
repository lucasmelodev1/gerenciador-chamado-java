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
  Estado ativo resolvido **no servidor** (`jakarta.servlet.forward.request_uri` + `aria-current`), por prefixo
  mais longo; a navegação vive em `navGroups` (`Grupo@href|Rótulo|ícone#...`).
- `fragments/topbar.jspf`: `navbar` no formato do `SiteHeader` — linha única com `border-b`, gatilho do drawer,
  separador e título da tela. Perfil e logout **não** ficam aqui (migraram para a lateral).
- `fragments/icone.jspf`: ícones Tabler (outline, 3.31.0) como markup. Contrato: quem inclui define `icone`
  (alias) e `iconeClasse` (ex.: `size-4`); `currentColor` faz o item ativo recolorear o ícone.
  Alias desconhecido não quebra o build: cai num círculo de fallback (que `ui-shell.sh`/`ui-tabelas.sh` reprovam).
- `fragments/alerts.jspf`: flash pós-redirect (`alert alert-success|alert-error`).
- `fragments/scripts.jspf`: `layout.js` não é mais carregado.
- `scripts/ui-shell.sh` verifica o shell (estrutura, ícones, grupos, item ativo, cartão do usuário) sobre o
  HTML de `baseline/html-shell/`; roda depois de `scripts/ui-routes.sh shell`.

## Componentes próprios (`WEB-INF/tags`, prefixo `ui`)
- Seis tags montam as telas de tabela: `ui:card-head`, `ui:busca`, `ui:badge`,
  `ui:acao-link`, `ui:acao-editar`, `ui:acao-form` e `ui:drawer`. Atributos, protocolo de
  criar/editar e esqueleto de uma tela nova estão em **`WEB-INF/tags/CONTEXT.md`** — leia
  antes de escrever uma listagem.
- `ui:drawer` — painel lateral que desliza da borda (topo com título/descrição/X, slot livre
  no meio e rodapé só com Salvar). **Precisa ser incluído fora de `.page-content`**, como
  filho direto do `<body>`. A tela não guarda estado de edição do servidor: o drawer vem
  sempre fechado e no modo de criação, e os gatilhos `data-drawer-abrir`/`data-drawer-editar`
  é que preenchem e abrem. Comportamento em `static/js/drawer.js` (`AppDrawer`,
  evento `drawer:fechado`).

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
- **Ações**: `ui:acao-form` (remover/desativar/definir padrão), `ui:acao-editar` (abre o
  drawer) e `ui:acao-link` (Detalhar / Gerenciar / Ver unidades). Tipos de chamado só tem
  `ui:acao-editar` e blocos só tem `ui:acao-link` — são as telas sem endpoint de remoção.
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

## Fragmentos de conteúdo
- `vazio.jspf`: estado vazio — `vazioTitulo` (opcional), `vazioMensagem`, `vazioCompacto`.
- `reserva-status.jspf`: badge de status de reserva com cor semântica — `reservaStatus`.
- `reservas-agenda.jspf`: calendário compartilhado (admin/morador); toolbar em `join` + `tabs`.
  Traz o `#calendar` + os `.reserva-data`; **nada de painel de detalhe** (ver o próximo).
- `reservas-agenda-paineis.jspf`: os painéis da agenda (S30) — o `ui:drawer` informativo com a
  lista `ui:detalhe-linha` e o `ui:dialog` de cancelamento. Cada agenda inclui este fragmento
  **depois de `</main>`**, senão o `.page-content` espremeria o backdrop.

## Contrato com o JS (não renomear)
`calendar.js`: `#calendar`, `#reservas-data`, `.reserva-data` (com os `data-*` do evento),
`#filtro-area`, `#drawer-reserva` (o detalhe) e o `dd[data-detalhe]` de cada linha; o
cancelamento é o botão que o `ui:drawer` gera a partir de `painelAcao="dialog-cancelamento"`
(`data-drawer-editar`), com `_method=delete`. Mais os hooks `data-*` de
`forms.js`/`tables.js`/`alerts.js`/`drawer.js`.
`scripts/ui-invariants.sh` verifica todos eles.

Antes da S30 o detalhe era um `<section id="reserva-detalhe">` no fim da página, com os três
`<form>` escondidos (`#form-aprovar`, `#form-negar`, `#form-cancelar`): aprovar/negar saíram da
agenda (a decisão é na lista de reservas) e o cancelamento virou diálogo central.

- `auth/`: `login.jsp`.
- `morador/`, `admin/`, `colaborador/`: páginas por perfil (`chamados/`, `reservas/`, cadastros do admin).
- Os controllers enviam mapas prontos (`WebControllerSupport`); atributos comuns vêm de `WebModelAttributeAdvice`.
