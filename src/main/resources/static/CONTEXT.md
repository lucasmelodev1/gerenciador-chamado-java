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
  dois ajustes de geometria escopados em `.app-sidebar` (a daisyUI vem depois de `utilities` no cascade, então
  `.menu{width:fit-content;padding:.5rem}` precisa ser sobrescrito fora de layer), o token `--card-p` (respiro
  interno dos cards) e acessibilidade.
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
  `data-auto-submit`), `tables` (`data-filter-*`) e `calendar.js` (agendas mês/semana do admin e do morador).
- `drawer.js` (`window.AppDrawer`): abre/fecha o `ui:drawer` e reemite o fechamento como evento
  `drawer:fechado` (`detail = { id, valor }`, borbulha). Hooks: `data-drawer`, `data-drawer-form`,
  `data-drawer-titulo`, `data-drawer-abrir`, `data-drawer-editar`, `data-drawer-fechar`,
  `data-drawer-aberto`, `data-drawer-backdrop`. Como não há `<dialog>`, Esc, foco preso no painel,
  devolução do foco e trava de scroll da página são implementados aqui. Também faz o **conteúdo
  dinâmico**: `data-drawer-editar` aplica `data-drawer-acao`/`data-drawer-titulo`/`data-campo-*` no
  formulário, e `data-drawer-abrir` o devolve ao estado que o servidor renderizou (`reset()`), de modo
  que criar e editar usam o mesmo drawer sem reload. Carregado em todas as páginas (é inerte sem
  `data-drawer`); o visual fica em `custom.css` sob `.app-drawer*`, junto do `prefers-reduced-motion`.
- `layout.js` foi removido: o drawer da daisyUI dispensa toggle por JS e a navegação ativa é server-side.
- `js/vendor/fullcalendar/`, `css/vendor/fullcalendar/`: FullCalendar 7.1.0 vendorizado para uso offline,
  carregado quando a view define `calendarAssets`.

## Build
- `npm run build:css` / `watch:css`. O bundle não é versionado; o estágio 0 do `Dockerfile` o gera.
