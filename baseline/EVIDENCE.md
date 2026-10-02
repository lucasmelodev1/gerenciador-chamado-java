# Evidence log — P0…P3 (S1…S9)

Executed steps of [UI-REWRITE-PLAN.md](../UI-REWRITE-PLAN.md) §3. Every gate below was run and its
output captured. Deviations from the plan text and findings discovered during execution are recorded
per step; they are the reason some plan details were corrected.

Environment: Docker 29.7.2 / Compose v5.5.0, host JDK 25 (project targets 21 → **all gates in Docker**),
Node 26.3.0 / npm 12.2.0, `npm` cache relocated to `./.npm-cache` (host `~/.npm` is read-only).

---

## S1 — Baseline capture — **GATE PASS**

`bash scripts/ui-baseline.sh` (idempotent).

| Artifact | Value |
|---|---|
| `git-head.txt` | `c857a1b444a9e4292b009f40657f408e05471a16` |
| `assets.sha256` | **45** files (34 templates + 5 CSS + 6 JS) |
| `test-suite.log` | **`Tests run: 154, Failures: 0, Errors: 0, Skipped: 0`** + `BUILD SUCCESS` |
| `coverage.txt` | `LINE_COVERED=173 LINE_MISSED=1 LINE_RATIO=0.9943` (gate 0.40) |
| `war-contents.txt` | 480 entries, 11 under `static/css/` |
| `toolchain.txt` | host JDK 25, node 26.3.0, npm 12.2.0 |

**Deviations**
1. The plan's step 5 (`./mvnw -DskipTests clean package` on the host) was dropped: the host has no JDK 21
   and the plan itself declares Docker authoritative. The WAR payload is instead extracted from the built
   image (`docker compose run --rm --no-deps --entrypoint jar app tf /app/app.war`).
2. The suite runs `mvn verify` (not `mvn test`), so the same run also exercises `jacoco-check` and the
   coverage ratio is captured from `target/site/jacoco/jacoco.csv`.

**State note:** HEAD moved to `c857a1b` ("docs: atualizacao especificacao sobre timestamp") between
planning and execution; the snapshot uses the current commit, which is correct.

---

## S2 — Fixture + 26-route matrix — **GATE PASS**

`bash scripts/ui-seed.sh` → idempotent (second run: all `skip`), then
`bash scripts/ui-routes.sh baseline` → **26/26 routes HTTP 200 with the expected baseline marker**, for the
three roles. Fixture: 1 bloco / 6 unidades / 1 área / 1 tipo / 3 usuários / 1 chamado / 1 comentário /
2 reservas (**1 Aprovado + 1 Solicitado**, deliberately, to exercise CA-01-02).

### Findings that changed the plan

1. **The JSON API is not usable for seeding.** `/api/auth/**` is permitted in `SecurityConfig` but has no
   controller, and `JwtAuthenticationFilter` only *reads* the `jwt` cookie — nothing in the codebase ever
   writes it. Seeding therefore uses the web form flow (session + CSRF), as the plan suspected. This also
   means the "front-end consumes the JSON API" alternative is not viable today.
2. **The CSRF token is BREACH-masked and cannot be read from the cookie.** `XorCsrfTokenRequestAttributeHandler`
   renders a masked token in the form; replaying the raw `XSRF-TOKEN` cookie value returns **403**. Proven
   directly: masked token → `302`, raw cookie value → `403`.
3. **Authentication clears the `XSRF-TOKEN` cookie** (`CsrfAuthenticationStrategy`), and the cookie repo is
   deferred, so immediately after login the jar contains only `JSESSIONID`. Consequence: every POST must
   re-read `_csrf` from a freshly rendered form of that session
   (`/admin/usuarios`, `/morador/chamados/novo`). A first version using the cookie value failed with 403.
4. **Reservation status is stored as the enum `valor`** (`Solicitado`, `Aprovado`), not the enum name
   (`SOLICITADO`). The first seed silently skipped the approval; corrected.
5. **Marker corrections (data-dependent branches).** Three markers only render when data exists:
   `timeline` is absent without comments → the fixture now creates a comment; `empty-state` is absent on
   `/morador/reservas/disponibilidade` once there are rows → marker changed to `inline-panel`. Detail pages
   now use the always-present `timeline`/`description-box` pattern.
6. **ID resolution uses `psql`, not list-page HTML scraping.** The plan suggested extracting UUIDs from
   list links; reading them from the DB is deterministic and the UI rendering of those links is already
   asserted by the matrix itself. Documented deviation.
7. **Reference data pre-seeded by Flyway:** 3 status (`Solicitado` = inicial padrão, `Finalizado`,
   `Atrasado`); 0 blocos/áreas/tipos. Role tables are separate from `usuarios`
   (`administradores`, `colaboradores`, `moradores`); links live in `morador_unidade` and
   `colaborador_tipo_chamado`.

### Fixture contract (`baseline/fixture.txt`)

```
blocos=1  unidades=6  areas=1  tipos_chamado=1  usuarios=3  chamados=1
reservas=2  reservas_aprovadas=1  reservas_pendentes=1
```

---

## S3 — Invariant guard — **GATE PASS**

`bash scripts/ui-invariants.sh snapshot` then `check`.

| Run | Result |
|---|---|
| clean tree | `INVARIANTS OK` — exit **0** |
| injected drift (`data-confirm` → `data-xconfirm` in `admin/usuarios/detalhe.jsp`) | `FAIL confirmations = 9 (< 12)`, `FAIL data-confirm = 4 (< 7)`, exit **1** |
| restored | `INVARIANTS OK` — exit **0** |

Frozen: 26 view names, 36 form action URLs, `_method`=26, CSRF includes=36, multipart=5, confirmations≥12,
UTF-8 decls=2, JaCoCo config (16 include lines, minimum 0.40), 27 `data-*` hooks, 12 calendar selectors,
plus "no changes under `src/main/java`, `src/main/resources/db`, `pom.xml`".

Deliberately **not** frozen: `data-sidebar*` (removed by S7), the `data-confirm`/inline-`onsubmit` split
(normalised by S13), and legacy presentation classes.

**Deviations / findings**
1. Script bug found and fixed during execution: calendar selectors contain `=`, so `IFS='='` parsing broke.
   Collectors now emit TSV and look keys up exactly with `awk`.
2. The plan's negative control targeted `admin/areas/lista.jsp`, which uses inline `onsubmit`, not
   `data-confirm` — the control would have silently passed. Corrected to `admin/usuarios/detalhe.jsp`
   and the plan was updated.
3. `jacoco_includes` counts **16** `<include>` lines (8 classes × 2 executions: report + check), not 8.

---

## S4 — Tailwind 4 + daisyUI 5 bundle — **GATE PASS**

Installed `tailwindcss@4.3.3`, `@tailwindcss/cli@4.3.3`, `daisyui@5.7.47`. `npm run build:css` → 140 ms.

### Finding: automatic content detection is a real hazard here (bundle 251 KB → 48 KB)

With the default `@import "tailwindcss"` (automatic detection), the scanner treats **every non-ignored
file in the repo** as content. Measured consequences:

| Class | Present in JSPs | Present in `*.md` | Emitted by the 1st build |
|---|---|---|---|
| `navbar`, `drawer-side`, `join`, `rating`, `swap`, `radial-progress` | 0 | 1–2 docs | **yes** |
| `menu` | only inside `aria-label="Abrir menu"` / `"Fechar menu"` | — | **yes** (whole component) |

Switching to `@import "tailwindcss" source(none)` + explicit `@source` directives:

| | raw | gzip | selectors |
|---|---|---|---|
| automatic detection | 250,926 B | 28,562 B | 1,897 |
| **explicit sources** | **48,311 B** | **8,021 B** | — |

Legacy CSS for comparison: 20,398 B raw. Gate checks passed: daisyUI classes actually referenced by the
JSPs are emitted (`.btn`, `.card`, `.alert`, `.timeline`, `.divider`, `.table`); doc-only components are
gone; legacy-only classes (`status-pill`, `data-table`, `stat-card`) are absent.

**Correction applied to the plan:** the `@source` path was off by one directory
(`../../../../webapp` → `../../../webapp`); fixed in the plan and in `app.css`.

---

## S5 — Theme + component gallery — **GATE PASS**

`src/main/resources/static/css/app.css` now defines the custom daisyUI theme `chamados`
(`themes: false` + `@plugin "daisyui/theme"`), mapping the legacy `base.css` `:root` palette:

`--color-primary:#0d5c63`, `--color-accent:#dba24a`, `--color-success:#167c5b`, `--color-error:#b64134`,
`--color-neutral:#5f6c80`, `--color-base-200:#f3efe7`, `--radius-box:1.5rem` — all verified present in the
compiled bundle. Theme is wired via `data-theme=chamados` and
`:root:has(input.theme-controller[value=chamados])`.

`src/main/resources/static/ui-preview.html` is the component gallery (drawer/navbar/menu, buttons, badges,
alerts, stats, table + `join` pagination, forms + `validator` + `file-input`, timeline, agenda toolbar +
tabs, steps, modal, toast, tooltip, breadcrumbs, and the three composition-only patterns). It is also the
explicit safelist, being declared in `@source`. All 20 checked components are emitted.

| | raw | gzip |
|---|---|---|
| S4 (JSPs only) | 48,311 B | 8,021 B |
| S5 (+ gallery safelist) | **130,767 B** | **19,143 B** |

**Decision:** dark mode deferred (only the light `chamados` theme is enabled), so no `theme-controller` is
wired into the shell. Pill buttons vs single `--radius-field` was resolved as `--radius-field: 0.875rem`
(the project's 14 px inputs); pill-shaped buttons can come back via `@utility btn`.

---

## S6 — Maven/Docker integration — **GATE PASS** (Option A chosen)

`Dockerfile` gained `STAGE 0 : FRONTEND` (`node:22-alpine`, `npm ci`, `npm run build:css`), with the `src`
tree mirrored under `/ui` so the relative `@source` paths resolve identically to local dev. The Maven build
stage overlays the generated bundle before `mvn package`. `.dockerignore` added (node_modules, .git,
baseline, target). `app.build.css` is **not versioned** — it is a generated artifact (added to `.gitignore`).

| Check | Result |
|---|---|
| `docker compose build app` (incl. npm stage) | success |
| WAR payload | `WEB-INF/classes/static/css/app.build.css` + `static/ui-preview.html` present |
| `GET /css/app.build.css` unauthenticated | **200**, 130,767 B, **byte-identical to the local build** |
| `GET /ui-preview.html` unauthenticated | **302 → /login** |
| `GET /ui-preview.html` with admin session | **200**, 21,552 B, `data-theme="chamados"`, 234 `class=` attributes |
| `scripts/ui-routes.sh baseline` after image swap | **26/26** green |

---

## Cross-cutting status after P0+P1

- **No source file under `src/main/java`, `src/main/resources/db`, or `pom.xml` was modified** — enforced by
  `ui-invariants.sh` (exit 0) and re-checked here.
- The 26 screens are still rendered by the **legacy CSS**: nothing links `app.build.css` from a JSP yet.
  That is S7's job, and it is why the baseline matrix remains valid.
- Test suite: 154 tests, 0 failures; line coverage 99.43% (gate 40%).

---

# P2 — Shell (S7, S8)

## S7 — Shell rewrite (drawer + navbar + menu) — **GATE PASS**

Fragments rewritten to daisyUI: `sidebar.jspf` (drawer + `menu`), `topbar.jspf` (`navbar`), `alerts.jspf`
(`alert` + `role="alert"`), `head.jspf` (loads the bundle), `scripts.jspf` (no `layout.js`).
`js/layout.js` deleted; nav highlighting moved server-side.

| Check | Result |
|---|---|
| `ui-routes.sh shell` | **26/26** (`drawer-side` on the 25 shell pages) |
| `ui-routes.sh baseline` | **26/26** — unfinished pages' content untouched |
| active nav, per page | **exactly 1** active link on all 25 shell pages, semantically correct (login: none) |
| `drawer-side` / `navbar` / `menu menu-lg` / `menu-active` / `aria-current` | 25/25 pages each |
| old hooks `data-sidebar*` | 0 files |
| `layout.js` | not referenced by any `<script>`; `GET /js/layout.js` → **404** |
| invariants | `INVARIANTS OK` (exit 0) |
| suite | `BUILD SUCCESS`, coverage 0.9943 |

### Plan correction — deletion timing was wrong (sequencing flaw)

S7 was specified to delete `base.css` + `layout.css`. That would have broken every screen not yet rewritten:

- `base.css` owns the `:root` tokens referenced **48×** by `layout.css` (5), `components.css` (24) and
  `calendar.css` (19);
- their content classes are used by **9–26 JSPs each** (`two-column-grid` 9, `table-wrap`/`data-table` 16,
  `status-pill` 15, `empty-state` 21, `card`/`btn` 24, `alert` 26).

**Revised:** the four legacy stylesheets stay loaded **after** `app.build.css`, so unfinished screens are
unchanged and daisyUI wins only on names the legacy CSS does not define. Deletion moves to **S10**
(`components.css`) and **S17** (base/layout/responsive). The hybrid is verified by both marker sets passing.

### Plan correction — the drawer wrapper is a 25-file change

`drawer` requires `input.drawer-toggle` + `.drawer-side` + `.drawer-content` as children, and that wrapper
lives in the pages, not the fragments. Mechanical two-token edit on the 25 shell pages:
`app-shell` → `drawer lg:drawer-open`, `app-main` → `drawer-content`. (`login.jsp` has no shell.)

### JSP/EL traps hit (both fail silently — no compile-time feedback)

1. **`pageContext.request.requestURI` returns the forward target** (`/WEB-INF/jsp/admin/blocos/lista.jsp`),
   not the request URL, because Spring forwards to the JSP. Every nav link failed to match and no item was
   ever active. Fix: `jakarta.servlet.forward.request_uri`, with `requestURI` only as fallback.
2. `fn:replace(path, ctx, '')` is wrong when the context path is empty (ROOT deployment, `ctx == ""`).
   Replaced with `fn:substringAfter` guarded by a non-empty context.

Both were found by instrumenting the rendered output (temporary `<!-- DBG ... -->` in the loop) — the only
reliable way to debug EL here.

### Tooling change

`ui-routes.sh` gained a third marker set: `baseline | shell | new`. `new` markers belong to P3–P6 and would
false-fail between S7 and S16; `shell` is what P2 gates on.

## S8 — Shell responsive + a11y — **GATE PASS**

| Check | Result |
|---|---|
| skip link rendered | **25/25** pages; target `#conteudo-principal` added to `<main>` in 25 JSPs |
| `aria-controls` on the drawer toggle label | present |
| `aria-label` on the `drawer-toggle` checkbox | present |
| `prefers-reduced-motion` | honoured in `custom.css` (entry animation, drawer transition, smooth scroll) |
| focus visibility | restored in `custom.css` (legacy sets `outline: none`; needs `!important` while legacy
  loads — block removed in S17) |
| responsive utilities compiled | `lg:drawer-open`, `lg:hidden`, `sm:flex`, plus `sr-only`/`focus:not-sr-only` |
| `ui-routes.sh shell` / `baseline` | **26/26** / **26/26** |
| invariants | `INVARIANTS OK` |

**Deviation:** the plan asked for `aria-expanded` on the toggle. Deliberately omitted: daisyUI's drawer is
CSS-only (no JS state to expose), and an `aria-expanded` on a `<label>` with no JS would be a false
assertion. The visually-hidden checkbox already conveys state to assistive tech via checked/unchecked.

**Still not verified:** anything that requires a real viewport or visual rendering (360/768/1280 px layout,
focus ring appearance, drawer animation, colour contrast of the daisyUI shell). No headless browser exists
in this environment; see Deferred below.

### Deferred / not produced

- **Screenshots at 360/768/1280 px** (planned artifacts for S5/S7/S8): no headless browser is available in
  this environment (`chromium`, `firefox`, Puppeteer and Playwright are all absent). All verification so far
  is DOM/CSS-level; visual regression still needs a browser.
- Dark mode, pill-button radius, and the pt-BR accent decision remain open (plan §11).

### Phase readiness after P2

P3 (S9 fragment extraction, S10 primitives) is unblocked. S9 must keep the render byte-identical, which also
gives the first strong visual-equivalence check available without a browser.

---

# P3 — Primitives (partial: S9 + identity)

Requested alongside P3: daisyUI typography, removal of the background gradient, and Inter titles / Noto Sans
body text.

## P3.1 — Global identity: fonts, flat background, daisyUI type scale — **DONE**

**Fonts.** Inter (variable, titles) and Noto Sans (text) vendored from the provided TTFs. Only the four
weights daisyUI actually uses ship — Regular 400, Medium 500, SemiBold 600, Bold 700; Thin/Light/ExtraBold/
Black were deliberately left out (they would add ~2.5 MB with no consumer in the daisyUI type scale). Total
payload **3.3 MB**, all TTF — no `fonttools`/`woff2` and no `pip` in this environment, so woff2 encoding was
not possible. Converting to woff2 (~10× smaller) is the obvious follow-up.

**Constraint discovered:** fonts had to live in `static/css/fonts/`, not `static/fonts/`. `SecurityConfig`
only exempts `/css/**`, `/js/**`, `/images/**`, `/webjars/**` from authentication, and adding `/fonts/**`
would be a **Java change**, which the invariant contract forbids. `/css/fonts/` is served by the permitted
`/css/**` prefix — verified: the TTFs return **200 without a session**, which the login page requires.

Wiring: `@font-face` + `@theme` tokens in `app.css` (`--font-display` Inter, `--font-sans` Noto Sans,
`--default-font-family`), plus the same stacks in the legacy `base.css` `:root` so that not-yet-rewritten
screens switch immediately (legacy loads last and owns `:root` during the transition). Shell fragments moved
from `font-serif` to `font-display`.

**Background.** The page gradient and the two blurred decorative blobs (`body::before/::after`) were removed
from `base.css` → flat `var(--bg)`. The `auth-brand` gradient, its diagonal pattern overlay and its accent
blob were flattened to `var(--primary-strong)`. Every remaining gradient on a surface was flattened to a
solid token (cards, cards' sheen `::before`, stat cards + accent bar, hero card, buttons, status pills,
`detail-list`, `description-box`, `list-row`, `empty-state`, input background, timeline rail) and the three
dead shell rules in `layout.css` too. **Gradients remaining in the source CSS: 0.**

**Typography.** Fluid `clamp()` sizes replaced with the Tailwind/daisyUI scale: headings
`clamp(1.5rem,3vw,2.1rem)` → `1.5rem/2rem font-semibold` (`text-2xl`), stat values
`clamp(2rem,4vw,2.8rem)` → `2.25rem/2.5rem font-bold` (`text-4xl`), table headers `0.86rem` → `0.75rem`
(`text-xs`), eyebrow `0.76rem` → `0.75rem`.

## P3.2 — S9 fragment extraction — **PASS for the extracted fragment**

Analysed the duplication before writing anything: the `empty-state` block appears **33 times across 21
files** in exactly **2 shapes** (17 compact with a single `<p>`, 16 with `<h3>` + `<p>`). That uniformity is
what makes a JSP fragment viable, so it was extracted into `fragments/vazio.jspf` (parameters
`vazioTitulo`, `vazioMensagem`, `vazioCompacto`, with `<c:remove>` so the optional vars do not leak between
blocks). **33/33 call sites replaced, 0 skipped.**

**Verification** — captured all 26 routes before and after, normalized (whitespace between tags, the
masked CSRF token which changes per render, and the intentional `font-serif`→`font-display` rename):

| Result | Value |
|---|---|
| routes compared | 26 |
| pages differing | **1** |
| empty-state blocks rendered before/after | 4 + 3 / 4 + 3 (identical) |
| shell markers / invariants / suite | 26/26 · `INVARIANTS OK` · 154 tests, 0 failures, coverage 0.9943 |

The single differing page is `admin-usuarios.html`, and the delta is **not** from this change: it is the
`<option>` order of the user-type select, which comes from `AdminWebController.tiposUsuario()` returning
`Map.of(...)`. `Map.of` has **unspecified iteration order**, so the role dropdown renders in a different order
after each JVM restart. Recorded as a pre-existing inconsistency; the fix (`LinkedHashMap`) is a Java change
and therefore outside this rewrite's contract.

**Coverage limitation (honest):** the fixture only renders **7** of the 33 empty-state blocks (the rest are
in no-data branches that the fixture never reaches). Those 7 match exactly; the remaining 26 share the same
two shapes but are not exercised by the current fixture.

## P3.3 — Not done (remaining P3 work, with reasons)

- **S9 remainder:** `paginacao` (12 sites), `comentarios` (3), `tabela` (16), `form-field` (18),
  `lista-filtros`, `detalhe-grid`. Reviewing them changed the plan's assumption: in JSP, a fragment is
  parameterized by `<c:set>` + `<%@ include %>` and has no slot/attribute mechanism, so a fragment only pays
  off when its parameter surface is **smaller** than the markup it replaces. `form-field` and `detalhe-grid`
  carry per-instance labels, names, types and values, so parameterizing them costs more than the duplication
  they remove — they are better served by a JSP custom tag (`.tag` file), which is a larger change. The
  worthwhile candidates are the chrome-like ones with few parameters.
- **S10 (primitive restyle + `components.css` removal):** cannot ship before S11–S15. Legacy CSS still loads
  *after* the bundle, so a restyle of `.card`/`.btn`/`.table`/`.field` is invisible until the corresponding
  legacy rules are deleted — and those rules are still consumed by every not-yet-converted screen
  (`components.css` has 16–26 JSP consumers per class). This is the same sequencing constraint found in S7;
  `components.css` deletion therefore belongs with the screen conversions and S17, not S10.

### Phase readiness after P3

S11 (auth + dashboards) is the natural next step: it starts retiring `components.css` page by page, which is
what makes the daisyUI primitives visible. A headless browser remains the main gap — every verification so
far is DOM/CSS-level.

---

# P4 — Primitives converted globally (partial)

P4 as planned (S11–S15, page by page) was blocked by the constraint found in P3: `components.css` loads
*after* the bundle, so a restyle is invisible until its legacy rules go — and those rules are shared by all
20 content screens. Converting screens one at a time would have produced no visible change for four steps.
Instead the **shared primitives were converted globally**, and the legacy blocks they replace were deleted.

## What changed

Markup, across all JSPs (scripted, uniform patterns):

| Primitive | Legacy | Now | Sites |
|---|---|---|---|
| Table | `data-table` / `table-wrap` / `compact-table` | `table table-zebra` / `overflow-x-auto` / `table-sm` | 17 + 17 + 1 |
| Local filter | `table-search` | `input input-sm` | 4 |
| Buttons | `btn btn-secondary`, `btn-danger`, `ghost-button` | `btn`, `btn-error`, `btn btn-ghost` | 60 + 6 + 3 |
| Text/number/date/e-mail/password inputs | *(no class)* | `input w-full` | 33 |
| File inputs | *(no class)* | `file-input` | 5 |
| Selects / textareas | *(no class)* | `select w-full` / `textarea w-full` | 24 + 4 |
| Status pill | `status-pill` (single teal, no per-status colour) | `badge` + semantic colour | 16 |

CSS deleted (blocks whose selectors were replaced): **19 rule blocks** from `components.css` and 2 rules from
`responsive.css`. `components.css`: **386 → 238 lines (−38%)**.

The two `'btn-secondary'` ternaries in the agenda view toggle were replaced by the daisyUI default button —
this is the semantic trap from UI-REWRITE-MAP.md §4.3 (legacy `btn-secondary` = white; daisyUI =
brand `#5f6c80`), which would otherwise have silently turned the inactive tab grey-blue.

## Verification

| Check | Result |
|---|---|
| `ui-routes.sh shell` | **26/26** |
| legacy primitives rendered (`status-pill`, `data-table`, `table-wrap`, `ghost-button`, `btn-secondary`, `btn-danger`, `table-search`) | **0 pages** |
| new primitives rendered | table 15, badge 25, input 16, select 15, textarea 4, file-input 4, btn 26 pages |
| distinction by status (CA-01-02) | `/admin/reservas` renders **`badge-success` ×1 + `badge-warning` ×1** — previously both were identical pills |
| invariants | `INVARIANTS OK` |
| suite | 154 tests, 0 failures, coverage 0.9943 |

## Still legacy (next chunk of P4)

`card` (25 JSPs), `section-header` (24), `field` label (19), `list-row` (8), `detail-list` (3),
`description-box` (3), `divider` (3), `alert` (2). These are the structural conversions that were
deliberately **not** scripted here because they change nesting rather than class names:

- daisyUI's `card` has no padding of its own — it needs a `card-body` wrapper around the children, so
  converting 57 cards means rewriting element nesting, not swapping a class.
- `field` → `fieldset`/`fieldset-legend` changes the label structure, and `forms.js` reads
  `field.parentElement` for the character counter and `closest('.password-field')` for the password toggle,
  so the JS must move in the same commit.

Both are mechanical but nesting-aware, and without a browser there is no way to check the result visually —
which is why they are the next step rather than a rushed one.

---

# P4.1 — Button/alert colours: cascade-layer bug

**Reported:** buttons in "Início" render white with white text; in "Agenda", dark green with black text.

**Root cause — CSS cascade layers, not custom CSS.** daisyUI's output is emitted inside `@layer daisyui`;
Tailwind's preflight sits in `@layer base`. `base.css` carried the *same* resets **unlayered**:

```css
a { color: inherit; text-decoration: none; }        /* unlayered */
button, input, select, textarea { font: inherit; }  /* unlayered */
```

Unlayered styles beat **every** layered style, regardless of specificity or source order. So that legacy
`a { color: inherit }` overrode daisyUI's `.btn { color: var(--btn-fg) }`, and every *anchor* button
inherited its ancestor's colour — white inside `.stat-card-wide` (white text on a light button = invisible),
dark inside a dark surface. It also overrode daisyUI's button/input font sizes, which is the "diverts from
daisyUI defaults" symptom.

**Fix:** the two duplicated resets were deleted from `base.css`. Tailwind's preflight already provides both,
inside `@layer base`, so nothing is lost and daisyUI's own values now apply. The legacy `.alert`,
`.alert-success`, `.alert-danger` and `.alert-close` blocks were removed for the same reason (daisyUI owns
`alert`), and `auth/login.jsp` — which still hardcoded `alert-danger`/`alert-close` — was switched to
`alert alert-error` + `btn btn-sm btn-ghost`.

| Check | Result |
|---|---|
| unlayered resets that hijack daisyUI (`a {`, `button, {`) | **0** |
| preflight still supplies both resets (layered) | yes |
| legacy button/alert classes in rendered HTML | **0 pages** |
| `/login?error=true` | renders `alert alert-error` + `btn btn-sm btn-ghost` |
| `/login?logout=true` | renders `alert alert-success` |
| `ui-routes.sh shell` / invariants | **26/26** · `INVARIANTS OK` |

**Not verifiable here:** the actual rendered colours — no browser. The cause was removed and the cascade
verified structurally; the visual result needs a human/browser check.

**Systematic consequence for the rest of P4:** *every* remaining unlayered legacy rule whose selector matches
the same element as a daisyUI component still wins. Only `button { cursor: pointer }` remains among
element-level rules, but class-level ones do (`.card`, `.section-header`, `.divider`, `.field span`,
`.list-row`, `.detail-list`, `.description-box`, `.empty-state`). The clean end state is to wrap the legacy
stylesheets in a cascade layer declared *before* Tailwind's, which makes daisyUI always win; that is only
safe once `.card` carries a `card-body`, otherwise daisyUI's padding-less `.card` takes over.

---

# P5 — S16 Agenda (calendar) — **GATE PASS**

`fragments/reservas-agenda.jspf` toolbar converted to daisyUI: period navigation as `join`
(`btn join-item`, with the period label as a `btn-disabled join-item`), month/week switch as
`tabs tabs-box` with `tab-active` resolved **server-side** (same pattern as the sidebar nav).
The area filter had already received `select w-full` in P4.

`calendar.css`: the `--fc-classic-*` tokens now point at daisyUI theme variables with the legacy tokens as
fallbacks (`var(--color-primary, var(--primary))`), and the two rules the new toolbar replaced
(`.calendar-toolbar`, `.calendar-view-toggle`) were deleted.

| Check | Result |
|---|---|
| both agendas | `join` ×1, `role="tablist"` ×1, `tab-active` ×1 |
| active tab | default → **Mes**; `?view=semana` → **Semana** (verified against the live app) |
| `calendar.js` contract intact | `#calendar`, `#reservas-data`, `.reserva-data`, `#reserva-detalhe`, `.reserva-titulo|meta|motivo`, `#form-aprovar|negar|cancelar`, `#filtro-area`, `#reserva-fechar` — all present |
| `ui-routes.sh shell` / invariants | 26/26 · `INVARIANTS OK` |

**Not done:** the detail panel was left as a `hidden` `<section>` rather than converted to a `<dialog
class="modal">`. `calendar.js` toggles it via `.hidden` and rewrites the three form `action`s, so a modal
conversion has to move that JS in the same commit — not worth doing blind without a browser.

---

# P6 — S17 Cleanup + S18 Acceptance — **GATE PASS**

## S17 — cleanup

| Item | Result |
|---|---|
| confirmations unified on `data-confirm` | **12 `data-confirm`, 0 inline `onsubmit`** (5 files normalised; total conserved, so the invariant still passes) |
| dead CSS removed (shell-era classes no longer referenced) | **20 rule blocks** — 13 from `layout.css` (`.app-shell`, `.sidebar*`, `.nav-link*`, `.brand-*`, `.topbar-*`), 3 from `components.css` (`.profile-chip`, `.mobile-nav-button`), 4 from `responsive.css` |
| calendar rules replaced by the new toolbar | 3 blocks |
| `CONTEXT.md` updated | `src/main/webapp/WEB-INF/jsp/`, `src/main/resources/static/` (shell, fragments, JS contract, CSS build, fonts) |

Residual, intentionally kept: a few stale selectors sit **inside** still-live shared rules (e.g.
`.profile-chip span` is part of the muted-colour group with `.eyebrow`/`.list-row`/`.field-hint`).
Whole-block dead-code detection correctly refuses to split those.

## S18 — final acceptance, from a cold start

`docker compose down -v` (volume dropped) → `docker compose up --build -d`.

| # | Check | Result |
|---|---|---|
| 1 | cold start | app ready in **8 s** |
| 2 | fixture rebuilt from an **empty** DB | 3 usuários · 1 chamado · 2 reservas (1 Aprovado + 1 Solicitado) — the seed is idempotent *and* correct from scratch |
| 3 | 26-route matrix (all 3 roles) | **26/26** |
| 4 | invariant guard | `INVARIANTS OK` |
| 5 | suite + coverage gate | **153 tests, 0 failures, `BUILD SUCCESS`**, coverage **0.9942** (gate 0.40) |
| 6 | scope proof | **0 files** changed under `src/main/java`, `src/main/resources/db`, `pom.xml` vs the S1 baseline commit |
| 7 | legacy primitives in rendered HTML | **0 pages** for `status-pill`, `data-table`, `table-wrap`, `ghost-button`, `btn-secondary`, `btn-danger`, `alert-danger`, `alert-close` |
| 8 | daisyUI primitives in rendered HTML | table 16 · badge 30 · input 17 · select 18 · file-input 7 · join 2 · tabs 2 pages |
| 9 | CA-01-02 visible | `/admin/reservas` → `badge-success` ×1 + `badge-warning` ×1 |

**Final shape:** 36 templates (34 + `vazio.jspf`, `reserva-status.jspf`), 5 vendored fonts,
bundle 133,365 B, legacy CSS **1085 → 608 lines (−44 %)**.

# P7 — S19 Sidebar `dashboard-01` (shadcn) — **GATE PASS**

Escopo pedido: implementar a **lateral** do bloco `dashboard-01` do shadcn usando componentes da daisyUI,
**sem alterar o CSS da daisyUI** — só layout, tipografia e uso de cor. Ícones Tabler/Lucide, cantos
arredondados e o **cartão do usuário dentro da lateral**.

Referência lida: `https://ui.shadcn.com/r/styles/new-york-v4/dashboard-01.json` (`app-sidebar.tsx`,
`nav-main.tsx`, `nav-user.tsx`, `site-header.tsx`). O bloco é React/TSX sobre Base UI e **não é portável**;
foi reaproveitado o *layout*, não o código.

## O que mudou

| Arquivo | Mudança |
|---|---|
| `fragments/sidebar.jspf` | 3 slots do `dashboard-01`: cabeçalho (marca + ícone), conteúdo (grupos com rótulo + itens com ícone) e rodapé com o **cartão do usuário** (`avatar` + `dropdown` com o logout). Variante *inset* (`p-2 lg:p-3` + painel `rounded-box`). Nav reorganizada em grupos (`navGroups`) |
| `fragments/topbar.jspf` | `SiteHeader`: linha única com `border-b`, gatilho, separador e título da tela. Perfil e logout **saíram** daqui (sem duplicar identidade) |
| `fragments/icone.jspf` | **novo** — 20 ícones Tabler outline 3.31.0 como markup (`<c:choose>`); sem bundler, o pacote npm não é consumível no JSP |
| `fragments/head.jspf` | materializa `${_csrf.token}` no `<head>` (ver regressão abaixo) |
| `css/custom.css` | painel *inset* do `drawer-content`; topbar de linha única; `.app-sidebar .menu` (geometria) |
| `scripts/ui-shell.sh` | **novo** — verificador do shell sobre o HTML renderizado + checagem de fonte do CSRF |

**CSS da daisyUI: intocado.** Componentes usados: `drawer`, `menu`, `avatar avatar-placeholder`, `dropdown
dropdown-top`, `badge`, `navbar`, `btn`. Os únicos ajustes de geometria são dois, escopados em `.app-sidebar`
e fora de cascade layer — necessário porque `@layer daisyui` vem **depois** de `@layer utilities`
(offsets 8.172 vs 8.155), então `.menu{width:fit-content;padding:.5rem}` não cede a utilitário do Tailwind.

## Regressão encontrada e corrigida — CSRF × buffer de 8 KB

Os ícones inline inflaram o começo do `<body>` e empurraram o form que contém o `_csrf` para depois do
buffer de resposta do Tomcat. O `CookieCsrfTokenRepository` só escreve `XSRF-TOKEN` quando o token é
resolvido; com a resposta já comprometida o `Set-Cookie` se perde, a sessão fica sem token e **todo POST
autenticado passa a responder 403** — inclusive o logout.

| Build | Offset do form `_csrf` em `GET /admin` | `Set-Cookie: XSRF-TOKEN` | `POST /logout` |
|---|---|---|---|
| HEAD/S18 (topbar) | 8.179 B | emitido **por 13 B de margem** | 302 → `/login?logout=true` |
| S19 (ícones inline) | 18.635 B | **perdido** | **403** |
| S19 + correção no `head.jspf` | 18.646 B | emitido | 302 → `/login?logout=true` |

Confirmado por comparação direta: `git stash` → rebuild → o mesmo fluxo passa no HEAD e falhava no S19.
A causa raiz é estrutural (qualquer página grande quebrava os POSTs, e o HEAD estava a 13 B do limite);
por isso a correção é resolver o token no início da resposta, e não encolher a página.

## Verificação (a partir do artefato final)

| # | Check | Result |
|---|---|---|
| 1 | matriz de rotas, 3 perfis | **26/26** |
| 2 | `scripts/ui-shell.sh` | **25/25** páginas autenticadas — estrutura, 20 ícones, grupos, item ativo, cartão do usuário |
| 3 | self-test negativo do verificador | **7/7 sabotagens detectadas** (avatar, ícone, ativo, grupo, ícone de fallback, logout na topbar, título) |
| 4 | CSRF/logout ao vivo, 3 perfis | `XSRF-TOKEN` emitido · `/logout` → **302** · sessão encerrada **sim** (form a 18.646 B) |
| 5 | suíte + gate de cobertura | **153 testes, 0 falhas, `BUILD SUCCESS`** |
| 6 | `scripts/ui-invariants.sh check` | `INVARIANTS OK` (inclui `no changes under src/main/java, src/main/resources/db, pom.xml`) |
| 7 | bundle CSS | 133.365 → **139.804 B** (+6.439: `avatar`, `dropdown`, `menu-title`, utilitários) |
| 8 | item ativo correto | prefixo mais longo, exatamente **1** `menu-active` + 1 `aria-current` por página |

## Custos e limites

- **Peso por página (ícones inline):** `/admin` 11.763 → **26.263 B**, `/morador` 18.870 B,
  `/colaborador/chamados` 14.815 B. Com gzip o acréscimo cai bastante. Um sprite SVG externo reduziria
  isso, mas `<use href="arquivo.svg#id">` não é verificável aqui (sem navegador) — ficou inline.
- **Ícones: 20 declarados, 20 em uso** (15 na navegação + `marca`, `menu`, `opcoes`, `perfil`, `sair`).
  `icone.jspf` tem um `<c:otherwise>` que emite um círculo neutro, para que um alias desconhecido não quebre
  o build do JSP; `ui-shell.sh` falha se ele aparecer.
- **Sem navegador:** cantos, sombras, espaçamento, `avatar` circular da daisyUI (o do shadcn é quadrado
  arredondado — mantido o padrão da daisyUI) e o menu do cartão do usuário seguem **sem verificação visual**.

# P7.1 — S20 Raios menores e espaçamento mais justo — **GATE PASS**

Pedido: "gaps menores e menos raio de borda em geral". Aplicado no tema, no shell e — obrigatoriamente —
também no CSS legado.

## Por que o legado precisou ser tocado

O legado não está em cascade layer, então ele **vence** a daisyUI onde define a mesma propriedade. Mexer só
nos tokens do tema deixaria `stat-card`, `list-row`, `description-box`, `empty-state` e o `auth-panel` com os
raios antigos — e, abaixo de 640 px, `responsive.css` força `.card` para o raio dele, ignorando o tema.
Os dois lados foram ajustados para o raio ser consistente.

## Raios

| Alvo | Antes | Depois |
|---|---|---|
| `--radius-box` (tema) | 1.5rem / 24px | **1rem / 16px** |
| `--radius-field` (tema) | 0.875rem / 14px | **0.625rem / 10px** |
| `--radius-selector` (tema) | 0.75rem / 12px | **0.5rem / 8px** |
| `--radius-lg` / `-md` / `-sm` (legado) | 24 / 18 / 12px | **16 / 12 / 8px** |
| `.stat-card` | 24px | 16px |
| `.detail-list div` | 16px | 10px |
| `.description-box`, `.list-row`, `.empty-state` | 18 / 18 / 20px | **12px** |
| `.auth-panel` (login) | 32px | 20px |
| `.card` em `≤640px` (legado) | 20px | 14px |

## Espaçamento

| Alvo | Antes | Depois |
|---|---|---|
| `.drawer-side` (inset da lateral) | `p-2 lg:p-3` | **`p-1.5 lg:p-2`** |
| painel do conteúdo (`drawer-content`) | margem 12px | **8px** |
| topbar: `min-height` / `padding` / `top` sticky | 3.5rem / .5rem 1rem / 12px | **3.25rem / .375rem .75rem / 8px** |
| grupos da navegação | `gap-3`, `px-2 pb-2` | **`gap-1.5`, `px-1.5 pb-1.5`** |
| itens dentro do grupo | `gap-1` | **`gap-0.5`** |
| cabeçalho e rodapé da lateral | `p-2` | **`p-1.5`** |
| `.page-content` | `padding 24px 32px 40px`, `gap 24px` | **`18px 24px 28px`, `gap 16px`** |
| respiro interno dos cards (`--card-p`) | 1.5rem / 24px | **1.25rem / 20px** |

## Verificação

| # | Check | Result |
|---|---|---|
| 1 | tokens no bundle | `--radius-box:1rem`, `--radius-field:.625rem`, `--radius-selector:.5rem` |
| 2 | utilitários emitidos | `p-1.5`, `px-1.5`, `pb-1.5`, `gap-1.5`, `gap-0.5`, `lg:p-2` |
| 3 | matriz de rotas | **26/26** |
| 4 | `scripts/ui-shell.sh` | **SHELL OK** (25 páginas + checagens de fonte) |
| 5 | `scripts/ui-invariants.sh check` | `INVARIANTS OK` |
| 6 | CSRF/logout ao vivo, 3 perfis | cookie `XSRF-TOKEN` emitido · `/logout` **302** · sessão encerrada |
| 7 | escopo de backend | nenhuma mudança em `src/main/java`, `db/`, `pom.xml` |

O shell verificado (`ui-shell.sh`) foi atualizado junto: ele fixa a string de classes do `.drawer-side`.

# P7.2 — S21 Lateral sobre o fundo + fundo cinza-neutro — **GATE PASS**

Pedido: a lateral deve ficar **sobre o fundo da página**, não como ilha; e o fundo mais cinza-branco, menos
amarelo.

## Lateral sem superfície própria

Removido do `<aside>`: `bg-base-100`, `border border-base-300`, `rounded-box`, `shadow-sm` e `overflow-hidden`
(este último não fazia mais sentido sem os cantos arredondados e ainda podia cortar o menu do cartão do
usuário). Ficou `bg-base-200 lg:bg-transparent`.

**A exceção do mobile é necessária, não estética:** abaixo de `lg` o `.drawer-overlay` pinta `oklch(0% 0 0/.4)`
sobre a página; uma lateral transparente ali deixaria o texto da navegação sobre o fundo escurecido. Por isso
ela é opaca abaixo de `lg` e transparente a partir de `lg`.

**Efeito colateral tratado:** os hovers do cabeçalho (marca) e do cartão do usuário usavam `bg-base-200` —
exatamente a cor do fundo em que a lateral agora vive, ou seja, ficariam invisíveis. Trocados por
`bg-base-content/10`, a mesma mistura que a própria daisyUI usa no hover dos itens de `menu`.

O conteúdo (`drawer-content`) continua sendo a superfície arredondada; o contraste com a lateral plana é o que
dá a separação agora que a borda saiu.

## Fundo cinza-neutro

| Token | Antes | Depois |
|---|---|---|
| `--bg` (`base.css`, fundo real do `body`) | `#f3efe7` | **`#f3f4f6`** |
| `--color-base-200` (tema) | `#f3efe7` | **`#f3f4f6`** |
| `--color-base-300` (bordas) | `#e4ded2` | **`#e5e7eb`** |

`base-300` entrou junto porque é a cor da borda e do filete da topbar: mantê-la quente ao lado de um fundo
frio deixaria a moldura amarelada. Os acentos (`--primary #0d5c63`, `--accent #dba24a`) não foram tocados.

## Verificação

| # | Check | Result |
|---|---|---|
| 1 | tokens no bundle | `--color-base-200:#f3f4f6`, `--color-base-300:#e5e7eb`, `--color-base-100:#fff` |
| 2 | utilitários emitidos | `bg-base-200`, `lg:bg-transparent`, `hover:bg-base-content/10`, `focus-visible:bg-base-content/10` |
| 3 | guard novo em `ui-shell.sh` | falha se o `<aside>` voltar a ter `bg-base-100`/`border`/`rounded-box`/`shadow-sm` ou perder `lg:bg-transparent` — **4/4 sabotagens detectadas** |
| 4 | matriz de rotas | **26/26** |
| 5 | `scripts/ui-shell.sh` | **SHELL OK** |
| 6 | `scripts/ui-invariants.sh check` | `INVARIANTS OK` |
| 7 | CSRF/logout ao vivo, 3 perfis | cookie `XSRF-TOKEN` emitido · `/logout` **302** · sessão encerrada |
| 8 | escopo de backend | nenhuma mudança em `src/main/java`, `db/`, `pom.xml` |

# P8 — S23 Drawer lateral (substitui o modal) — **GATE PASS**

Dois problemas relatados sobre o componente da S22: as bordas horizontais da tela não escureciam como o
meio, e o componente deveria ser um **drawer**, não um `<dialog>`.

## Problema 1 — as bordas claras: causa e correção

Não era o `::backdrop`: a daisyUI aplica **`display: none`** nele e pinta o escurecimento no próprio
elemento `.modal` (`background-color: oklch(0% 0 0/.4)`). O componente estava renderizado **dentro de
`.page-content`**, e o legado tem:

```css
.page-content > * { width: min(100%, 1360px); margin-inline: auto; }
```

Como o legado não está em cascade layer, ele **vence** o `width: 100%` da daisyUI. Acima de 1360 px o
elemento escurecido ficava com 1360 px e centralizado — exatamente as bordas claras relatadas. O
`animation: fadeLift ... both` da mesma regra ainda deixava um `transform` no elemento.

**Correção estrutural:** o componente passa a ser renderizado **fora de `.page-content`**, como filho
direto do `<body>`, e o backdrop virou um elemento próprio (`position: fixed; inset: 0`) em vez de depender
do `.modal`. `ui-drawer.sh` agora **falha** se o drawer ou o backdrop aparecerem antes de `</main>`.

## Problema 2 — de `<dialog>` para drawer

Trocado por dois elementos irmãos — backdrop e `<aside>` — animados por `translate`. Sem `<dialog>`, o
comportamento que ele daria de graça passou a ser explícito no JS: Esc, foco preso no painel, devolução do
foco e trava de scroll.

| Antes (S22) | Depois (S23) |
|---|---|
| `<dialog class="modal">` centrado | `<aside class="app-drawer app-drawer--sm app-drawer--end">` deslizando da direita |
| escurecimento pelo `.modal`, espremido pelo legado | `<div class="app-drawer-backdrop">` irmão, `position: fixed; inset: 0` |
| fechar por `method="dialog"` + `.modal-backdrop` | `data-drawer-fechar`, clique no backdrop e Esc, no JS |
| foco/scroll nativos | `role="dialog"` + `aria-modal`, focus trap, trava de scroll |
| `ui:modal`, `modal.js`, `AppModal`, `modal:fechado` | `ui:drawer`, `drawer.js`, `AppDrawer`, `drawer:fechado` |
| `.app-modal` (larguras) | `.app-drawer*` (topo, corpo com scroll, rodapé, tamanhos, lados) |

As três faixas continuam iguais: topo (título + descrição + X), slot livre no meio
(`<jsp:doBody/>`, agora a única região com scroll) e rodapé (Salvar + Fechar). O `<form>` segue no meio, com
o Salvar no rodapé ligado por `form="<id>-form"`, e o `_csrf` continua dentro do componente. Novos atributos:
`lado` (`end`/`start`) além de `tamanho` (`sm` padrão/estreito, `md`, `lg`).

## Verificação — `bash scripts/ui-drawer.sh`

| # | Check | Result |
|---|---|---|
| 1 | contrato do markup nos **dois** estados | OK — topo, slot, rodapé, X, backdrop, `_csrf`, e **nenhum `<dialog>`** na página |
| 2 | **posição** | drawer e backdrop renderizados **depois de `</main>`** (fora de `.page-content`) |
| 3 | escopo | `ui:drawer` usado **só** em `admin/areas/lista.jsp`; `modal.tag`/`modal.js` não existem mais |
| 4 | fluxo criar → editar → remover pelo form do drawer | `302` nos três, banco conferido a cada passo (remoção é *soft delete*, `deleted_at`) |
| 5 | resíduo | removido ao fim; a fixture volta a ter só "Piscina" |
| 6 | **comportamento do JS executado** | `node scripts/ui-drawer-js.mjs` → **13/13**, self-test negativo **6/6** |
| 7 | matriz de rotas | **26/26** |
| 8 | `scripts/ui-shell.sh` | `SHELL OK` |
| 9 | `scripts/ui-invariants.sh check` | `INVARIANTS OK` |
| 10 | suíte | **153 testes, 0 falhas, `BUILD SUCCESS`** |
| 11 | escopo de backend | nenhuma mudança em `src/main/java`, `db/`, `pom.xml` |

O caso 6 cobre o que a S22 não cobria: o JS agora é **executado** num DOM mínimo em Node (não há navegador
aqui), incluindo clique no backdrop, Esc, focus trap, trava de scroll e abertura server-side. Continua sem
cobrir o que depende do motor do navegador — a animação do `translate` e o layout real das faixas.

## Revisão S23.1 — rodapé enxuto e os dois bugs relatados

### Rodapé só com Salvar

Saiu o botão "Fechar": fechar é o X do topo, o Esc e o clique fora. O botão que sobra passou a se
chamar **"Salvar"** (sem "Cadastrar area"/"Salvar area") e ganhou o ícone Tabler `device-floppy`.
Sem `acao` (drawer informativo) o rodapé nem é renderizado.

### Bug 1 — salvar não fechava o drawer

**Causa:** `AreaApiController.atualizarArea` termina em `redirect:/admin/areas?areaId=" + areaId`, e a
view tratava `?areaId=` como "abra o drawer em modo edição". Salvar reabria o próprio drawer.

**Correção:** a view deixou de usar o estado de edição do servidor. O drawer é **sempre renderizado
fechado e no modo de criação**; quem preenche e abre é o gatilho de edição, no cliente. Depois de
salvar, a página recarrega com o drawer fechado, independentemente de para onde o servidor redirecione.
**Nenhuma linha de Java foi alterada** — a correção foi possível justamente por tirar o `?areaId=` do
caminho de renderização.

### Bug 2 — dois cliques para criar

**Causa:** em modo edição o botão "Nova area" era um link para a URL limpa. O reload removia o
`areaId`, mas o drawer só abria quando havia estado de edição — então ele voltava fechado e só um
segundo clique (já no modo de criação) o abria.

**Correção:** "Nova area" virou gatilho de cliente (`data-drawer-abrir`), igual ao "Editar". Os dois
operam sobre o mesmo drawer: `data-drawer-abrir` devolve o formulário ao estado renderizado
(`action` original + `reset()`), `data-drawer-editar` aplica os `data-campo-*` do gatilho. Não há mais
reload para abrir.

### Conteúdo dinâmico

O `_method` virou um campo comum: o componente renderiza `<input type="hidden" name="_method" value="">`
e o gatilho de edição o preenche via `data-campo-_method="patch"`. Vazio = POST (o
`HiddenHttpMethodFilter` ignora parâmetro sem valor).

### Verificação desta revisão

| # | Check | Result |
|---|---|---|
| 1 | rodapé com **1** botão, chamado Salvar, com `<svg`, sem `data-drawer-fechar` | OK |
| 2 | drawer **nunca** vem com `data-drawer-aberto` no HTML | OK |
| 3 | **depois de salvar**: o destino do `Location` do PATCH é buscado e conferido — vem sem `data-drawer-aberto` | OK (bug 1 travado por teste) |
| 4 | self-test negativo do markup: 4/4 sabotagens (Fechar de volta, ícone removido, rótulo trocado, `data-drawer-aberto` no HTML) | OK |
| 5 | comportamento do JS: **16/16 casos**, incluindo editar preenche, novo reseta e novo abre em um clique | OK |
| 6 | matriz de rotas · `ui-shell.sh` · `ui-invariants.sh` · suíte | 26/26 · OK · `INVARIANTS OK` · **153 testes, 0 falhas** |

O caso 3 é o mais importante: ele **executa** o fluxo salvar→redirect→render e falha se o drawer voltar
aberto, em vez de confiar na leitura do código.

**Snapshot de invariantes renovado** de novo: os hooks `data-modal*` saíram de `FROZEN_HOOKS` e entraram
`data-drawer`, `data-drawer-abrir`, `data-drawer-fechar`, `data-drawer-aberto` e `data-drawer-backdrop`.

## S24 — Cabeçalho de tabela e faixa de filtros (tela de areas)

### O que mudou

A tela de areas deixou de usar a composição legada `.section-header` + `.toolbar-inline`, em que busca e
ação dividiam a linha do título, com `align-items: flex-start` e `gap: 16px`. Agora:

- **cabeçalho** (`.app-card-head`) — uma linha com descrição e título **colados** (bloco de `gap: 2px`, contra
  os 8px de `margin-bottom` do `.eyebrow`) à esquerda e o botão "Nova area" à direita (`space-between`);
- **filete** — `border-bottom: 1px solid var(--color-base-300)` na base do cabeçalho, separando-o dos filtros;
- **faixa de filtros** (`.app-card-filtros`) — um container flexível abaixo do filete, hoje com um único filtro:
  a busca, com `placeholder="Pesquisar..."` e a lupa Tabler `search` **dentro da moldura, à esquerda do texto**.

### Por que classes novas em vez de reaproveitar `.section-header`

Três razões, todas verificadas no cascade real:

1. `.section-header`/`.toolbar-inline` são legado **sem cascade layer** e carregam *depois* de `custom.css`,
   então venceriam qualquer regra nova de mesma especificidade;
2. `responsive.css` força `flex-direction: column` nelas abaixo de 900px — contra o alinhamento em linha pedido;
3. nelas a busca pertence à linha do título, e aqui ela pertence aos filtros.

Com classes novas nenhuma regra precisa de `!important`. O custo é que o `<h2>` deixa de casar com
`.section-header h2`, e o preflight do Tailwind zera o tamanho do título: por isso `.app-card-head h2` repõe
`font-size: 1.5rem` + `var(--font-display)`. `ui-tabelas.sh` (entao `ui-areas.sh`) falha se essa regra desaparecer.

### A lupa dentro do campo, sem posicionamento absoluto

O `.input` da daisyUI é `display: inline-flex; align-items: center; gap: .5rem` e já zera o `input` interno
(`background: transparent; border: none; width: 100%`). Ou seja: basta um `<label class="input input-sm">`
com o `<svg>` **antes** do `<input>` e o ícone fica dentro da moldura, alinhado à esquerda — sem
`position: absolute`, sem wrapper extra e sem utilitário novo no bundle. O ícone é `size-4 shrink-0 opacity-60`.

### Risco real da mudança

O `tables.js` descobre o campo com `document.querySelectorAll("[data-filter-input]")`. Envolver a busca num
`<label>` muda a posição dela na árvore, então era esse o ponto a provar — não o CSS. `ui-tables-js.mjs`
executa o `tables.js` de verdade sobre o cenário novo: **11/11 casos**, incluindo descoberta dentro do
`label`, filtro *case-insensitive* com `trim`, `data-filter-target` roteando entre duas tabelas e o casamento
por qualquer célula da linha.

### Verificação

| # | Check | Result |
|---|---|---|
| 1 | markup renderizado: cabeçalho com 1 botão, sem `<input>`/`<svg>` dentro; descrição e título juntos e nessa ordem | OK |
| 2 | faixa de filtros **depois** do cabeçalho; busca é `label.input` com a lupa **antes** do campo; `placeholder="Pesquisar..."` | OK |
| 3 | `.toolbar-inline`, `.section-header` e `Filtrar localmente` não aparecem mais na tela | OK |
| 4 | CSS: `flex-direction: row` + `space-between` + filete + `gap: 2px`; `.app-card-head h2` repõe a tipografia. Self-test negativo: **4/4** | OK |
| 5 | bundle: `.input{display:inline-flex}`, `.input input{...}`, `.input-sm`, `.size-4`, `.shrink-0`, `.opacity-60` presentes | OK |
| 6 | self-test negativo (markup): **8/8** — placeholder antigo, lupa ausente, lupa **depois** do campo, busca movida para o cabeçalho, `data-filter-input` e `data-filter-target` removidos, `.app-card-filtros` e `.app-card-head__texto` renomeados | OK |
| 7 | comportamento: **11/11 casos**; self-test negativo do harness 3/3 | OK |
| 8 | filtro **local**: `listarAreas` sem parâmetro de busca e `tables.js` sem `fetch`/`XHR`/`URLSearchParams`/`location.` | OK |
| 9 | matriz de rotas · `ui-shell.sh` · `ui-drawer.sh` · `ui-invariants.sh` · suíte | 26/26 · OK · OK · `INVARIANTS OK` · **153 testes, 0 falhas** |

Os self-tests de 4 e 6 não são um passo manual à parte: são a segunda metade da seção A e B de
`ui-areas.sh`, rodando sobre o **próprio HTML/CSS real** a cada execução. Cada sabotagem também confere que
alterou o arquivo — foi o que pegou, durante o desenvolvimento, duas sabotagens escritas com `sed` que nunca
casavam e por isso "passavam" sem medir nada.

Nenhuma linha de Java, migration ou `pom.xml` foi alterada (o `ui-invariants.sh` confere isso por `git diff`
contra o commit-base). `app.build.css` saiu **idêntico** do `npm run build:css`: a mudança não introduziu
utilitário novo, só reusou o que já estava no bundle — que é justamente o que o check 5 passa a travar.

## S25 — Coluna de acoes: encostada na direita, so icone + tooltip

### O que mudou

Na tabela de areas, a ultima coluna virou um **cluster de acoes encostado na borda direita** da tabela:

- **encostada de verdade.** A daisyUI da `padding-inline: 1rem` a toda `th/td`
  (`.table :where(th,td)`) e a daisyUI nao distingue a ultima coluna. `.app-tabela-acoes` zera esse
  padding na celula de acoes e alinha o conteudo com `justify-content: flex-end` — sem isso a acao
  ficava flutuando no meio de uma coluna mais larga que o conteudo.
- **so icone.** "Editar" e "Remover" perderam o texto: `btn btn-ghost btn-sm btn-square`, com o icone
  Tabler em `size-4` — o mesmo tamanho dos icones da lateral. Sao o lapis (`pencil`) e a lixeira (`trash`),
  dois aliases novos em `icone.jspf`.
- **tooltip.** `tooltip` + `data-tip="Editar"` / `data-tip="Remover"`, mais `aria-label` no botao e
  `<span class="sr-only">Acoes</span>` no `<th>`: o rotulo saiu da tela, nao da arvore de acessibilidade.

### Os dois detalhes que so apareceram medindo

**O balao nao pode ser centralizado.** O `tooltip` da daisyUI centraliza o balao sobre o elemento
(`left: 50%` + `translateX(-50%)`). Com a acao encostada na borda direita, metade do balao cairia fora da
tabela — e o `<div class="overflow-x-auto">` em volta, que por ter `overflow-x: auto` tambem vira container
de rolagem no eixo Y, **cortaria** o balao (alem de poder criar barra de rolagem horizontal no hover).
A correcao alinha o balao pela direita do botao e deixa a seta centrada no botao, nao no balao.

**O hover do `btn-ghost` some na linha zebrada.** `.btn:hover` pinta `--btn-bg: var(--color-base-200)` — que e
exatamente o `background-color` que a `.table-zebra` aplica nas linhas pares. A coluna de acoes ganhou um
hover proprio (`color-mix(base-content 10%)`), visivel nas duas cores de linha.

### Status como badge

A coluna Status deixou de ser texto puro: `badge-success` para `Ativo`, `badge-neutral` para `Inativo`
(`<span class="badge ...">` dentro da celula). O conjunto e fechado — a migration V19 declara
`status TEXT NOT NULL CHECK (status IN ('Ativo', 'Inativo'))` — entao o mapeamento pode ser literal no JSP,
que e o mesmo raciocinio (e a mesma exigencia do Tailwind) documentada em `fragments/reserva-status.jspf`.
Nao virou fragmento porque o status de area aparece em uma unica tela; o de reserva aparece em varias.

O texto continua sendo o `valor` ("Ativo"), nao o nome do enum, entao nada muda no que o usuario le — so a
forma. E como o badge fica **dentro** da celula, o `tables.js` continua casando pelo texto: o filtro local
segue encontrando a linha por "Ativo"/"Inativo".

### Uma suposicao errada que a instrumentacao pegou

A primeira versao deste passo **nao** usou `btn-square`: eu havia concluido, lendo os offsets do bundle, que o
`.btn-square{padding-inline:0}` (em `daisyui.l1.l2`) perdia para o `.btn{padding-inline:var(--btn-p)}` (em
`daisyui.l1.l2.l3`), por sub-layer vencer o layer pai, e que o icone transbordaria. Estava **invertido**.

A regra, no CSS Cascade 5, e o contrario para declaracoes normais: *"non-nested styles in a layer have
precedence over normal nested styles"* — **o layer pai vence o filho**. O `.btn-square`, portanto, funciona
normalmente (mora no layer pai do `.btn`), e o botao de icone ficou com ele. O que essa regra explica de
verdade e por que `btn-ghost btn-error` nao serve: `.btn:hover{color:var(--btn-fg)}` vive em `daisyui.l1`, layer
pai de onde mora o `.btn-ghost`, e o `--btn-fg` do `btn-error` e quase branco — no hover o icone sumiria sobre o
fundo transparente. Dai a classe propria `.app-btn-perigo`, fora de layer.

Licao registrada no proprio `custom.css`: ler a ordem dos layers no bundle **nao** basta; a direcao da
precedencia entre layer e sub-layer precisa ser confirmada na especificacao.

### O guard tambem passou a contar so markup

A deriva acima expos um defeito do proprio `ui-invariants.sh`: os coletores fazem `grep`
sobre **todo** o `src/main/webapp`, e os `CONTEXT.md` moram la dentro. Escrever
`name="_method"` ou um `data-*` na documentacao movia o floor — e como a S26 fez os
`CONTEXT.md` citarem o markup que os tags emitem, isso virou uma mina: encurtar um
comentario derrubava `data-drawer-editar` de 4 para 3 e reprovava o guard.

Correcao: `MARKUP=(--include='*.jsp' --include='*.jspf' --include='*.tag')`, aplicada aos
sete `grep` que varrem o webapp. O guard passou a medir exatamente o que ele diz medir.

Isso baixou alguns floors, todos por ocorrencia apenas em documentacao:

| Item | Antes | Depois | O que saiu |
|---|---|---|---|
| `method_inputs` | 24 | 23 | mencao em `tags/CONTEXT.md` |
| `csrf_includes` | 32 | 31 | idem |
| `data-filter-input` / `-target` | 4 | 3 | mencoes em `jsp/CONTEXT.md` |
| `data-drawer` | 26 | 18 | mencoes em 3 `CONTEXT.md` |
| `data-drawer-abrir` | 9 | 6 | idem |
| `data-drawer-editar` | 4 | 1 | idem (sobra a do `ui:acao-editar` que **emite** o hook) |
| `data-drawer-titulo` | 3 | 2 | idem |
| `reserva-data` / `reserva-titulo` | 2 | 1 | mencoes em `jsp/CONTEXT.md` |

Depois disso os floors voltaram a ser o **markup real**: qualquer hook removido de um JSP ou
de um tag volta a reprovar. Verificado item a item: cada linha que baixou tem a ocorrencia
removida identificada como texto, nao como codigo.

### Verificacao

| # | Check | Result |
|---|---|---|
| 1 | markup: toda celula `.cell-actions` tambem tem `.app-tabela-acoes` (comparacao de contagens, para o caso de so uma linha regredir) | OK |
| 2 | 2 botoes por linha, ambos `btn-square` + `tooltip`, com `data-tip` e `aria-label`; o de excluir com `.app-btn-perigo` | OK |
| 3 | os icones sao o lapis e a lixeira do Tabler (nao o fallback) e os dois em `size-4` | OK |
| 4 | nenhum botao de acao com texto (`>` **so** pode vir `<svg>`) e `btn-link`/`btn-error` fora da tela | OK |
| 5 | CSS: `flex-end` + `padding-inline-end: 0` + `form{display:flex}` + hover próprio + balao à direita | OK |
| 6 | self-test negativo das secoes A e B: **17/17** e **9/9** (saiu de 8/8 e 4/4 em S24) | OK |
| 7 | o Status e badge em **todas** as linhas (contagem igual a das linhas) e cada valor com a sua cor | OK |
| 8 | `ui-drawer.sh` continua verde: o gatilho de editar mudou de classe, entao passou a ser validado por atributo | OK |
| 9 | matriz de rotas · `ui-shell.sh` · `ui-invariants.sh` · suíte | 26/26 · OK · `INVARIANTS OK` · **153 testes, 0 falhas** |

Os dois self-tests negativos foram, de novo, o que pegou defeito: a sabotagem "celula de acoes sem a classe"
**passou** na primeira tentativa, porque o `findall` so olhava as celulas que ainda tinham a classe e a
sabotagem mexia em uma das tres linhas. A checagem agora compara o total de `.cell-actions` com o total de
`.app-tabela-acoes`, e a sabotagem reprova.

## S26 — O padrao de areas virou framework, e foi para as outras telas de tabela

### O que foi extraido

Tudo o que a S24 e a S25 fizeram **dentro da tela de areas** virou componente em
`WEB-INF/tags`, para as telas de tabela pararem de repetir a mesma moldura:

| Tag | Substitui |
|---|---|
| `ui:card-head` | `.app-card-head` + `.app-card-head__texto` + `.eyebrow` + `<h2>` + o filete |
| `ui:busca` | o `label.input` + o include do icone `pesquisar` + `data-filter-input`/`data-filter-target` |
| `ui:badge` | o `<span class="badge badge-X">` repetido a mao |
| `ui:acao-link` | o `<a class="btn btn-ghost btn-sm btn-square tooltip">` + icone + `data-tip` + `aria-label` |
| `ui:acao-editar` | o botao de editar + os `data-campo-*` + o `data-campo-_method` |
| `ui:acao-form` | o `<form>` + `csrf.jspf` + `_method` + o botao de icone (remover/desativar/padrao) |

O contrato, o esqueleto de uma tela nova e os atributos de cada tag estao em
`src/main/webapp/WEB-INF/tags/CONTEXT.md`. O estilo continua onde estava (`custom.css`),
porque nao mudou: o que mudou foi quem escreve o markup.

O resultado no tamanho das telas: areas foi de 152 para 119 linhas, usuarios de 119 para 137
(ganhou drawer de edicao e tres acoes), blocos de 106 para 106 (perdeu o formulario lateral e
ganhou drawer, cabecalho e filtros), status-chamado de 113 para 125 (virou tabela).

### Onde foi aplicado

| Tela | Criar/editar | Filtros | Acoes de linha | Status |
|---|---|---|---|---|
| areas | drawer (ja tinha) | busca local | editar, remover | badge success/neutral |
| blocos | **drawer** (era formulario lateral) | busca local | ver unidades | — |
| chamados | **nao tem** (so leitura) | `GET` na faixa | detalhar | badge ghost |
| status-chamado | **drawer** (era form inline + `?statusId=`) | busca local | editar, tornar padrao | badge Inicial/Disponivel/Reservado |
| usuarios | **drawer para criar e editar** (editar era pagina de detalhe) | busca local | editar, gerenciar, desativar | badge neutral |

Duas consequencias estruturais:

- **blocos e usuarios perderam a grade de duas colunas.** O cartao de criacao da esquerda virou
  o drawer; a listagem passou a ocupar o cartao inteiro, como areas. E o preco de ter o mesmo
  desenho nas cinco telas.
- **status-chamado deixou de ser `stack-list` de `.list-row`** e virou tabela. Sem a tabela nao
  haveria onde encaixar a coluna de acoes compartilhada; os tres status reservados ganharam o
  badge `Reservado` no lugar do antigo botao desabilitado (um `.btn:disabled` tem
  `pointer-events: none`, entao nem tooltip teria).

### Duas capacidades novas no drawer

**Campos do gatilho como inputs escondidos.** O formato antigo
(`data-campo-<name>="<valor>"` no proprio botao) nao sobrevive a um tag: o nome do atributo
teria de ser montado por variavel, e qualquer codificacao em string quebra com dado de usuario
— um nome com `;` ou `|` corromperia a lista. Agora o corpo do `ui:acao-editar` recebe
`<input type="hidden" data-campo="nome" value="...">`, que passa pelo escape normal do HTML e
aceita quantos campos forem. O `drawer.js` le as duas formas (a nova vence), entao o formato da
S23 continua valido.

**`travar="tipo"`.** Campos que a edicao nao pode mudar mas a criacao pode. O componente
renderiza um espelho escondido com o mesmo `name`, ja `disabled`; o JS desabilita o controle
visivel e habilita o espelho ao editar, e desfaz ao criar — necessario porque campo `disabled`
nao e enviado. Uso hoje: o **perfil do usuario**, que o `PATCH` deriva do papel persistido e o
servico recusa trocar (`Nao e permitido alterar o tipo do usuario`). O gatilho manda a CHAVE do
tipo (`usuario.tipo` e o rotulo; a chave sai de `fn:substringAfter(usuario.role, 'ROLE_')`).

Alem disso, o gatilho de edicao passou a **passar pelo estado inicial antes de aplicar**. Sem
isso, campo que o gatilho nao declara vazaria de uma edicao para a seguinte — a `senha`, que o
PATCH exige em toda edicao, era o caso concreto.

### O bug que a tela pegou e o verificador nao

A primeira versao do `badge.tag` escrevia, **dentro do comentario JSP do arquivo**, um exemplo
com a marca de comentario JSP aninhada. Comentario JSP nao aninha: o fechamento de dentro
fechou o de fora, e todo o resto do comentario virou **texto da pagina** — o comentario inteiro
apareceu impresso dentro do badge, repetido em cada linha da tabela. Foi o usuario que viu, nao
o `ui-tabelas.sh`: as checagens procuravam `<span class="badge badge-X">Texto</span>`, que
continuava casando (o texto vazado ficava **fora** do span).

Correcao: o comentario nao contem mais nenhuma marca literal, e a secao A passou a reprovar
qualquer `<%--`, `--%>`, `<%@` ou `${` que chegue ao HTML renderizado. A sabotagem
"marcador de comentario JSP vazando para o HTML" exercita exatamente isso.

Vale registrar o segundo tropeco: ao **documentar** o cuidado, a primeira reescrita do
comentario voltou a colocar as marcas literais dentro dele e reintroduziu o mesmo bug. O
comentario agora descreve o risco sem escreve-lo.

### Deriva do snapshot de invariantes, revisada linha a linha

O `ui-invariants.sh` reprovou por tres motivos, todos esperados: consolidar formularios em tags
muda a contagem de literais que o guard congelava.

| Item | Antes | Depois | Por que |
|---|---|---|---|
| `action-urls` | 36 entradas | 31 | 7 acoes viraram o atributo `acao=` de um tag (nao mais `action="..."`); `${acao}` foi de 1 para 2 (drawer + `ui:acao-form`) |
| `method_inputs` | 26 | 24 | areas −2, status-chamado −2, usuarios −1 saem; `ui:acao-form` +1 e `drawer.tag` +1 entram |
| `csrf_includes` | 37 | 32 | areas −1, blocos −1, status-chamado −2, usuarios −2 saem; `ui:acao-form` +1 entra |
| `confirmations` | 12 | **13** | subiu |
| `utf8_decls` | 3 | **9** | subiu |

A conta fecha arquivo por arquivo e **nenhuma linha sumiu sem substituto**: cada `action`,
`_method` e `csrf.jspf` que saiu de uma tela reapareceu dentro de `ui:acao-form` (uma vez) ou ja
existia em `ui:drawer`. O resto dos floors nao se moveu. Snapshot renovado com essa revisao
registrada.

**Achado colateral:** o guard faz `grep` sobre **todo** o `src/main/webapp`, incluindo `.md`.
Escrever `name="_method"` num `CONTEXT.md` conta como se fosse codigo (foi o que aconteceu com
`WEB-INF/tags/CONTEXT.md`, +1 no floor). Fica anotado nas limitacoes.

### Verificacao

| # | Check | Result |
|---|---|---|
| 1 | `ui-tabelas.sh` secao A: contrato comum das 5 telas + o que e de cada uma | OK |
| 2 | self-test negativo do markup: **10/10** sabotagens (inclui o vazamento de marcador JSP) | OK |
| 3 | self-test negativo do CSS: **10/10** | OK |
| 4 | `drawer.js` executado: **21/21** casos (campos nos dois formatos, campo travado, sem heranca entre edicoes) | OK |
| 5 | `tables.js` executado: **11/11** casos; self-test 3/3 | OK |
| 6 | `ui-drawer.sh`: markup, posicao, fluxo criar→editar→remover e o escopo das 4 telas | OK |
| 7 | `ui-routes.sh shell` · `ui-shell.sh` | 26/26 · `SHELL OK` |
| 8 | `ui-invariants.sh check` (com o snapshot renovado) | `INVARIANTS OK` |
| 9 | `docker compose run --rm test` | **153 testes, 0 falhas** |

O fluxo real de criar→editar→remover continua exercitado ponta a ponta: `ui-drawer.sh` cria uma
area pelo formulario do drawer, faz o PATCH, segue o `Location` e confere que a pagina nao volta
com o drawer aberto, e remove (com limpeza do residuo).

### Fica para depois (nao pedido, nao feito)

1. **`admin/usuarios/detalhe.jsp` ainda tem o formulario de edicao** (nome/email/senha), agora
   duplicando o drawer da listagem. O detalhe continua sendo o lugar dos vinculos de morador e
   dos tipos do colaborador; unificar exigiria decidir se a edicao sai de la.
2. **A paginacao e repetida nas 5 telas** (e nas outras quatro) com o mesmo bloco
   Anterior/Pagina/Proxima. Um `ui:paginacao` com `pagina` + `params` extra resolveria, mas nao
   faz parte do que foi pedido aqui.
3. **Os `GET` com `?areaId=`, `?statusId=` e `?tipoId=` continuam nos controllers** e agora sao
   codigo morto: nenhuma tela aponta para eles. Sao `src/main/java`, congelado pelo guard.
4. **`tipos-chamado` saiu desta lista na S27** (era a mais parecida com `areas`). Continuam
   fora as telas de reservas, vinculos-morador e escopo-colaborador.
5. **O admin de chamados perdeu o subtitulo** "Os chamados mais antigos aparecem primeiro na
   lista.": o `ui:card-head` tem uma linha de descricao, que ficou com o eyebrow
   ("Monitoramento"). A frase tambem prometia uma ordenacao que a consulta nao garante.

## S27 — Tipos de chamado no mesmo padrao

Ultima tela de tabela do admin a sair do formato antigo. Ela era a mais parecida com `areas`
— cartao de criacao a esquerda, listagem a direita, edicao por `?tipoId=` — e virou a sexta
tela do padrao, com uma diferenca: **nao tem remocao**.

`TipoChamadoApiController` so expoe `POST` e `PATCH /{tipoId}`; nao existe `@DeleteMapping`.
Entao a coluna de acoes tem **uma** acao, `ui:acao-editar`, e a tabela perdeu o
"Editar" que era um link para a mesma tela com o parametro de query.

O que saiu:

| Antes | Depois |
|---|---|
| `c:set tipoChamadoAction` (POST ou PATCH conforme `?tipoId=`) | `acao="${ctx}/admin/tipos-chamado"` no drawer + `data-drawer-acao` por linha |
| `<form method="post">` no cartao esquerdo, com `csrf.jspf` e `_method=patch` condicional | `ui:drawer` (ja traz os dois) |
| `<input type="search" placeholder="Filtrar localmente" ...>` a mao | `ui:busca alvo="tipos-table"` |
| `<a href="...?tipoId=" class="btn btn-link">Editar</a>` | `ui:acao-editar` (icone + tooltip) |
| dois cartoes em `two-column-grid` | um cartao, como as outras cinco telas |

O `PATCH` continua devolvendo `?tipoId=<id>` para a listagem. O parametro nao e mais lido por
ninguem — o `GET` tambem aceita e preenche `tipoChamadoForm`, mas nenhuma tela aponta para ele
— entao salvar cai na lista com o drawer fechado, que e o comportamento das outras telas.
Mexer nisso e mexer em `src/main/java`, que o `ui-invariants.sh` congela.

### Verificacao

| # | Check | Result |
|---|---|---|
| 1 | `ui-tabelas.sh` cobre as **6** telas (a nova entra com alvo `tipos-table` e drawer `drawer-tipo`) | OK |
| 2 | check por tela: sem coluna de status, um gatilho de editar por linha, nenhuma acao de remocao, e o gatilho levando `titulo` e `prazoHoras` | OK |
| 3 | self-test negativo do markup: **11/11** (a nova sabotagem aponta o gatilho de tipos para outro drawer) | OK |
| 4 | secao D tambem trava `listarTiposChamado`: nenhum parametro de busca no servidor | OK |
| 5 | `ui-drawer.sh`: o escopo passou de 4 para **5** telas de cadastro | OK |
| 6 | `ui-routes.sh shell` · `ui-shell.sh` · `ui-tabelas.sh` · `ui-invariants.sh` | 26/26 · OK · OK · `INVARIANTS OK` |
| 7 | `docker compose run --rm test` | **153 testes, 0 falhas** |

### Deriva do snapshot, revisada

| Item | Antes | Depois | Por que |
|---|---|---|---|
| `action-urls` | 30 entradas | 29 | `-1 ${tipoChamadoAction}`: o form inline virou `acao=` do drawer. Nada mais mudou |
| `method_inputs` | 23 | 22 | o `_method=patch` condicional do form inline saiu |
| `csrf_includes` | 31 | 30 | o `csrf.jspf` do form inline saiu (o drawer ja tem o dele) |
| `data-filter-input` / `-target` | 3 | 2 | a busca a mao de `tipos-chamado` virou `ui:busca`; sobra a ocorrencia dentro do `busca.tag` |
| `data-drawer` | 18 | **19** | subiu: a tela nova acrescenta o drawer |
| `data-drawer-abrir` | 6 | **7** | subiu: idem |

A revisao de `action-urls` foi de uma linha so (`-1 ${tipoChamadoAction}`), o que confirma que
a migracao nao tocou nenhum formulario de outra tela. Como na S26, a queda e consolidacao —
o `_method` e o `csrf` da tela reapareceram dentro do `ui:drawer`.

## S28 — Decisao de reserva: tres acoes com icone e dialogo central

### O problema

Na lista de reservas as tres acoes de decisao eram links de texto ("Aprovar", "Negar",
"Cancelar") e o **motivo da negacao era um `<input class="input w-full">` dentro da propria
celula de acoes**. Como `w-full` dentro de uma celula de tabela nao tem largura para
resolver, o campo estourava a coluna e empurrava os botoes uns sobre os outros — foi o que
a captura de tela mostrou.

### O que ficou

Tres acoes so com icone, na mesma coluna `cell-actions app-tabela-acoes` das outras telas:

| Acao | Icone | Como decide |
|---|---|---|
| Aprovar | `aprovar` (check) | direto: `ui:acao-form` com `metodo="patch"` |
| Negar | `negar` (ban) | `ui:dialog` pedindo o **motivo**, com confirmar vermelho e "Voltar" esmaecido |
| Cancelar | `fechar` (X) | `ui:dialog` de confirmacao, **sem** motivo, tambem com confirmar vermelho |

O `data-confirm` nativo do cancelamento saiu: a confirmacao passou a ser o dialogo central,
que e o que o pedido descrevia. O `ui-tabelas.sh` reprova se `data-confirm` voltar a
aparecer nessa tela.

### O componente novo: `ui:dialog`

Um dialogo e um drawer centralizado — mesmo backdrop, mesmo Esc, mesmo foco preso, mesma
trava de scroll, mesmo conteudo dinamico. Entao **nao ha JS novo**: o `dialog.tag` emite o
mesmo protocolo `data-drawer*` e o `drawer.js` que ja existia cuida do resto. O que muda e
apenas a apresentacao (`.app-dialog`: `inset: 0` + `margin: auto`, com fade e escala no lugar
do `translate`) e o rodape, que confirma em vez de salvar.

Duplicar o comportamento num `dialog.js` separado seria duplicar os bugs: os 21 casos do
`ui-drawer-js.mjs` (foco preso, Esc, devolucao de foco, trava de scroll, campos do gatilho,
campo travado) cobrem o dialogo sem uma linha a mais de teste.

Centralizar com `margin: auto` e nao com `translate` e proposital: com `translate` um
conteudo mais alto que a viewport sairia da tela; com `inset: 0` + `margin: auto` quem manda
e o `max-height: calc(100dvh - 2rem)`, e o corpo rola.

**Um dialogo para cada decisao, nao um por linha.** O gatilho de cada linha
(`ui:acao-editar`, com `icone`/`rotulo`/`metodo` trocados) leva a acao daquela reserva por
`data-drawer-acao`; o `reporInicial` limpa o motivo digitado entre uma linha e outra — o que
so funciona porque a S26 fez o gatilho de edicao passar pelo estado inicial antes de aplicar.

### Mais uma vez o verificador pegou o verificador

A checagem nova "a celula de acoes nao pode conter campo de formulario" reprovou o markup
**correto**: o `ui:acao-form` emite `_csrf` e `_method` como inputs escondidos, e eles vivem
dentro da celula por natureza. O que nao pode ali e campo **visivel** — era o caso do motivo.
A checagem passou a olhar so `input` sem `type="hidden"`, `select` e `textarea`.

### Correcao: a altura do dialogo

A primeira versao saiu com o painel **esticado na altura da tela**, com o corpo vazio no
meio — a captura do usuario mostrou. Causa: `inset: 0` define `top` e `bottom` como zero e,
com `height: auto`, um elemento `position: fixed` **preenche** o espaco entre os dois. Nao
sobrava folga para o `margin: auto` dividir, entao o dialogo nao "centralizava": ele ocupava
tudo.

Correcao: `height: fit-content`. Com altura de conteudo sobram as duas folgas, o `margin:
auto` centraliza, e o `max-height: calc(100dvh - 2rem)` continua sendo o teto — quando o
conteudo passa dele, o teto manda e o corpo rola. O dialogo agora cresce com o formulario e
para.

`ui-tabelas.sh` ganhou a checagem (com sabotagem propria) porque e um erro silencioso: o
dialogo continua abrindo e funcionando, so com a altura errada.

### Verificacao

| # | Check | Result |
|---|---|---|
| 1 | `ui-tabelas.sh` cobre as **7** telas; reservas entra com `filtros: False` (e a unica sem faixa de busca) | OK |
| 2 | reservas: os dois dialogos existem, com `.app-dialog` + `role="dialog" aria-modal="true"`, fora de `.page-content` | OK |
| 3 | reservas: as tres acoes com `data-tip`, o campo `motivo` no dialogo de negacao, `btn-error` no confirmar e nenhum `data-confirm` | OK |
| 4 | reservas: nenhuma celula de acoes com campo **visivel** (o defeito original) | OK |
| 5 | CSS: `.app-dialog` com `position: fixed` + `inset: 0` + `margin: auto` + `max-height` e o estado aberto | OK |
| 6 | self-test negativo: **13/13** markup (dialogo virando drawer lateral e o motivo desaparecendo) e **13/13** CSS (o dialogo deixando de centralizar, nascendo visivel e perdendo a altura de conteudo) | OK |
| 7 | `ui-drawer-js.mjs` continua 21/21 — o dialogo e coberto pelo mesmo harness | OK |
| 8 | `ui-routes.sh shell` · `ui-shell.sh` · `ui-drawer.sh` · `ui-invariants.sh` | 26/26 · OK · OK · `INVARIANTS OK` |
| 9 | `docker compose run --rm test` | **153 testes, 0 falhas** |

### Deriva do snapshot, revisada

| Item | Antes | Depois | Por que |
|---|---|---|---|
| `action-urls` | `${acao}` x2 | `${acao}` x3 | o `dialog.tag` soma um `action="${acao}"` |
| `action-urls` | 29 entradas | 27 | as tres acoes de reserva viraram o atributo `acao=` de um tag |
| `method_inputs` | 22 | 20 | tres forms com `_method` saem de reservas; `dialog.tag` soma um |
| `csrf_includes` | 30 | 28 | idem para o `csrf.jspf` |
| `confirmations` | 13 | 12 | saiu o `data-confirm` do cancelamento (virou dialogo) |
| `utf8_decls` | 9 | **10** | subiu: o `dialog.tag` declara `pageEncoding` |

Fecham arquivo por arquivo: os tres `action`/`_method`/`csrf.jspf` de reservas reapareceram
dentro de `ui:acao-form`, `ui:acao-editar` e `ui:dialog`.

## Known limitations (carried to the end)

1. **No browser in this environment.** Every verification is DOM/CSS-level. Button/alert colours, spacing,
   the drawer animation and the responsive layout at real viewports are unverified visually.
2. **Cards and form fields are still legacy.** `card` (25 JSPs) needs a `card-body` wrapper before daisyUI's
   padding-less `.card` can take over; `field` → `fieldset` must move `forms.js` in the same commit.
3. **The cascade-layer end state is not reached.** The legacy stylesheets are still unlayered, so any
   remaining legacy rule whose selector matches a daisyUI component still wins. The fix — declaring the
   legacy layer *before* Tailwind's — depends on (2) being finished.
4. **Dark mode, pill-button radius and the pt-BR accent decision remain open** (plan §11).
5. **The drawer's logic is executed; its rendering is not.** `ui-drawer-js.mjs` runs the real `drawer.js`
   against a minimal DOM in Node, so open/close, the `drawer:fechado` event, the backdrop click, Esc, the
   focus trap and the scroll lock are actually executed. What still cannot be checked here is everything that
   depends on the browser engine: the `translate` animation, `100dvh`, the `position: fixed` stacking against
   the shell, and the real layout of the three bands. The `_csrf` lesson of S19 stands — source-level
   agreement is not proof of behaviour.
6. **The action tooltips are verified structurally, not visually.** `ui-areas.sh` proves the balloon is
   anchored to the button's right edge (`right: 0` on `.tooltip[data-tip]:before`, arrow re-centred on the
   button) and that the `data-tip` wiring is intact. Whether the balloon actually clears the table header
   vertically and whether `.overflow-x-auto` clips it are exactly the kind of questions only a browser can
   settle — the arithmetic in S25 says it fits, but that is arithmetic, not observation.
