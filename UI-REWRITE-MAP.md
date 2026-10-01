# UI Rewrite Map — Gerenciador de Chamados

Planning artifact for a full UI rewrite of the JSP views on **Tailwind CSS 4 + daisyUI 5**, keeping the
existing Spring Boot / JSP / JSTL stack and all current functionality. Scope is **presentation only**: no
controller, service, repository, route, form field name, or view-name changes.

Reference inputs:

- `Desafio_seleção.pdf` → DESAFIO N° 003/2026 (Reservas de Áreas Comuns), 11 pages. Functionality, roles and
  acceptance criteria are already implemented; the UI is the remaining weak point.
- All 34 templates under `src/main/webapp/WEB-INF/jsp/` (26 pages + 8 fragments).
- `src/main/resources/static/css/{base,layout,components,calendar,responsive}.css` (1085 lines) and
  `src/main/resources/static/js/{core,layout,forms,tables,alerts,calendar}.js` (339 lines).
- daisyUI 5 component list: <https://daisyui.com/llms.txt> (metadata `version: 5.7.x`), install/config:
  <https://daisyui.com/docs/install/>.

---

## 1. TL;DR — the ten keynotes

1. **daisyUI needs a build step the project does not have.** There is no Node/npm/Tailwind pipeline, no
   `package.json`, and the WAR is built by Maven only (`pom.xml`, `Dockerfile`, `docker-compose.yml`).
   Adding daisyUI means adding one. Options in §3.
2. **JSP is a *scanning* barrier, not a rendering barrier.** Tailwind v4 extracts class candidates from raw
   file text. Plain `class="btn btn-primary"` in a `.jsp`/`.jspf` works once the directory is declared with
   `@source`. What breaks is **runtime-composed class names** (`class="badge badge-${x}"`, or a class string
   assembled in Java). Those must be literal in the template or safelisted. §4.
3. **Class-name collisions are the biggest regression risk.** The project already defines `.card`, `.btn`,
   `.alert`, `.divider`, `.timeline`, `.pagination` — the same names daisyUI owns, with different meaning.
   The four legacy CSS files must be deleted, not kept alongside. §4.3.
4. **Five fragments restyle all 26 screens.** `head`, `topbar`, `sidebar`, `alerts`, `scripts` +
   `reservas-agenda`. Highest-leverage work; also the riskiest, because it flips every screen at once.
5. **26 files, but only ~10 page archetypes.** Extract shared fragments first (table+filter+pagination,
   detail grid, form field) or the rewrite multiplies the manual effort by 3–7×. §6.
6. **Server-rendered, zero-JS navigation stays.** Full page reloads, `redirect:` + flash messages, CSRF
   hidden input, `_method` form override. daisyUI components that assume client state (modal, dropdown,
   tabs, drawer) need *added* JS, not replacement of the current model.
7. **JS hooks must be preserved or migrated deliberately.** `layout.js`, `forms.js`, `tables.js`,
   `alerts.js`, `calendar.js` select by class (`nav-link`, `is-hidden`, `password-field`,
   `.reserva-titulo`) and by `data-*`. §5.
8. **Keep FullCalendar.** daisyUI 5's `calendar` component only styles Cally / react-day-picker / Vanilla
   Calendar Pro — not FullCalendar. The vendored FullCalendar decision is already recorded in
   `ESPECIFICACAO.md`; restyle it via its CSS variables instead. §7.
9. **Only ~9 things need genuine hand-written CSS.** Everything else is a daisyUI component or a Tailwind
   utility. §8.
10. **The existing test suite does not assert markup.** Verified: 22 test files, zero CSS/class/HTML
    assertions; web tests assert `view().name(...)`, model attributes and redirects only. Do **not** rename
    view names or model attribute keys, and the rewrite is test-safe. §9.

---

## 2. Screen inventory (all affected)

26 pages + 8 fragments. Routes from `infrastructure/controller/web/*`.

| # | Screen (JSP) | Route (GET) | Role | Archetype |
|---|---|---|---|---|
| 1 | `auth/login.jsp` | `/login` | public | A — split auth |
| 2 | `admin/dashboard.jsp` | `/admin` | admin | B — stat dashboard |
| 3 | `morador/dashboard.jsp` | `/morador` | morador | B — stat dashboard |
| 4 | `colaborador/dashboard.jsp` | `/colaborador` | colaborador | B — stat dashboard |
| 5 | `admin/blocos/lista.jsp` | `/admin/blocos` | admin | D — form + list |
| 6 | `admin/blocos/detalhe.jsp` | `/admin/blocos/{id}` | admin | G — hero + table |
| 7 | `admin/areas/lista.jsp` | `/admin/areas` | admin | D — form + list |
| 8 | `admin/tipos-chamado/lista.jsp` | `/admin/tipos-chamado` | admin | D — form + list |
| 9 | `admin/status-chamado/lista.jsp` | `/admin/status-chamado` | admin | D — form + card list |
| 10 | `admin/usuarios/lista.jsp` | `/admin/usuarios` | admin | D — form + list |
| 11 | `admin/usuarios/detalhe.jsp` | `/admin/usuarios/{id}` | admin | F — form + nested relations |
| 12 | `admin/vinculos-morador/lista.jsp` | `/admin/vinculos-morador` | admin | D+ — form + 2 lists, dual paging |
| 13 | `admin/escopo-colaborador/lista.jsp` | `/admin/escopo-colaborador` | admin | D+ — form + assignment |
| 14 | `admin/chamados/lista.jsp` | `/admin/chamados` | admin | C — filtered list |
| 15 | `admin/chamados/detalhe.jsp` | `/admin/chamados/{id}` | admin | E — detail cards |
| 16 | `admin/reservas/lista.jsp` | `/admin/reservas` | admin | C — filtered list + row actions |
| 17 | `admin/reservas/agenda.jsp` | `/admin/reservas/agenda?inicio&view` | admin | J — calendar + detail panel |
| 18 | `morador/chamados/lista.jsp` | `/morador/chamados` | morador | C — filtered list |
| 19 | `morador/chamados/novo.jsp` | `/morador/chamados/novo` | morador | H — narrow form |
| 20 | `morador/chamados/detalhe.jsp` | `/morador/chamados/{id}` | morador | E — detail cards + upload |
| 21 | `morador/reservas/lista.jsp` | `/morador/reservas` | morador | C — list + cancel |
| 22 | `morador/reservas/nova.jsp` | `/morador/reservas/nova` | morador | H — narrow form |
| 23 | `morador/reservas/disponibilidade.jsp` | `/morador/reservas/disponibilidade` | morador | I — query + table |
| 24 | `morador/reservas/agenda.jsp` | `/morador/reservas/agenda?inicio&view` | morador | J — calendar + detail panel |
| 25 | `colaborador/chamados/lista.jsp` | `/colaborador/chamados` | colaborador | C — filtered list |
| 26 | `colaborador/chamados/detalhe.jsp` | `/colaborador/chamados/{id}` | colaborador | E — detail cards |

Fragments (shared, 8): `taglibs.jspf`, `head.jspf`, `topbar.jspf`, `sidebar.jspf`, `alerts.jspf`,
`scripts.jspf`, `csrf.jspf`, `reservas-agenda.jspf`.

**Invariant:** `view().name(...)` strings are asserted by tests — never move or rename a JSP path.
Also never rename the model attribute keys consumed by the templates (`pageTitle`, `appName`,
`currentUserEmail`, `currentUserRoleLabel`, `currentUserHome`, `isAdministrador|isColaborador|isMorador`,
`calendarAssets`, `*Page`, `filtro*`, `*Form`, `*Edicao`, `successMessage`, `errorMessage`).

---

## 3. Build & tooling barrier (decision required)

### Current state

- `pom.xml`: WAR, no frontend plugin. Assets are static files under `src/main/resources/static/`, copied
  into the WAR and served by the static-resource filter chain (`SecurityConfig.StaticResourcesConfig`
  permits `/css/**`, `/js/**`, `/images/**`, `/webjars/**`).
- `head.jspf` links 4 CSS files unconditionally + 4 more when `calendarAssets` is true.
- Node 22 / npm exist on the dev host; nothing in the repo uses them.
- `docker compose up` is a graded deliverable, and FullCalendar was **vendored** instead of CDN'd for
  stability (`ESPECIFICACAO.md`, "Decisões fora de escopo" item 1). The rewrite should stay self-contained
  and offline-capable.

### Options

| Option | How | Pros | Cons |
|---|---|---|---|
| **A. Node stage in Docker + Maven hook** (recommended) | `package.json` + `@tailwindcss/cli`; a `node:22-alpine` stage (or `frontend-maven-plugin`) runs the CLI before `mvn package` | Reproducible, no stale CSS, keeps offline runtime, no browser JS | Adds npm to the build (network on first `docker compose up --build`); two toolchains |
| **B. Vendored/committed compiled CSS** | Run the CLI locally, commit the generated `app.css` next to the sources | Zero build change, fully offline, mirrors the FullCalendar decision | Every class edit needs a manual rebuild; real risk of stale CSS shipped |
| **C. Browser CDN** (`@tailwindcss/browser` + `daisyui@5`) | Two `<link>/<script>` tags in `head.jspf` | Fastest to try | Runtime JS compiler, FOUC, CDN dependency in production, contradicts the existing vendoring decision, and the CDN build omits `is-drawer-open:`/`is-drawer-close:` variants |

**Recommendation:** Option A, with the compiled artifact *not* committed and a CI guard
(`npm run build:css && git diff --exit-code` is only needed for Option B). Keep `src/main/resources/
static/css/vendor/fullcalendar/` untouched.

### Entry CSS (Tailwind 4 + daisyUI 5)

```css
/* src/main/resources/static/css/app.css */
@import "tailwindcss";
@source "../../../../webapp/WEB-INF/jsp";   /* JSP + .jspf live here */
@source "../js";                             /* JS toggles classes too */
@plugin "daisyui" {
  themes: false;                             /* drop built-ins; custom theme only */
}
@plugin "daisyui/theme" {
  name: "chamados";
  default: true;
  color-scheme: light;
  /* all required color, radius, size, border, depth and noise variables — see §7.1 */
}
```

Notes:

- Tailwind 4 **deprecates `tailwind.config.js`**; theme config lives in CSS (`@theme`, `@plugin`).
- `@source` is relative to the CSS file. Explicit declarations are the fix for the JSP barrier — do not rely
  on auto-detection.
- Keep the deliverable doc and `*.md` out of the scan (they are full of class names); `@source` only the
  JSP/JS trees.

---

## 4. The JSP barrier — concrete rules

### 4.1 What works

JSTL/JSP does not stop Tailwind: it scans **raw text**, so every class name literally present in the file is
extracted, including inside EL ternaries:

```jsp
<a class="btn ${viewAtual eq 'mes' ? 'btn-primary' : 'btn-secondary'}" ...>   <!-- OK: both literals seen -->
<span class="status-pill ${unidade.vinculadaAoMorador ? '' : 'neutral'}">    <!-- OK -->
```

### 4.2 What breaks

| Pattern | Problem | Fix |
|---|---|---|
| `class="badge badge-${reserva.badgeColor}"` | Only `badge-` is extracted → no color emitted | Literal map in the JSP (`<c:choose>`) or `@source inline("badge-warning badge-success badge-error badge-neutral")` |
| Class string built in Java (`WebControllerSupport` returning `"badge badge-warning"`) | Tailwind never reads `.java` | Same as above, or add `@source "../../java"` **and** keep the literal — safelist is safer |
| Concatenation in JS (`"badge-" + status`) | Same | Literal map in `calendar.js`/`tables.js`, or safelist |
| `class="${classeDinamica}"` | Nothing extracted | Never; keep the literal in the template |
| Dynamic `statusNome` of chamados | Status names are **admin-configurable rows** → unbounded value set | Style unknown statuses with a neutral `badge badge-ghost`; only reserva/área/usuário statuses (fixed enums) get semantic colors |

**Rule to enforce in review:** no daisyUI class name may be assembled from a variable. If a class must be
data-driven, it is chosen by a literal `<c:choose>` in the template or declared in `@source inline(...)`.

### 4.3 Class-collision register (must be removed, not merged)

| Colliding class | Current meaning | daisyUI meaning | Action |
|---|---|---|---|
| `.card`, `.hero-card` | frosted panel, `::before` gradient, hover lift | `card` requires `card-body`; no padding on the root | Rewrite markup to `card` + `card-body`; delete legacy rules |
| `.btn`, `.btn-primary`, `.btn-secondary`, `.btn-danger`, `.btn-link`, `.btn-block` | gradient pills (`-secondary` = white/neutral!) | `btn` + `btn-primary`/`btn-secondary`(**brand color!**)/`btn-error`/`btn-link`/`btn-block` | **`btn-secondary` changes meaning.** Map legacy `.btn-secondary` → `btn` (default) or `btn-soft`; legacy `.btn-danger` → `btn-error` |
| `.alert`, `.alert-success`, `.alert-danger` | inline flash banner | `alert` + `alert-success` / **`alert-error`** | `alert-danger` → `alert-error` |
| `.divider` | 1px horizontal rule with margin | flex divider (text/vertical) | Use `divider` markup or a plain `border-t border-base-300`; do not keep both |
| `.timeline`, `.timeline-item` | custom dot + `::before` rail | `timeline` + `timeline-start/middle/end/box` | Markup rewrite required, not a class swap |
| `.pagination` | flex row, prev/next + counter | no component; docs use `join` | Rebuild with `join`/`join-item` |
| `.table-search` | input | `input`/`input-sm` | Replace |
| `.mobile-nav-button` | CSS-drawn 3-bar hamburger | `btn btn-ghost btn-square` + inline SVG | Replace (no CSS) |

Dead/inconsistent classes found while mapping (fix or drop in the rewrite):

- `section-subtitle`, `helper-text`, `status-row` are used in JSPs but **never defined in any CSS file**.
- Two confirmation mechanisms coexist: `data-confirm` (handled by `forms.js`) and inline
  `onsubmit="return confirm(...)"` (`admin/areas/lista`, `admin/reservas/lista`, `morador/reservas/lista`,
  `reservas-agenda.jspf`). Pick `data-confirm` as the single mechanism.
- `status-pill` has no per-status color, so `Solicitado`, `Aprovado`, `Negado` and `Cancelado` render
  identically. Real UX defect; the badge mapping fixes it.
- All pt-BR copy is unaccented ASCII ("Operacao", "Areas", "Solicitacao"). `taglibs.jspf` already declares
  `pageEncoding="UTF-8"` and `head.jspf` `charset="UTF-8"`, so accents are safe. Decide explicitly.

### 4.4 Form/CSRF invariants (never touched by the rewrite)

- Every mutating form stays `method="post"` + `action` URL exactly as today, with
  `<%@ include file="/WEB-INF/jsp/fragments/csrf.jspf" %>` inside it.
- `_method` hidden inputs (`patch`/`delete`/`put`) are required —
  `spring.mvc.hiddenmethod.filter.enabled=true`.
- Mutations live in `controller/api` but are mapped to the **same page paths** (`/admin/reservas/{id}/
  aprovacao`, `/morador/reservas/{id}`, `/admin/usuarios/{id}`, …) and are session+CSRF authenticated. A
  daisyUI `<dialog>`/JS fetch refactor must keep sending `X-XSRF-TOKEN`/the CSRF field.
- `enctype="multipart/form-data"` must survive on the 5 upload forms (chamado inicial, comentário ×3,
  anexo ×3).
- Flash messages come from `RedirectAttributes` → `successMessage`/`errorMessage`. Keep the
  `alerts.jspf` contract.
- Pagination is server-rendered links; only `<select>` filters auto-submit (`data-auto-submit`).
  The agenda navigates by `?inicio=YYYY-MM-DD&view=mes|semana`.

---

## 5. JavaScript hooks that must survive (or be migrated on purpose)

| Hook | Owner | Used by | Recommendation |
|---|---|---|---|
| `[data-sidebar]`, `[data-sidebar-toggle]`, `[data-sidebar-backdrop]`, `.is-open`, `.is-visible` | `layout.js` | shell | **Delete** — replaced by daisyUI `drawer` + `drawer-toggle` checkbox |
| `.nav-link`, `.is-active`, `aria-current` | `layout.js` | shell | Prefer server-side active state (`aria-current="page"` per route) + `menu-active`; otherwise rename to `[data-nav-link]` |
| `[data-confirm]` | `forms.js` | all destructive forms | Keep (phase 1); optionally upgrade to a daisyUI `<dialog class="modal">` (phase 2) |
| `[data-password-toggle]` + `[data-password-input]` + `.password-field` | `forms.js` | login, usuarios lista/detalhe | Keep data attrs; if `password-field` becomes `join`, update the `closest()` selector |
| `[data-character-count]` + `[data-character-output]` + `field.parentElement` | `forms.js` | textareas (3 files) | DaisyUI `fieldset` wrappers can change `parentElement` → switch to `closest('[data-character-field]')` when restructuring |
| `[data-auto-submit]` | `forms.js` | usuarios/blocos/colaborador selects | Keep |
| `[data-filter-input]`, `[data-filter-target]`, `[data-filter-table]`, `.is-hidden` | `tables.js` | areas, blocos, tipos, usuarios lists | Keep attributes; swap `.is-hidden` for Tailwind `hidden` in the same commit |
| `[data-alert]`, `[data-dismiss-alert]` | `alerts.js` | flash | Keep; add `role="alert"`; consider daisyUI `toast` | 
| `#calendar`, `data-view`, `data-referencia`, `data-base-url`, `data-modo` | `calendar.js` | agenda ×2 | Keep ids/attrs; restyle via `calendar.css` |
| `#reservas-data .reserva-data[data-*]` | `calendar.js` | agenda ×2 | Keep the hidden data island (or pass JSON) |
| `#reserva-detalhe`, `.reserva-titulo`, `.reserva-meta`, `.reserva-motivo`, `#form-aprovar`, `#form-negar`, `#form-cancelar`, `.hidden` toggling | `calendar.js` | agenda ×2 | Keep ids/classes, or update `calendar.js` in the same commit |
| `#filtro-area`, `#reserva-fechar` | `calendar.js` | agenda ×2 | Keep |

`calendar.js` also hardcodes pt-BR status literals (`"Aprovado"`, `"Negado"`, `"Cancelado"`,
`"Solicitado"`) and a hex palette `CORES_AREAS`. If the rewrite changes status *display* strings, the
calendar breaks — read from `data-status` values, or add a stable `data-status-nome`.

---

## 6. Page archetypes → fragment strategy

26 templates, ~10 shapes. Extract these fragments **before** restyling, so each shape is written once:

1. `fragments/shell-*.jspf` — head/topbar/sidebar/alerts/scripts (already exist; rewrite in place).
2. `fragments/form-field.jspf` — label + control + hint + error slot (used ~60×).
3. `fragments/tabela.jspf` — `card` + `overflow-x-auto` + `table` + `empty-state` + `pagination`.
4. `fragments/lista-filtros.jspf` — GET filter grid + Filtrar/Limpar.
5. `fragments/detalhe-grid.jspf` — label/value tile grid.
6. `fragments/paginacao.jspf` — `join` prev/counter/next, preserving query params.
7. `fragments/comentarios.jspf` — timeline + composer, currently duplicated across the 3 chamado detail
   pages (~80% identical).
8. `fragments/acoes-reserva.jspf` — aprovar/negar/cancelar forms (shared by agenda + listas).
9. `fragments/confirm-modal.jspf` — optional, replaces `window.confirm`.

---

## 7. daisyUI mapping — components that translate

Bucket 1 of 3: **existing UI → daisyUI component**. (Bucket 2 = Tailwind layout utilities, §8.1;
bucket 3 = genuinely custom CSS, §8.2.)

### 7.1 Theme and tokens

Map the existing `:root` palette (`base.css`) into a daisyUI custom theme:

| Current token | Value | daisyUI token |
|---|---|---|
| `--bg` / page gradient | `#f3efe7` | `base-100` / `base-200` |
| `--panel`, `--panel-strong` | `#fff` @ 90% | `base-100` (+ `bg-base-100/80 backdrop-blur`) |
| `--ink` | `#122033` | `base-content` |
| `--muted` | `#5d6a7c` | `base-content/60` |
| `--primary`, `--primary-strong` | `#0d5c63`, `#093f44` | `primary`, `primary-content` |
| `--accent` | `#dba24a` | `accent` (or `secondary`) |
| `--success` | `#167c5b` | `success` |
| `--danger` | `#b64134` | `error` |
| `--neutral` | `#5f6c80` | `neutral` |
| `--radius-lg/md/sm` | 24/18/12px | `--radius-box` / `--radius-selector` / `--radius-field` |
| `--font-sans` / `--font-serif` | Trebuchet / Georgia | `@theme --font-*` |
| shadows | 3 custom levels | `--depth`, plus `shadow-*` utilities |

Design decisions to make:

- The current design mixes **pill buttons** (`border-radius: 999px`) with **14px inputs**, but daisyUI has a
  single `--radius-field` shared by button/input/select/tab. Either accept one radius, or keep pills via
  `@utility btn { @apply rounded-full; }`.
- The serif headings (`--font-serif` on `h1/h2`) are a brand trait; decide to keep (`font-serif`) or drop to
  Trebuchet for consistency. No daisyUI equivalent — a theme choice.
- **Dark mode is net-new.** daisyUI themes + `data-theme` on `<html>` in `head.jspf` + an optional
  `theme-controller` checkbox in `topbar.jspf`. Do **not** use Tailwind `dark:` with daisyUI colors; define
  `@custom-variant dark` if a dark theme is enabled.

### 7.2 Shell / layout components

| Current | daisyUI | Notes |
|---|---|---|
| `.app-shell` (280px + 1fr grid), `.sidebar` (fixed, translateX), `.sidebar-backdrop`, `layout.js` toggle, `.mobile-nav-button` | `drawer` + `drawer-toggle` + `drawer-content` + `drawer-side` + `drawer-overlay` | Removes ~90 lines of CSS + one JS function. Hamburger becomes `<label for="app-drawer" class="btn btn-ghost btn-square lg:hidden">` with an inline SVG |
| `.nav-list` / `.nav-link` | `menu menu-lg` + `menu-title`; active = `menu-active` + `aria-current="page"` | Move active-state detection server-side (route is known) |
| `.brand-block`, `.brand-chip`, `.brand-mark`, `.sidebar-footer` | `badge badge-ghost badge-sm`, plain text + `menu-title`, `divider` | Mostly manual composition |
| `.topbar`, `.topbar-actions`, `.profile-chip` | `navbar` + `navbar-start`/`navbar-end`; profile → `dropdown` + `avatar`/`menu` | Keep `sticky top-0 z-20 bg-base-100/80 backdrop-blur` (utility combo) |
| `.page-content` wrapper | `grid gap-6 max-w-[1360px] mx-auto px-5 lg:px-8` | Pure utilities |
| `.eyebrow` | `text-xs uppercase tracking-widest text-base-content/60` | No component |
| `.section-header`, `.section-subtitle` | `flex items-start justify-between gap-4 border-b border-base-300 pb-4 mb-5` + `text-sm text-base-content/60` | Utilities |
| `.narrow-content` | `max-w-3xl mx-auto` | Utility |
| buttons (`.btn*`, `.ghost-button`, `.icon-button`) | `btn`, `btn-primary`, `btn-error`, `btn-ghost`, `btn-link`, `btn-block`, `btn-square`, `btn-sm`, `btn-disabled` | Watch the `btn-secondary` semantic trap (§4.3) |
| `.status-pill`, `.status-pill.neutral` | `badge`, `badge-success`, `badge-warning`, `badge-error`, `badge-neutral`, `badge-ghost` | Fixes today's monochrome statuses; see §4.2 for extraction safety |
| `.divider` | `divider` | Structure change (element + optional text) |

### 7.3 Data-display components

| Current | daisyUI | Notes |
|---|---|---|
| `.stats-grid` + `.stat-card` + `.stat-card-wide` | `stats` (`stats-vertical lg:stats-horizontal`) + `stat` + `stat-title`/`stat-value`/`stat-desc`/`stat-actions` | The accent bar (`::after`) and gradient of `.stat-card-wide` need custom CSS or a `bg-primary text-primary-content` stat |
| `.card`, `.hero-card`, `.section-header` grouping | `card` + `card-body` + `card-title` + `card-actions`, `card-border`/`card-dash` | Markup must add `card-body` |
| `.hero-card` + `.hero-metrics` (blocos detalhe) | `hero`/`card bg-base-200` + `stats` | Partial |
| `.table-wrap` + `.data-table` | `overflow-x-auto` + `table` (+ `table-zebra`, `table-sm`, `table-pin-rows`) | Keep `.compact-table` as `table-sm`; long admin tables get `table-pin-rows` |
| `.cell-actions` | `flex flex-wrap items-center gap-2` | Utility |
| `.table-search` (local filter) | `input input-sm` | `tables.js` filter unchanged |
| `.pagination` | `join` + `join-item` + `btn` | daisyUI has no pagination component |
| `.timeline` + `.timeline-item` (comments) | `timeline timeline-vertical` + `timeline-start`/`timeline-middle`/`timeline-end` + `timeline-box` | Markup rewrite; comment bubble = `timeline-box` (`card bg-base-200`) |
| `.alert`, `.alert-success`, `.alert-danger` | `alert`, `alert-success`, `alert-error` (+ `alert-soft`) | Add `role="alert"` |
| `.list-row` (unit/attachment/assignment rows) | no component → `flex justify-between items-center gap-3 rounded-box border border-base-300 bg-base-100 p-4`; or `card card-body card-sm` | Candidate for a fragment |
| `.detail-list` (label/value tiles) | no component → `grid grid-cols-2 gap-3` of `bg-base-200 rounded-box p-3`, or `stats`/`stat` per field | Custom composition |
| `.description-box` | no component → `bg-base-200 rounded-box p-4 whitespace-pre-wrap` (accent variant is custom) | Custom |
| `.empty-state`, `.empty-state.compact` | **no daisyUI counterpart** → `border border-dashed border-base-300 rounded-box p-9 text-center` (optionally `hero`) | Custom |
| `.field-hint`, `helper-text` | `text-xs text-base-content/60` (`label` / `validator-hint` for form-bound hints) | Utility |
| `.status-row` | dead class — remove | — |
| status/lifecycle emphasis | `steps` + `step-primary` (reserva: Solicitada → Aprovada/Negada → Cancelada), `badge`, `status`, `progress`, `radial-progress` | **Net-new capability**, good UX win for RN-01-13/14 history |

### 7.4 Forms and inputs

| Current | daisyUI | Notes |
|---|---|---|
| `.field` (label > span + control) | `fieldset` + `fieldset-legend` + control + `label` hint; or keep the implicit `<label>` wrapper and add `input`/`select`/`textarea` | Verify exact v5 class names against the docs at implementation time |
| `.field input/select/textarea` | `input`, `select`, `textarea` (+ `input-bordered` is default in v5; `select-ghost`, `textarea-ghost`) | Sizes `-sm`/`-lg` |
| `.password-field` (1fr auto grid) | `join` + `input join-item` + `btn join-item` | Update `forms.js` `closest(".password-field")` if the class goes away |
| file inputs (5 forms) | `file-input` (+ `file-input-bordered`) | `enctype` unchanged |
| `data-character-count` + `.field-hint` | `label` / `validator-hint` | Keep `data-*` hooks |
| HTML5 `required`/`maxlength`/`min`/`disabled` | `validator` + `validator-hint`, `input-disabled` | **Server-side validation stays authoritative**; client hints are additive |
| `_method` + `_csrf` hidden inputs | untouched | Do not let a component wrapper hoist them out of the `<form>` |
| `<option disabled>` (already linked) | untouched | daisyUI does not restyle options |
| `data-auto-submit` selects | `select` + optional `loading loading-spinner` | Behavior unchanged |
| destructive action confirm | `modal` (`<dialog class="modal">` + `modal-box` + `modal-action` + `modal-backdrop`) | Phase 2; needs new JS to submit the triggering form |
| flash stack | `toast` + `toast-end` + `alert` | Optional; `alerts.jspf` already sufficient |

### 7.5 Net-new daisyUI capability available (nothing uses it today)

`drawer`, `modal`, `dropdown`, `toast`, `tabs`, `steps`, `tooltip`, `breadcrumbs`, `skeleton`,
`theme-controller`, `progress`, `join`, `validator`, `table-pin-rows`, `avatar`. There are **no checkboxes,
radios, toggles, ranges or ratings** anywhere in the app, so `checkbox`/`radio`/`toggle`/`range`/`rating`
are not needed.

High-value opportunities: drawer (mobile nav), modal (destructive confirm + reservation decision),
toast (flash), tabs/join (agenda Mes/Semana + prev/next), steps (reservation lifecycle), tooltip (long
area names/denial reasons), breadcrumbs (admin detail pages), theme-controller (dark mode).

---

## 8. What needs manual work

### 8.1 Bucket 2 — layout only → Tailwind utilities (no hand-written CSS)

Every one of these existing layout classes disappears into utility classes. This is the bulk of the CSS
deletion: `layout.css` (314 lines), most of `responsive.css` (121 lines) and `components.css` (386 lines).

| Current | Replacement |
|---|---|
| `.two-column-grid`, `.detail-grid` | `grid gap-6 lg:grid-cols-[minmax(320px,420px)_1fr]` (breakpoints replace the media queries) |
| `.form-grid`, `.filter-grid` | `grid gap-4 md:grid-cols-2` / `grid gap-4 md:grid-cols-3 items-end` |
| `.stack-form`, `.stack-list` | `grid gap-4` / `flex flex-col gap-3` |
| `.button-row`, `.toolbar-inline`, `.inline-form`, `.cell-actions`, `.align-end` | `flex flex-wrap items-center gap-3` (+ `items-end`) |
| `.inline-panel`, `.compact-form`, `.danger-zone` | `mt-5 flex flex-wrap items-end gap-3`, `mt-4`, `mt-5 border-t border-error/20 pt-5` |
| `.detail-list` (grid) | `grid gap-3 sm:grid-cols-2` |
| `.stats-grid` responsive rules | `grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6` |
| mobile block rules (`.btn{width:100%}`) | `w-full sm:w-auto` on action buttons |
| `.data-table{min-width:640px}` / `560px` | `min-w-[640px]` + `overflow-x-auto` |
| `.is-hidden`, `.is-open`, `.is-visible`, `.is-active` | Tailwind `hidden` / daisyUI `drawer` / `menu-active` (update the owning JS) |
| `.narrow-content`, `.page-content` max-width | `max-w-3xl mx-auto` / `max-w-[1360px] mx-auto` |

### 8.2 Bucket 3 — genuinely custom CSS (must be written by hand)

Only these need a real stylesheet (a slim `custom.css`, loaded after the compiled daisyUI CSS):

1. **FullCalendar integration** (`css/calendar.css`, keep the file, rewrite the tokens):
   `--fc-classic-*` → daisyUI theme vars (`--color-primary`, `--color-base-100`, `--color-base-content`,
   `--color-error`, `--color-accent`, `--color-base-300`), plus `#calendar { min-height: 640px }` (lower it
   on mobile) and `#calendar .fc-event { cursor: pointer }`.
2. **Custom daisyUI theme block** — `@plugin "daisyui/theme"` with the palette in §7.1 (OKLCH/hex) and the
   radius tokens. Configuration, not component CSS.
3. **Auth brand panel art** (`auth-brand` gradient + `repeating-linear-gradient` pattern + accent blob via
   `::before`/`::after`). No counterpart; either keep as custom CSS or reduce to a solid `bg-primary` hero.
4. **Body ambient background** (two radial gradients + blurred blobs) — optional decorative cust; keep only
   if the visual identity is worth the paint cost.
5. **Entry animations** `fadeLift` and `slideIn` (page-content stagger). Recompose as `@keyframes` +
   `@utility`/`animate-*`, or drop.
6. **`white-space: pre-wrap`** on `description-box p` and `timeline-item p` → `whitespace-pre-wrap`
   (utility, listed for completeness because the content is user-authored with newlines).
7. **Safari/`backdrop-filter` fallbacks** for the frosted panels (if the glass look is kept).
8. **Data island `.reservas-data { display:none }`** → replace with the `hidden` attribute and delete the
   rule.
9. **Responsive table `min-width`** values, only if they differ from the utilities in §8.1.
10. **`html{scroll-behavior:smooth}` / `body{overflow-x:hidden}`** — one-line base rules.

That is the whole hand-written surface: roughly one 150–250 line `custom.css` (mostly FullCalendar +
theme), versus ~1085 lines of legacy CSS today.

---

## 9. Test & verification keynotes

- **Markup is not asserted.** `src/test/.../integration/controller/web/*` (4 test classes) use
  `view().name(...)`, `model().attribute(...)`, `redirectedUrl(...)` and `status()`. No `content().string`
  or class assertions anywhere in the 22 test files. A presentation-only rewrite is therefore safe **iff**
  view names, model attribute keys, redirect targets and form action URLs are unchanged.
- Keep the suite green after every phase: `docker compose run --rm test`.
- AGENTS.md requires E2E coverage for functionality changes; add a light per-role smoke check (login →
  dashboard → list → detail) asserting a stable rendered marker (`drawer-side`, `table`, `badge`) so a
  future refactor cannot silently drop the new UI.
- If Option B (committed CSS) is chosen, add a CI guard that rebuilds and fails on diff.
- No visual-regression tooling exists. If wanted, add Playwright screenshots in a separate, optional task —
  it is not required by the challenge.
- Manual acceptance checklist per archetype: 360px / 768px / 1280px widths, keyboard-only nav
  (drawer, modal, focus rings), `prefers-reduced-motion`, and a dark theme pass if enabled.

---

## 10. Suggested migration order

| Phase | Work | Files | Risk |
|---|---|---|---|
| 0 | Wire the Tailwind+daisyUI build (Option A), convert **login only**, prove `docker compose up --build` offline | `package.json`, `app.css`, Dockerfile, `login.jsp`, `head.jspf` | Medium (build) |
| 1 | Rewrite the shared shell: theme tokens, `head`, `topbar`, `sidebar` → `drawer`/`menu`/`navbar`, `alerts`, `scripts`; delete `layout.css`/`base.css` | 6 fragments + `custom.css` + `layout.js` | **High** (all 26 screens at once) |
| 2 | Shared primitives + new fragments: field, table+pagination, empty-state, badges, comment timeline | fragments + `components.css` deletion + `tables.js`/`forms.js` hook migration | Medium |
| 3 | Screens by archetype: B dashboards → D/C admin cadastros & lists → E/F/G detail pages → H/I forms | ~20 JSPs | Medium |
| 4 | Reservas agenda: restyle FullCalendar tokens, `join`/`tabs` toolbar, detail panel → `modal` optional | `reservas-agenda.jspf`, `calendar.css`, `calendar.js` | Medium |
| 5 | Cleanup: delete `responsive.css`, dead classes; add status badge mapping; normalize confirms; accents decision; update `CONTEXT.md`; run full suite | all CSS/JS | Low |

Rationale: the shell has the largest blast radius but the smallest file count — do it early, behind the
login spike, and verify with per-role smoke checks. The calendar goes last because it is the only piece with
third-party CSS and bespoke JS.

---

## 11. Risks and open questions

**Risks**

1. Adding npm to a Maven/Docker build can break the graded `docker compose up` if offline — mitigate with a
   build stage + cached `node_modules`, or fall back to Option B.
2. Deleting the legacy CSS in the same commit that adds daisyUI hides which rule caused a visual regression —
   delete per phase, not all at once.
3. `btn-secondary`, `.divider`, `.timeline`, `.card` semantic collisions (§4.3) are the most likely silent
   breakages.
4. Dynamic class extraction (§4.2) — status colors are exactly the feature that tempts string
   interpolation.
5. `forms.js` `parentElement`/`closest(".password-field")` and `tables.js` `.is-hidden` break if the markup
   changes without updating the JS in the same commit.
6. `calendar.js` depends on pt-BR status literals and on `.reserva-*` classes/ids.
7. FullCalendar's own CSS may win specificity against daisyUI surface tokens; the token bridge in
   `calendar.css` is the supported path, not `!important`.

**Open questions for the product owner**

1. Keep the serif headings and the frosted/glass visual identity, or move to a flat daisyUI look?
2. Dark mode now (theme-controller) or light-only?
3. Fix the missing pt-BR accents in copy as part of the rewrite?
4. Replace `window.confirm` with a daisyUI `modal`, or keep the native dialog for cost reasons?
5. Mobile tables: keep horizontal scroll, or collapse rows into cards (bigger effort)?
6. Semantic colors per status: reserva/área/usuário (fixed enums) yes — but chamado statuses are
   admin-configurable, so they stay neutral unless a color column is added to the model (out of scope for a
   UI rewrite).

---

## 12. Verification of this map

- **Read in full:** all 26 JSP pages and 8 fragments; `base/layout/components/calendar/responsive.css`;
  all 6 project JS files; `head/sidebar/topbar/alerts/scripts/csrf` fragments; root + JSP + static
  `CONTEXT.md`; `AGENTS.md`, `STANDARDS.md`, `ESPECIFICACAO.md`, `pom.xml`, `application.properties`,
  `Dockerfile`, `docker-compose.yml`, `SecurityConfig`, `WebControllerSupport`,
  `WebModelAttributeAdvice`; controller route mappings (web + api); test assertion sweep (22 test files).
- **Extracted:** `Desafio_seleção.pdf` → 11 pages of requirements, roles, RN/RF/CA and scope.
- **Cross-checked:** daisyUI 5.7.x component list and install/config rules against
  <https://daisyui.com/llms.txt> and <https://daisyui.com/docs/install/>.
- **Machine-checked:** CSS-class usage-vs-definition diff over `src/main/webapp` vs
  `src/main/resources/static/css` (found the unstyled `section-subtitle`, `helper-text`, `status-row`).
