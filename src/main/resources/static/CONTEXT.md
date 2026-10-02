# src/main/resources/static

CSS/JS servidos direto pelo Spring e incluídos pelos fragmentos JSP.

## CSS
- `css/app.css`: entry do Tailwind CSS 4 + daisyUI 5 (tema `chamados`), tipografia (Inter/Noto Sans) e
  `@source` explícitos com `source(none)` — sem isso o scan varre o repositório e emite componentes citados
  apenas em documentação. Também define a escala de raios do tema (`--radius-box: 1rem`,
  `--radius-field: .625rem`, `--radius-selector: .5rem`), reduzida em S20, e as superfícies
  (`--color-base-200: #f3f4f6`, `--color-base-300: #e5e7eb`) — cinza-neutro desde S21, no lugar do creme
  `#f3efe7/#e4ded2`. O `--bg` do `base.css` (fundo real do `body`) acompanha o `base-200`.
- `css/app.build.css`: **gerado** (`npm run build:css` ou estágio `frontend` do Dockerfile); não versionado.
- `css/custom.css`: shell — painel *inset* do `drawer-content` e topbar (linha única com `border-b`) —,
  o **diálogo central** `.app-dialog` (mesmo componente do drawer, centralizado com `inset: 0` +
  `margin: auto` e `max-height`, aberto por `[data-drawer-aberto]`),
  dois ajustes de geometria escopados em `.app-sidebar` (a daisyUI vem depois de `utilities` no cascade, então
  `.menu{width:fit-content;padding:.5rem}` precisa ser sobrescrito fora de layer), o token `--card-p` (respiro
  interno dos cards) e acessibilidade.
  Também o **cabeçalho de card de listagem** (S24): `.app-card-head` é uma linha (`flex-direction: row` +
  `space-between`) com a descrição e o título num bloco de `gap: 2px` à esquerda e a ação primária à direita,
  fechada por um filete (`border-bottom: 1px solid var(--color-base-300)`) que a separa da faixa de filtros
  `.app-card-filtros`. São classes **novas** de propósito: `.section-header`/`.toolbar-inline` são legado sem
  layer (carregam depois deste arquivo) e a `responsive.css` as empilha abaixo de 900px — contra o alinhamento
  em linha. Como o `<h2>` deixa de casar com `.section-header h2`, `.app-card-head h2` repõe a tipografia
  (o preflight do Tailwind zera o tamanho do título). `scripts/ui-tabelas.sh` confere tudo isso.
  A **variante `--campos`** é para a faixa que é um `<form method="get">` com rótulo acima do
  controle: alinha as ações pela base. Ela existe porque `.app-card-filtros` não está em layer e
  venceria o utilitário `items-end` do Tailwind.
  Também a **coluna de ações das tabelas** (S25): `.app-tabela-acoes` alinha à direita (`flex-end`) e zera o
  `padding-inline: 1rem` que a daisyUI dá a toda `th/td`, para a ação encostar na borda da tabela; o `form`
  fica `display: flex` (senão a folga de descida da linha desalinha os dois ícones) e há hover próprio, porque
  o `base-200` do `btn-ghost` some sobre a linha zebrada. `.app-btn-perigo` pinta o ícone de excluir com
  `--color-error` — `btn-ghost btn-error` não serve: `.btn:hover{color:var(--btn-fg)}` e o `--btn-fg` do
  `btn-error` é quase branco. Os botões usam `btn-square` normalmente.
  Também a **lista de detalhes** (S30): `.app-detalhe-*` é o "rótulo à esquerda, valor em negrito à
  direita" do `ui:detalhe-linha` — linha em `flex` com `space-between`, valor com `font-weight: 700` e
  `text-align: end`, os dois `margin` do navegador zerados e `min-width: 0` no valor (item flex nasce com
  `min-width: auto` e um motivo longo empurraria a linha para fora do painel).
  **Camadas aninhadas:** dentro da daisyUI (`daisyui.l1` > `l1.l2` > `l1.l2.l3` > `l1.l2.l3.l4`), para
  declarações **normais** o layer **pai vence o filho** ("non-nested styles in a layer have precedence over
  normal nested styles"). É o que faz o `.btn:hover` de `l1` sobrepor o `color` do `.btn-ghost` de `l1.l2.l3` —
  e é o motivo dos dois ajustes de cor acima. O `btn-square` funciona: ele mora no layer pai do `.btn`.
  **Raio:** o legado tem valores fixos (`base.css` e `components.css`/`responsive.css`) que vencem a daisyUI por
  não estar em layer — ao mexer no raio, ajuste os dois lados, senão cards e `stat-card` divergem do shell.
- `css/calendar.css`: tema do FullCalendar; tokens `--fc-classic-*` apontam para as variáveis da daisyUI,
  com os tokens legados como fallback.
- `css/fonts/`: Inter (variável, títulos) e Noto Sans 400/500/600/700 (texto). Ficam sob `/css/` porque o
  `SecurityConfig` só libera `/css/**` sem autenticação — `/fonts/**` exigiria sessão e quebraria o login.
- `css/base.css`, `css/layout.css`, `css/components.css`, `css/responsive.css`: **legado transitório**
  (não está em cascade layer, por isso vence a daisyUI). Remoção em S17/S18.

## JS
- `core` (`window.AppDom`), `alerts`, `forms` (`data-confirm`, `data-password-*`, `data-character-*`,
  `data-auto-submit`) e `tables` (`data-filter-*`).
- `calendar.js` (agendas mês/semana do admin e do morador): monta os eventos a partir dos
  `.reserva-data`, filtra por área **no cliente** e, no clique do evento, abre o `ui:drawer` de detalhe
  (`#drawer-reserva`) preenchendo cada `dd[data-detalhe]`. A ação de cancelar é um `ui:dialog`: o botão do
  rodapé do drawer nasce com `data-drawer-editar="dialog-cancelamento"` e o `calendar.js` só reescreve o
  `data-drawer-acao` da reserva clicada (o `drawer.js` lê no clique) — o mesmo diálogo serve todas as
  reservas. O botão é escondido quando o servidor recusaria a ação (status que não seja Solicitado/Aprovado,
  ou início já alcançado).
- `drawer.js` (`window.AppDrawer`): abre/fecha o `ui:drawer` e reemite o fechamento como evento
  `drawer:fechado` (`detail = { id, valor }`, borbulha). Hooks: `data-drawer`, `data-drawer-form`,
  `data-drawer-titulo`, `data-drawer-abrir`, `data-drawer-editar`, `data-drawer-fechar`,
  `data-drawer-aberto`, `data-drawer-backdrop`. Como não há `<dialog>`, Esc, foco preso no painel,
  devolução do foco e trava de scroll da página são implementados aqui. Também faz o **conteúdo
  dinâmico**: `data-drawer-editar` passa pelo estado renderizado e depois aplica
  `data-drawer-acao`/`data-drawer-titulo` e os campos do gatilho; `data-drawer-abrir` devolve tudo ao
  estado que o servidor renderizou (`reset()`), de modo que criar e editar usam o mesmo drawer sem
  reload. Os campos vêm de duas formas: `data-campo-<name>` no botão (formato da S23) ou
  `<input data-campo="<name>">` dentro do botão (S26, a que `ui:acao-editar` usa — `value` de input
  aceita qualquer dado de usuário sem codificação em string). Com `data-drawer-travar` no formulário,
  os campos listados ficam desabilitados na edição e um espelho escondido com o mesmo `name` assume o
  envio (`disabled` não é submetido); a criação desfaz. Uma pilha (`abertos`) guarda a ordem de abertura:
  com dois painéis empilhados (o detalhe e o diálogo que ele abre), Esc, o Tab e o foco preso valem para o
  de **cima**, e o scroll só destrava quando não sobra painel aberto. Carregado em todas as páginas (é inerte sem
  `data-drawer`); o visual fica em `custom.css` sob `.app-drawer*`, junto do `prefers-reduced-motion`.
- `layout.js` foi removido: o drawer da daisyUI dispensa toggle por JS e a navegação ativa é server-side.
- `js/vendor/fullcalendar/`, `css/vendor/fullcalendar/`: FullCalendar 7.1.0 vendorizado para uso offline,
  carregado quando a view define `calendarAssets`.

## Build
- `npm run build:css` / `watch:css`. O bundle não é versionado; o estágio 0 do `Dockerfile` o gera.
