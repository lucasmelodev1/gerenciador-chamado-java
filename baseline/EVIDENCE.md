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

## Known limitations (carried to the end)

1. **No browser in this environment.** Every verification is DOM/CSS-level. Button/alert colours, spacing,
   the drawer animation and the responsive layout at real viewports are unverified visually.
2. **Cards and form fields are still legacy.** `card` (25 JSPs) needs a `card-body` wrapper before daisyUI's
   padding-less `.card` can take over; `field` → `fieldset` must move `forms.js` in the same commit.
3. **The cascade-layer end state is not reached.** The legacy stylesheets are still unlayered, so any
   remaining legacy rule whose selector matches a daisyUI component still wins. The fix — declaring the
   legacy layer *before* Tailwind's — depends on (2) being finished.
4. **Dark mode, pill-button radius and the pt-BR accent decision remain open** (plan §11).
