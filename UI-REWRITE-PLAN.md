# UI Rewrite — Step-by-Step Implementation Plan

Implementation plan that turns [UI-REWRITE-MAP.md](UI-REWRITE-MAP.md) into ordered, individually
verifiable steps. **Planning only: this document changes no source file.** After writing it,
`git status` must show only documentation (`UI-REWRITE-MAP.md`, `UI-REWRITE-PLAN.md`, and the
`CONTEXT.md` pointer added earlier) — no file under `src/`.

Companion documents: [UI-REWRITE-MAP.md](UI-REWRITE-MAP.md) (analysis), [AGENTS.md](AGENTS.md),
[STANDARDS.md](STANDARDS.md), [CONTEXT.md](CONTEXT.md). `ESPECIFICACAO.md` is not edited.

---

## 0. How to use this plan

1. Steps `S1…S18` execute **in order**. A step starts only when its dependency's gate passed.
2. Every step ends with **Verifiable output** — a command plus the literal expected result. A step is
   done when that command was run and its output recorded in the evidence log (§6).
3. Every step declares **Escopo de escrita** (files it may touch). Do not edit outside it. Steps are
   sized so their write scopes are disjoint.
4. **Never** proceed on a red gate. Roll back with `git checkout -- <files>` (each step is one commit).
5. Commit convention: `feat(ui): <step id> <summary>` — one commit per step, so `git bisect` stays
   usable across the rewrite.
6. `ESPECIFICACAO.md` is off limits (AGENTS.md). Documentation updates go to the `CONTEXT.md` files in
   `src/main/webapp/WEB-INF/jsp/`, `src/main/resources/static/`, and the root.

### Global progress tracker

| Phase | Steps | Theme | Screens affected |
|---|---|---|---|
| P0 | S1–S3 | Baseline, fixture, guardrails | none (instrumentation) |
| P1 | S4–S6 | Tailwind 4 + daisyUI 5 toolchain & theme | none (additive) |
| P2 | S7–S8 | App shell (fragments) | **all 26** |
| P3 | S9–S10 | Primitives & fragments | all (shared) |
| P4 | S11–S15 | Screens by archetype | 20 |
| P5 | S16 | Reservation calendar | 2 |
| P6 | S17–S18 | Cleanup, docs, acceptance | all |

---

## 1. Global invariants (the do-not-break contract)

These are asserted mechanically by `scripts/ui-invariants.sh` (S3) and re-checked at S18.

**Never change:**

| Invariant | Why | How it is checked |
|---|---|---|
| The 26 returned view names (`"admin/areas/lista"`, …) | `view().name(...)` is asserted by the 4 web integration tests | grep the 26 literals in `src/main/java/.../controller/web/` |
| Model attribute keys (`pageTitle`, `appName`, `currentUser*`, `isAdministrador/isColaborador/isMorador`, `calendarAssets`, `*Page`, `calendarAssets`, `viewAtual`, `periodo*`, `areasFiltro`, `successMessage`, `errorMessage`, `*Form`, `*Edicao`, `filtro*`) | templates consume them | grep JSP `${...}` identifiers against the controller `addAttribute` list |
| All form `action` URLs | they hit the real mutation endpoints | grep `action="` in JSPs, diff against baseline |
| `_method` hidden inputs (`patch`/`delete`/`put`) | `spring.mvc.hiddenmethod.filter.enabled=true` | grep `name="_method"` |
| `csrf.jspf` include inside every mutating `<form>` | cookie CSRF repository | count includes == count of mutating forms |
| `enctype="multipart/form-data"` on the 5 upload forms | file upload | grep `enctype` |
| `pageEncoding="UTF-8"` / `charset="UTF-8"` | pt-BR accents | grep in `taglibs.jspf` + `head.jspf` |
| `data-*` JS hooks (`data-confirm`, `data-password-*`, `data-character-*`, `data-auto-submit`, `data-filter-*`, `data-alert`, `data-dismiss-alert`, `data-sidebar*`) | behaviour | grep per §5 of the map |
| `#calendar`, `#reservas-data`, `.reserva-data`, `#reserva-detalhe`, `.reserva-titulo|meta|motivo`, `#form-aprovar|negar|cancelar`, `#filtro-area`, `#reserva-fechar` | `calendar.js` contract | grep in `fragments/reservas-agenda.jspf` + JSPs |
| `pom.xml` JaCoCo `includes` and the 0.40 line rule | the challenge's coverage evidence | `grep -A2 COVEREDRATIO pom.xml` |

**UI scope only: no change to** `src/main/java/**`, `src/main/resources/db/**`, `pom.xml` dependency
set, security config, or routes. If a step seems to need one, stop and re-plan.

---

## 2. Environment facts (verified on this machine)

| Fact | Value | Consequence for this plan |
|---|---|---|
| Host JDK | **25.0.4.1** (only `openjdk-bin-25`; no JDK 21) | Project targets 21. Host `./mvnw` is *best-effort*; **all gates run in Docker** (`eclipse-temurin:21`) |
| `.mvn/wrapper/` | only `maven-wrapper.properties`, no jar | `./mvnw` needs network on first run; Docker is the reproducible path |
| Node / npm | v26.3.0 / 12.2.0 | Tailwind CLI can run locally (S4) |
| Docker / Compose | 29.7.2 / v5.5.0 | the app + DB gates are available |
| Bootstrap admin | `APP_BOOTSTRAP_ADMIN_EMAIL=admin@condominio.local`, `APP_BOOTSTRAP_ADMIN_SENHA=admin123` (`.env.example`) | the smoke script's admin session |
| Seed data | **none** — no morador/colaborador, no bloco/area/tipo/status | S2 must create a fixture |
| `/api/auth/**` | permitted in `SecurityConfig` but **no controller exists**; the `jwt` cookie is read by `JwtAuthenticationFilter` and never written anywhere | The JSON API is **not** usable for seeding or for a future SPA front-end. Seed through the **web form flow** (session + CSRF). Record as a finding — do not fix in this rewrite |
| Tests coupling | 22 test files; web tests assert `view().name`, model attributes, redirects, status. Zero markup/CSS assertions | A presentation-only rewrite is test-safe **iff** §1 holds |
| Coverage gate | `jacoco-check` at `verify`, LINE ≥ 0.40 over 8 reserva classes | UI work must not touch those classes; `verify` must stay green |

### Canonical commands

```bash
# authoritative build (Docker, JDK 21)
docker compose build app
docker compose up -d db app          # http://localhost:8080

# full suite (the gate that matters)
docker compose run --rm test

# host-only, best effort (JDK 25)
./mvnw -DskipTests clean package
```

---

## 3. Steps

Each step: **Depende de · Escopo de escrita · Ações · Saída verificável · Gate · Rollback.**

---

### P0 — Baseline, fixture and guardrails

#### S1 — Baseline capture

- **Depende de:** nothing.
- **Escopo de escrita:** `scripts/ui-baseline.sh` (new), `baseline/` (new, add `baseline/` to `.gitignore`).
- **Ações**
  1. Record `git rev-parse HEAD` and `git status --porcelain`.
  2. `sha256sum` the 34 templates (`src/main/webapp/**/*.jsp*`) + 5 project CSS + 6 project JS = **45 files**.
  3. `docker compose build app` → log.
  4. `docker compose run --rm test` → log, extract the test/assertion totals.
  5. `./mvnw -DskipTests clean package` → log; `unzip -l target/*.war` snapshot.
  6. Write `baseline/README.md` stating which artifact proves what.
- **Saída verificável**
  ```bash
  bash scripts/ui-baseline.sh
  ls baseline/            # git-head.txt assets.sha256 mvn-package.log test-suite.log war-contents.txt
  wc -l baseline/assets.sha256          # -> 45
  grep -c "BUILD SUCCESS" baseline/*.log   # -> >= 1
  grep -E "Tests run: [0-9]+, Failures: 0, Errors: 0" baseline/test-suite.log | tail -1
  ```
  Expected: 45 hashes, zero test failures, one WAR listing containing `WEB-INF/classes/static/css/`.
- **Gate:** all five artifacts exist; suite green; record the baseline test count and the 8 reserva classes' coverage % in the evidence log (S18 compares against them).
- **Rollback:** delete `baseline/` and `scripts/ui-baseline.sh`; nothing else changed.

#### S2 — Smoke fixture + 26-route matrix (baseline markers)

- **Depende de:** S1.
- **Escopo de escrita:** `scripts/ui-seed.sh`, `scripts/ui-routes.sh` (new), `baseline/routes.tsv`.
- **Ações**
  1. `ui-seed.sh`, using **session + CSRF form POSTs** (no JSON API — see §2):
     `GET /login` → parse `_csrf` and cookie jar → `POST /login` as admin →
     `POST /admin/blocos` (identificacao, quantidadeAndares, apartamentosPorAndar) →
     `POST /admin/areas` (nome, status=Ativo) →
     `POST /admin/tipos-chamado` (titulo, prazoHoras) →
     `POST /admin/usuarios` × 2 (morador, colaborador) →
     extract UUIDs from list-page links (`/admin/blocos/<uuid>`, `/admin/usuarios/<uuid>`) →
     `POST /admin/moradores/<moradorId>/unidades` (`_method=put`) →
     `POST /admin/colaboradores/<colabId>/tipos-chamado` (`_method=put`) →
     login as morador → `POST /morador/chamados` (multipart) and `POST /morador/reservas` →
     login as admin → `POST /admin/reservas/<reservaId>/aprovacao` (`_method=patch`).
     Idempotent: re-running must not duplicate (check-then-create by name/email).
  2. `ui-routes.sh <baseline|new> [outdir]` logs in per role (cookie jars kept at `baseline/{admin,
     morador,colaborador}.jar`), calls all 26 routes, extracts detail UUIDs from the corresponding list
     page, writes `route<TAB>role<TAB>status<TAB>matched-marker` to `baseline/routes.tsv`, and saves each
     response body to `<outdir>/<route>.html` (default `baseline/html-<set>`).
- **Saída verificável**
  ```bash
  bash scripts/ui-seed.sh && bash scripts/ui-routes.sh baseline
  column -t baseline/routes.tsv
  awk -F'\t' '$3!=200 && $3!="302" {bad++} END{print "non-200:", bad+0}' baseline/routes.tsv   # -> non-200: 0
  wc -l baseline/routes.tsv                                                                     # -> 26
  grep -c 'app-shell' baseline/routes.tsv          # baseline shell marker in >= 20 rows
  grep -c 'auth-layout' baseline/routes.tsv        # -> 1 (/login)
  ```
  Expected: 26 rows, all `200`, each with its baseline marker.
- **Gate:** 26/26 routes return 200 **with the pre-rewrite markers**. If any route is 404, the fixture is incomplete — fix the seed before anything else. This matrix is the rewrite's regression detector.
- **Rollback:** `docker compose down -v` (drops the fixture volume), delete the two scripts.

#### S3 — Invariant guard script

- **Depende de:** S1, S2.
- **Escopo de escrita:** `scripts/ui-invariants.sh` (new).
- **Ações**
  1. Assert every §1 invariant with greps/counts (view names, attribute keys, action URLs vs
     `baseline/actions.txt`, `_method` count, `csrf.jspf` includes == mutating forms, `enctype` count == 5,
     UTF-8 declarations, data-* hooks, calendar ids, JaCoCo rule).
  2. Self-test: the script must **fail** on deliberate drift and **pass** on clean HEAD.
- **Saída verificável**
  ```bash
  bash scripts/ui-invariants.sh; echo "clean: $?"        # -> clean: 0
  # negative control: inject drift, expect failure, then restore.
  # NOTE: admin/areas/lista.jsp uses inline onsubmit, NOT data-confirm — target a file that does.
  sed -i 's/data-confirm/data-xconfirm/' src/main/webapp/WEB-INF/jsp/admin/usuarios/detalhe.jsp
  bash scripts/ui-invariants.sh; echo "drift: $?"        # -> drift: 1  (confirmations 12 -> 9)
  git checkout -- src/main/webapp/WEB-INF/jsp/admin/usuarios/detalhe.jsp
  bash scripts/ui-invariants.sh; echo "restored: $?"     # -> restored: 0
  ```
- **Gate:** `clean: 0`, `drift: 1` with the violating file named, `restored: 0`. The negative control is the point — an unverifiable guard is useless.
- **Rollback:** delete the script; the JSP is restored by `git checkout --`.

---

### P1 — Toolchain

#### S4 — Tailwind 4 + daisyUI 5 bundle

- **Depende de:** S1.
- **Escopo de escrita:** `package.json`, `package-lock.json`, `src/main/resources/static/css/app.css` (new), `.gitignore` (node_modules, `*.build.css` if Option B/A decided), `tailwind`/`daisyui` devDependencies.
- **Ações**
  1. `npm i -D tailwindcss @tailwindcss/cli daisyui@latest`.
  2. `app.css`: `@import "tailwindcss" source(none);` + `@source "../../../webapp/WEB-INF/jsp";` +
     `@source "../js";` + `@source not "../js/vendor";` + daisyUI plugin (`themes: false` + custom theme).
     **`source(none)` is required, not cosmetic** — see the finding in §10: with automatic detection the
     Tailwind scanner treats every file in the repo as content, so the planning docs (which enumerate
     daisyUI components) and even `aria-label="Abrir menu"` inflated the bundle from 48 KB to 251 KB.
  3. npm scripts: `build:css` (CLI → `static/css/app.build.css`, `--minify`) and `watch:css`.
- **Saída verificável**
  ```bash
  npm run build:css
  ls -l src/main/resources/static/css/app.build.css        # exists, non-zero
  for c in '\.btn' '\.drawer-side' '\.menu' '\.navbar' '\.table' '\.badge' '\.join' '\.stats'; do
    printf '%s %s\n' "$c" "$(grep -c "$c" src/main/resources/static/css/app.build.css)"; done
  grep -c "\.hidden" src/main/resources/static/css/app.build.css
  ```
  Expected: every component selector present with count ≥ 1 (proves the extractor read the JSP tree), and
  the `.hidden` utility present (proves `@source "../js"` works).
- **Gate:** all selectors > 0 **and** the bundle contains no selector that only exists in a JSP the scanner
  skipped. Record the uncompressed and minified byte sizes — S18 uses them as the CSS budget baseline.
- **Rollback:** delete `package*.json`, `app.css`, `app.build.css`, `node_modules/`.

#### S5 — Custom theme + component gallery

- **Depende de:** S4.
- **Escopo de escrita:** `app.css` (`@plugin "daisyui/theme"` block), `src/main/resources/static/ui-preview.html` (new, static, not linked from the app).
- **Ações**
  1. Map the `base.css` `:root` palette to daisyUI tokens (`primary`, `accent`, `success`, `error`,
     `neutral`, `base-*`, `--radius-*`, fonts) — table in UI-REWRITE-MAP.md §7.1.
  2. `ui-preview.html` renders one instance of every component the app will use: `drawer`, `navbar`,
     `menu`, `card`+`card-body`, `stats`/`stat`, `table`+`table-zebra`, `badge` (all 4 semantic colors),
     `alert` (success/error), `btn` (primary/default/error/ghost/link/block/square), `fieldset`+`input`+
     `select`+`textarea`+`file-input`+`validator`, `join`, `timeline`, `modal`, `tabs`, `steps`, `toast`,
     `tooltip`, `breadcrumbs`, `empty-state` (custom composition), `theme-controller`.
  3. Decide and document the two open theme questions (pill buttons vs single `--radius-field`; serif
     headings) in `CONTEXT.md` of `static/`.
- **Saída verificável**
  ```bash
  npm run build:css
  docker compose up -d db app
  # /ui-preview.html is a static page, so it needs the web (session) chain — use S2's admin cookie jar
  curl -s -o /dev/null -w '%{http_code}\n' -b baseline/admin.jar http://localhost:8080/ui-preview.html   # -> 200
  curl -s -b baseline/admin.jar http://localhost:8080/ui-preview.html | grep -o 'class="[^"]*"' | wc -l
  grep -o 'data-theme="chamados"' src/main/resources/static/ui-preview.html
  # theme tokens actually emitted:
  grep -c -- '--color-primary' src/main/resources/static/css/app.build.css    # >= 2
  ```
  Plus a **screenshot artifact**: `baseline/ui-preview-before.png` (old look) and
  `baseline/ui-preview-after.png` (daisyUI look), recorded in the evidence log.
- **Gate:** gallery renders with no unstyled component at 360/768/1280 px; theme colors present in the
  compiled CSS. This is the visual contract every later step is compared against.
- **Rollback:** remove the theme block and the preview file; `npm run build:css`.

#### S6 — Maven/Docker build integration

- **Depende de:** S4, S5.
- **Escopo de escrita:** `Dockerfile` (add a `node:22-alpine` frontend stage), `docker-compose.yml` (only if a build arg is needed), `.gitignore`, optionally `package.json` scripts. Decision recorded: **Option A** (build-time) vs **Option B** (commit `app.build.css`).
- **Ações**
  1. Add the Node stage: `npm ci` → `npm run build:css` → output copied into the Maven build stage before `mvn clean package`.
  2. Wire the new stylesheet into `head.jspf` **after** the legacy CSS only in a scratch check (do not commit a half-switched head here); the real switch is S7. For this step the goal is only that the artifact ships.
- **Saída verificável**
  ```bash
  docker compose build app
  docker compose run --rm app sh -c 'ls -l /app/app.war'   # or inspect the built WAR
  unzip -l target/*.war | grep 'static/css/app.build.css'  # present
  docker compose up -d db app
  curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080/css/app.build.css   # -> 200 (public: /css/** is permitted)
  docker compose down
  ```
  Expected: WAR contains the bundle; `/css/app.build.css` is served with 200 **without authentication**
  (proves the `StaticResourcesConfig` matcher still covers it — no security change needed).
- **Gate:** `docker compose build app` succeeds **from a clean state** (`docker compose down -v` first, so
  npm runs against the lockfile) and the served CSS byte size equals the locally built one.
- **Rollback:** `git checkout -- Dockerfile docker-compose.yml`; the app still builds Maven-only.

---

### P2 — Shell (every screen changes here)

#### S7 — Shell rewrite (atomic, highest blast radius)

- **Depende de:** S6, S3.
- **Escopo de escrita:** `fragments/head.jspf`, `topbar.jspf`, `sidebar.jspf`, `alerts.jspf`,
  `scripts.jspf`, `taglibs.jspf` (only if a nav-active attribute is added), `css/app.css` (custom layer),
  `js/layout.js`, delete `css/base.css`, `css/layout.css`.
- **Ações**
  1. `head.jspf`: link `app.build.css` + a slim `custom.css`; keep the conditional FullCalendar block and
     the UTF-8/charset tags. Remove the 4 legacy links.
  2. `sidebar.jspf` → daisyUI `drawer`: `drawer-toggle` checkbox + `drawer-content` + `drawer-side` +
     `drawer-overlay`; nav becomes `menu menu-lg` with `menu-active` + `aria-current="page"` computed
     **server-side** (`currentUserHome`/request path) instead of `layout.js` path matching.
  3. `topbar.jspf` → `navbar` + `navbar-start`/`navbar-end`, sticky `bg-base-100/80 backdrop-blur`; the
     hamburger becomes `<label for="app-drawer">` with an inline SVG.
  4. `layout.js`: delete `initSidebarToggle`, delete `initActiveNav` (replaced server-side). Keep the file
     only if it still owns something; otherwise remove it from `scripts.jspf`.
  5. `alerts.jspf`: `alert alert-success|alert-error` + `role="alert"`, keep `data-alert`/`data-dismiss-alert`.
  6. `custom.css`: theme-complementary rules only (ambient background, entry animation, auth art kept for S11).
- **Saída verificável**
  ```bash
  docker compose run --rm test                                        # green
  bash scripts/ui-routes.sh new
  awk -F'\t' '$3!=200 {bad++} END{print "non-200:", bad+0}' baseline/routes.tsv   # -> 0
  grep -c 'drawer-side' baseline/routes.tsv          # >= 20 (all non-login screens)
  grep -c 'navbar'      baseline/routes.tsv          # >= 20
  grep -c 'menu-active' baseline/routes.tsv          # >= 1 per role
  grep -c 'role="alert"' baseline/routes.tsv || true # only with a flash; check separately
  bash scripts/ui-invariants.sh; echo $?             # -> 0
  wc -l src/main/resources/static/css/*.css          # base.css + layout.css gone (~514 lines removed)
  ```
  Plus `baseline/shell-{360,768,1280}.png` screenshots and a keyboard check: Tab reaches the hamburger,
  Enter opens the drawer, Esc closes it, focus stays visible.
- **Gate:** suite green, 26/26 routes 200, all shell markers present, invariants clean, drawer works by
  keyboard at 360 px. One atomic commit — a partially converted shell is worse than either state.
- **Rollback:** `git revert <commit>` — single commit, no other step in flight.

#### S8 — Shell responsive + a11y pass

- **Depende de:** S7.
- **Escopo de escrita:** `css/app.css`, `custom.css`, `fragments/topbar.jspf`, `fragments/sidebar.jspf`.
- **Ações:** fix the findings from S7 (drawer at `lg`, sticky offset, focus rings, `aria-expanded`/`aria-controls` on the toggle, `aria-label` on icon buttons, `prefers-reduced-motion` for the entry animation, skip-to-content link).
- **Saída verificável** (all literal)
  ```bash
  for w in 360 768 1280; do
    curl -s -b baseline/admin.jar "http://localhost:8080/admin" > /dev/null && echo "w=$w ok"; done
  grep -c 'aria-expanded'  src/main/webapp/WEB-INF/jsp/fragments/topbar.jspf   # >= 1
  grep -c 'prefers-reduced-motion' src/main/resources/static/css/custom.css   # >= 1
  grep -c 'skip' src/main/webapp/WEB-INF/jsp/fragments/sidebar.jspf           # >= 1
  ```
  Plus screenshots at the 3 widths + a `prefers-reduced-motion: reduce` capture.
- **Gate:** no horizontal scrollbar at 360 px on the 4 dashboards; a11y attributes present; suite green.
- **Rollback:** `git revert <commit>`.

---

### P3 — Primitives and shared fragments

#### S9 — Zero-visual-change fragment extraction

- **Depende de:** S3.
- **Escopo de escrita:** new `fragments/{form-field,tabela,lista-filtros,detalhe-grid,paginacao,comentarios,acoes-reserva}.jspf`, the ~20 consuming JSPs (include substitution only), `baseline/html-s9-{before,after}/`.
- **Ações**
  1. Capture rendered HTML of all 26 routes → `baseline/html-s9-before/`.
  2. Extract the fragments from the map's §6 list **without changing any class or attribute** — pure `<%@ include %>` substitution with `<c:set>` parameters.
  3. Re-capture → `baseline/html-s9-after/`.
- **Saída verificável**
  ```bash
  bash scripts/ui-routes.sh baseline baseline/html-s9-before
  # ...extraction commit...
  bash scripts/ui-routes.sh baseline baseline/html-s9-after
  diff -r baseline/html-s9-before baseline/html-s9-after | grep -c '^[<>]'   # -> 0
  diff -rq baseline/html-s9-before baseline/html-s9-after | wc -l            # -> 0 differing files
  docker compose run --rm test                                              # green
  bash scripts/ui-invariants.sh; echo $?                                    # -> 0
  ```
  **Expected: a byte-identical render.** This is the step that makes the rest of the rewrite cheap, and
  its proof is a zero-line diff.
- **Gate:** diff line count 0 (any non-zero delta must be listed and justified per file in the evidence
  log, e.g. whitespace from taglib placement).
- **Rollback:** `git revert <commit>` — no user-visible change either way.

#### S10 — Primitive restyle

- **Depende de:** S7, S9.
- **Escopo de escrita:** the 7 new fragments + `fragments/alerts.jspf`, `css/app.css`, `custom.css`,
  `js/forms.js`, `js/tables.js`, delete `css/components.css`, optionally `css/responsive.css`.
- **Ações**
  1. Restyle inside the fragments only: `fieldset`/`input`/`select`/`textarea`/`file-input`, `table` +
     `overflow-x-auto` + `table-zebra` + `join` pagination, `badge` status mapping (literal `<c:choose>`
     or `@source inline(...)` — never interpolation), `timeline` comments, custom `empty-state`,
     `detail-list` grid, `list-row`.
  2. Migrate the JS hooks that must move: `.is-hidden` → `hidden`, `field.parentElement` →
     `closest('[data-character-field]')`, `closest(".password-field")` → `closest('[data-password-field]')`.
- **Saída verificável**
  ```bash
  docker compose run --rm test; bash scripts/ui-invariants.sh; echo $?
  bash scripts/ui-routes.sh new
  for m in 'table' 'badge' 'join' 'card-body' 'stats' 'timeline-box' 'file-input'; do
    printf '%-12s %s\n' "$m" "$(grep -c "$m" baseline/routes.tsv)"; done
  grep -c -- '--color-primary' src/main/resources/static/css/app.build.css
  # extraction safety: every emitted semantic class must exist in the bundle
  bash scripts/ui-check-badges.sh          # asserts each badge-* used in JSP exists in app.build.css
  ls src/main/resources/static/css/        # components.css gone
  ```
  Plus a **status-color proof**: `/admin/reservas` and `/morador/reservas` screenshots showing Solicitado
  /Aprovado/Negado/Cancelado in four distinct colors (today they are identical — map §4.3).
- **Gate:** 4 distinct status colors visible; zero badge classes missing from the bundle; suite green;
  invariants clean.
- **Rollback:** `git revert <commit>`; `components.css` returns.

---

### P4 — Screens by archetype

Shared acceptance for S11–S15 (each step repeats it):

```bash
docker compose run --rm test            # green
bash scripts/ui-invariants.sh           # 0
bash scripts/ui-routes.sh new           # touched routes 200, markers present
# per-screen: 360 / 768 / 1280 screenshots archived
```

#### S11 — Auth + dashboards (archetypes A, B) — 4 screens

- **Escopo de escrita:** `auth/login.jsp`, `{admin,morador,colaborador}/dashboard.jsp`.
- **Ações:** auth split layout → `hero`/`card` (+ the `auth-brand` art moved into `custom.css` if kept);
  dashboards → `stats`/`stat`/`stat-actions`; `card`+`card-body`; status badges.
- **Saída verificável adicional:** `baseline/routes.tsv` rows for `/login`, `/admin`, `/morador`,
  `/colaborador` carry `stats`, `card-body`; login page contains no legacy class
  (`grep -c 'auth-layout\|stat-card\|hero-card' baseline/html-new/login.html` → 0).
- **Gate:** shared acceptance + first-paint check (no FOUC beyond the compiled CSS), and the login failure
  path still shows the `alert-error` banner (`POST /login` with a wrong password → `/login?error=true`
  renders it).
- **Rollback:** `git revert <commit>`.

#### S12 — Admin cadastros, form + list (archetype D) — 6 screens

- **Escopo de escrita:** `admin/{blocos/lista,areas/lista,tipos-chamado/lista,status-chamado/lista,usuarios/lista,vinculos-morador/lista}.jsp`.
- **Ações:** two-column grids → Tailwind `grid lg:grid-cols-*`; forms → `fieldset`; lists → `table` +
  `join` pagination + local filter `input`; the "Reservado" `span.btn.disabled` → `btn btn-disabled` with
  `role="button" aria-disabled="true" tabindex="-1"`; `data-auto-submit` selects kept.
- **Saída verificável adicional:** all 6 routes 200 with `table`+`join`+`fieldset`;
  `grep -c 'btn-disabled' baseline/html-new/admin-status-chamado.html` ≥ 1; the dual-pagination page
  (`vinculos-morador`) shows both counters and both `join` groups.
- **Gate:** shared acceptance + every create/edit/delete form still round-trips (the seed script's
  create calls re-run cleanly against the new UI and return 302).
- **Rollback:** `git revert <commit>`.

#### S13 — Filtered lists + row actions (archetype C) — 4 screens

- **Escopo de escrita:** `admin/chamados/lista.jsp`, `admin/reservas/lista.jsp`,
  `morador/chamados/lista.jsp`, `morador/reservas/lista.jsp`, `colaborador/chamados/lista.jsp`,
  `morador/reservas/disponibilidade.jsp`.
- **Ações:** GET filter grids; tables; approve/deny/cancel row actions → `btn` + inline deny input →
  `join`; `onsubmit="return confirm(...)"` normalized to `data-confirm` (single mechanism, map §4.3).
- **Saída verificável adicional:**
  ```bash
  grep -rc 'onsubmit="return confirm' src/main/webapp/WEB-INF/jsp/   # -> all 0
  grep -rc 'data-confirm' src/main/webapp/WEB-INF/jsp/               # >= 4
  # the security-relevant path still works end to end:
  bash scripts/ui-decision-check.sh   # create pending -> approve -> deny-without-motive -> deny-with-motive
  ```
  Expected: deny without motive returns the error redirect; with motive returns success; state changes
  verify against `/admin/reservas`.
- **Gate:** shared acceptance + `ui-decision-check.sh` green (this is the challenge's CA-01-06 path — the
  UI must not weaken it).
- **Rollback:** `git revert <commit>`.

#### S14 — Detail pages (archetypes E, F, G) — 4 screens

- **Escopo de escrita:** `{admin,colaborador,morador}/chamados/detalhe.jsp`, `admin/usuarios/detalhe.jsp`, `admin/blocos/detalhe.jsp`.
- **Ações:** `detail-list` → `stats`/`grid` label-value tiles; `description-box` → `bg-base-200 rounded-box
  whitespace-pre-wrap`; comments → `timeline timeline-vertical` with `timeline-box`; attachments →
  `list-row` fragment + `file-input`; the two admin detail forms (status, relations) keep `_method`.
- **Saída verificável adicional:** the 4 routes 200 with `timeline-box` (3 of them), `file-input`
  (chamado details), `stats` (blocos detalhe); `grep -c 'disabled' admin-usuario-detalhe.html` ≥ 1 for the
  read-only profile field, and its hidden `name="tipo"` still present.
- **Gate:** shared acceptance + upload round-trip (a file uploaded as morador appears under "Anexos" after
  redirect).
- **Rollback:** `git revert <commit>`.

#### S15 — Narrow forms + availability (archetypes H, I) — 3 screens

- **Escopo de escrita:** `morador/chamados/novo.jsp`, `morador/reservas/nova.jsp`, `morador/reservas/disponibilidade.jsp`.
- **Ações:** `narrow-content` → `max-w-3xl mx-auto`; `datetime-local`/`date`/`select` + `textarea` with
  the character counter; add `validator`+`validator-hint` as an **additive** client hint while server-side
  validation stays authoritative; availability table → `table` with pending vs approved badges.
- **Saída verificável adicional:**
  - Submitting a reservation with `fim <= inicio` is still refused (server redirect + `alert-error`) —
    proves the hint did not replace server validation.
  - Approved vs pending rows on `/morador/reservas/disponibilidade` show **different** badges
    (CA-01-02 made visible — a genuine UX gain).
- **Gate:** shared acceptance + both negative cases above.
- **Rollback:** `git revert <commit>`.

---

### P5 — Reservation calendar

#### S16 — Agenda: toolbar, FullCalendar tokens, detail modal — 2 screens

- **Depende de:** S10.
- **Escopo de escrita:** `fragments/reservas-agenda.jspf`, `admin/reservas/agenda.jsp`,
  `morador/reservas/agenda.jsp`, `css/calendar.css`, `custom.css`, `js/calendar.js`,
  `css/vendor/fullcalendar/*` (read-only; not modified).
- **Ações**
  1. Keep FullCalendar (daisyUI 5's `calendar` component does not support it — map §7.3).
  2. `calendar.css`: bridge `--fc-classic-*` to daisyUI theme variables (`--color-primary`,
     `--color-base-100`, `--color-base-content`, `--color-error`, `--color-accent`, `--color-base-300`);
     lower the 640 px min-height on mobile.
  3. Toolbar: prev/label/next → `join`; Mes/Semana toggle → `tabs tabs-box`; area filter → `select`.
  4. Detail panel `#reserva-detalhe`: keep `hidden` toggling and the three form ids/actions; restyle as a
     `modal`/`card`. If switched to `<dialog>`, update `calendar.js` in the same commit and re-verify.
  5. Event colors: derive from the theme instead of the hardcoded `CORES_AREAS` hex list, or keep the list
     and document it — decide and record. Do **not** change the `data-status` values.
- **Saída verificável**
  ```bash
  bash scripts/ui-routes.sh new
  grep -c 'join'      baseline/routes.tsv    # agenda rows
  grep -c 'modal\|reserva-detalhe' baseline/routes.tsv
  grep -c -- '--fc-classic-primary' src/main/resources/static/css/calendar.css   # -> 1 (bridged, not hardcoded hex)
  grep -c '#0d5c63\|#dba24a' src/main/resources/static/css/calendar.css           # -> 0 once themed
  bash scripts/ui-decision-check.sh          # approve/deny/cancel from the agenda UI
  ```
  Plus agenda screenshots (month + week view) and a click-through that opens a pending reservation and
  approves it.
- **Gate:** agenda renders with theme colors, event click opens the panel, all three decisions (approve,
  deny with motive, cancel) redirect correctly, suite green, invariants clean.
- **Rollback:** `git revert <commit>`; FullCalendar vendor files were never touched.

---

### P6 — Cleanup and acceptance

#### S17 — Cleanup, docs, dead code

- **Depende de:** S11–S16.
- **Escopo de escrita:** remaining JSPs, `css/responsive.css` (delete), `css/base.css` leftovers, `js/*.js`
  headers, `src/main/webapp/WEB-INF/jsp/CONTEXT.md`, `src/main/resources/static/CONTEXT.md`,
  root `CONTEXT.md`, `UI-REWRITE-MAP.md` (mark decisions as executed), `.env.example` (only if a build var
  is added).
- **Ações**
  1. Delete `responsive.css` and any orphan CSS; grep every class used in JSPs against the bundle and
     delete dead ones (`section-subtitle`, `helper-text`, `status-row` were never styled).
  2. Normalize all confirmations to `data-confirm`; single `alert` mechanism.
  3. Apply the pt-BR accent decision (map §11 open question 3) consistently, or record the decision to keep ASCII.
  4. Update the 3 `CONTEXT.md` files: new CSS layout and pipeline, fragments list, JS responsibilities.
  5. Record executed decisions in `UI-REWRITE-MAP.md`.
- **Saída verificável**
  ```bash
  node -e "const fs=require('fs');const css=fs.readFileSync('src/main/resources/static/css/app.build.css','utf8');
  const used=new Set();for(const f of require('child_process').execSync('grep -rhoE \'class=\"[^\"]*\"\' src/main/webapp').toString().split('\n')){
  for(const m of f.matchAll(/[a-z][a-z0-9-]{2,}/g)) used.add(m[0]);}
  const MISS=[...used].filter(c=>!css.includes('.'+c)&&!c.startsWith('http'));
  console.log(MISS.length?MISS.join('\n'):'all classes covered');"
  ls src/main/resources/static/css/                 # only app.css, app.build.css, custom.css, calendar.css, vendor/
  grep -c 'helper-text\|section-subtitle\|status-row' src/main/webapp -r   # -> 0
  docker compose run --rm test
  ```
  Expected: no unstyled class (or a short, justified allowlist), dead CSS gone, suite green.
- **Gate:** the class-coverage check prints only allowlisted misses; docs updated; invariants clean.
- **Rollback:** `git revert <commit>` per concern (cleanup, docs) — two commits, not one.

#### S18 — Final acceptance

- **Depende de:** S17.
- **Escopo de escrita:** none (verification only). Fixes discovered here reopen the owning step.
- **Ações / Saída verificável** — run the full sequence from a **clean machine state**:

  ```bash
  # 1. Cold start, from zero
  docker compose down -v && docker compose up --build -d
  docker compose ps                      # db healthy, app running

  # 2. Full suite + coverage gate (JaCoCo LINE >= 0.40 on the 8 reserva classes)
  docker compose run --rm test 2>&1 | tee baseline/final-suite.log
  grep -E "Tests run: [0-9]+, Failures: 0, Errors: 0" baseline/final-suite.log | tail -1
  docker compose run --rm test sh -c 'grep -o "Total[^%]*%" target/site/jacoco/index.html | head -1'   # >= 40%

  # 3. All 26 routes, all 3 roles (fresh capture for the "no legacy CSS" check)
  bash scripts/ui-routes.sh new baseline/html-final
  awk -F'\t' '$3!=200 && $3!="302"{n++} END{print "non-200:", n+0}' baseline/routes.tsv   # -> 0
  wc -l baseline/routes.tsv                                                # -> 26

  # 4. All 26 pages free of legacy presentation classes
  #    (JS-hook classes such as .reserva-titulo are excluded — they are contract, see S16)
  grep -rlE 'data-table|status-pill|stat-card|app-shell|auth-layout|table-wrap|empty-state|two-column-grid|detail-grid|narrow-content|btn-secondary' baseline/html-final/ | wc -l   # -> 0

  # 5. Invariants + CSS budget
  bash scripts/ui-invariants.sh; echo $?
  wc -c src/main/resources/static/css/app.build.css src/main/resources/static/css/custom.css

  # 6. Diff review over the rewrite range
  REWRITE_BASE=$(git rev-list --max-parents=0 HEAD | tail -1)   # or the S1 baseline sha
  git diff --stat "$REWRITE_BASE"..HEAD
  git diff --stat "$REWRITE_BASE"..HEAD -- src/main/java src/main/resources/db pom.xml   # -> EMPTY (scope proof)
  ```

- **Gate (definition of done)**
  1. 26/26 routes return 200 with post-rewrite markers for all three roles.
  2. Full suite green, JaCoCo ≥ 0.40 (unchanged from S1 baseline).
  3. `scripts/ui-invariants.sh` exits 0.
  4. Zero legacy presentation classes in the rendered HTML.
  5. `git diff` proves `src/main/java`, `src/main/resources/db` and `pom.xml` dependencies are untouched.
  6. Compressed CSS budget recorded and justified (target: ≤ the S4 baseline bundle).
  7. Screenshots at 360/768/1280 for one screen per archetype (10) archived under `baseline/`.
- **Rollback:** the rewrite is 18 independent commits; `git revert` from the top until green.

---

## 4. Route verification matrix (26 routes)

Markers are written by `scripts/ui-routes.sh`. Baseline markers prove the fixture works before the
rewrite; new markers prove the rewrite landed.

| # | Route | Role | Baseline marker | Post-rewrite marker |
|---|---|---|---|---|
| 1 | `/login` | public | `auth-layout` | `card-body` |
| 2 | `/admin` | admin | `stats-grid` | `stats` |
| 3 | `/morador` | morador | `stats-grid` | `stats` |
| 4 | `/colaborador` | colaborador | `stats-grid` | `stats` |
| 5 | `/admin/blocos` | admin | `two-column-grid` | `fieldset` |
| 6 | `/admin/blocos/{id}` | admin | `hero-card` | `stats` |
| 7 | `/admin/areas` | admin | `two-column-grid` | `table` |
| 8 | `/admin/tipos-chamado` | admin | `two-column-grid` | `fieldset` |
| 9 | `/admin/status-chamado` | admin | `status-row` | `btn-disabled` |
| 10 | `/admin/usuarios` | admin | `two-column-grid` | `table` |
| 11 | `/admin/usuarios/{id}` | admin | `two-column-grid` | `divider` |
| 12 | `/admin/vinculos-morador` | admin | `pagination` | `join` |
| 13 | `/admin/escopo-colaborador` | admin | `two-column-grid` | `fieldset` |
| 14 | `/admin/chamados` | admin | `data-table` | `table-zebra` |
| 15 | `/admin/chamados/{id}` | admin | `timeline` | `timeline-box` |
| 16 | `/admin/reservas` | admin | `status-pill` | `badge` |
| 17 | `/admin/reservas/agenda` | admin | `id="calendar"` | `join` |
| 18 | `/morador/chamados` | morador | `filter-grid` | `select` |
| 19 | `/morador/chamados/novo` | morador | `narrow-content` | `file-input` |
| 20 | `/morador/chamados/{id}` | morador | `timeline` | `timeline-box` |
| 21 | `/morador/reservas` | morador | `status-pill` | `badge` |
| 22 | `/morador/reservas/nova` | morador | `datetime-local` | `validator` |
| 23 | `/morador/reservas/disponibilidade` | morador | `empty-state` | `badge-success` |
| 24 | `/morador/reservas/agenda` | morador | `id="calendar"` | `join` |
| 25 | `/colaborador/chamados` | colaborador | `data-table` | `table-zebra` |
| 26 | `/colaborador/chamados/{id}` | colaborador | `timeline` | `timeline-box` |

Detail routes (`{id}`) resolve their UUID from the corresponding list page; if the fixture is missing the
row records `SKIP` and the step fails — never silently pass.

---

## 5. Tooling deliverables

| Script | Owner step | Purpose |
|---|---|---|
| `scripts/ui-baseline.sh` | S1 | Hashes, build logs, suite log, WAR contents |
| `scripts/ui-seed.sh` | S2 | Idempotent fixture via web forms (session + CSRF) |
| `scripts/ui-routes.sh <baseline\|new>` | S2 | 26-route HTTP matrix + marker match |
| `scripts/ui-invariants.sh` | S3 | §1 do-not-break contract, with a negative self-test |
| `scripts/ui-check-badges.sh` | S10 | Every `badge-*` used in JSPs exists in the compiled CSS |
| `scripts/ui-decision-check.sh` | S13 | Reservation approve / deny / cancel round-trip |

All scripts are dev tooling, not production code: no dependency added to `pom.xml`, nothing imported by
`src/main/java`.

---

## 6. Evidence log template

Append one block per step to `baseline/EVIDENCE.md` (created in S1):

```markdown
## S<n> — <title>  (<commit sha>)
- Gate: PASS | FAIL
- Command: <exact command>
- Output (verbatim, trimmed):
  <...>
- Artifacts: <paths>
- Notes / deviations from the plan: <...>
- Next step unblocked: S<n+1>
```

---

## 7. Risks specific to execution

| Risk | Step | Mitigation |
|---|---|---|
| Shell rewrite flips all 26 screens at once | S7 | single atomic commit, `ui-routes.sh` before/after, instant `git revert` |
| npm in the Docker build breaks the graded `docker compose up` | S6 | verify from `down -v`; keep Option B (committed CSS) as the documented fallback |
| Dynamic class interpolation sneaks in (status badges) | S10 | `ui-check-badges.sh` fails the step if a used class is missing from the bundle |
| JS hook breakage (`parentElement`, `closest`, `.is-hidden`) | S10 | hooks migrated in the same commit; behavioural checks in `ui-decision-check.sh` |
| `calendar.js` status literals / `.reserva-*` selectors | S16 | ids/classes frozen by S3 invariants; change only with the JS in the same commit |
| Host JDK 25 vs target 21 | all | every gate runs in Docker; host `./mvnw` is never a gate |
| No JSON API auth → seeding complexity | S2 | use the web form flow; record the `jwt`/`/api/auth` gap as a finding, do not fix it here |
| Fixture drift makes route checks flaky | S2 | seed is idempotent and check-then-create; `ui-routes.sh` reports `SKIP` explicitly |
| Legacy CSS deleted before the replacement covers a page | S7/S10/S17 | delete per phase, never all at once |

---

## 8. Effort estimate

| Phase | Steps | Size | Note |
|---|---|---|---|
| P0 | S1–S3 | M | tooling-heavy, zero UI risk; S2 is the single hardest script |
| P1 | S4–S6 | M | build integration is the main unknown |
| P2 | S7–S8 | L | highest leverage, highest risk |
| P3 | S9–S10 | M | extraction makes P4 cheap |
| P4 | S11–S15 | L | volume, low risk (fragments do the work) |
| P5 | S16 | M | third-party CSS + bespoke JS |
| P6 | S17–S18 | M | cleanup + full acceptance |

Critical path: S1 → S2 → S3 → S6 → S7 → S9 → S10 → S16 → S18.
S4 and S5 can run in parallel with S2/S3 (disjoint write scopes: `package.json`/`app.css` vs
`scripts/`/`baseline/`).

---

## 9. What this plan does not do

- No change to backend behaviour, routes, security, persistence, or the challenge's business rules.
- No migration away from JSP; no SPA/JSON front-end (and the `jwt`/`/api/auth` gap means it is not
  currently viable anyway).
- No replacement of FullCalendar.
- No functional change to the reservation flow — only its presentation and the visibility of state
  (badges, availability distinction, lifecycle steps).
- No code edits while this document was written: only `UI-REWRITE-PLAN.md` was added.

---

## 10. Findings recorded during execution

Corrections and discoveries that changed this plan while P0–P2 ran. Full evidence in
[baseline/EVIDENCE.md](baseline/EVIDENCE.md).

### S4 — Tailwind's automatic content detection had to be disabled

`@import "tailwindcss"` scans **every non-ignored file in the repository** and treats any text as a
class candidate. Measured effect: the bundle was **250,926 B** because (a) this plan and `UI-REWRITE-MAP.md`
enumerate daisyUI components in prose, and (b) `aria-label="Abrir menu"` in the topbar emitted the whole
`.menu` component. With `source(none)` + explicit `@source`, the same JSPs produce **48,311 B**. The
`@source` path in the original plan was also off by one directory.

### S7 — the plan's deletion timing was wrong (sequencing flaw)

S7 originally deleted `base.css` and `layout.css`. That would have broken every screen not yet rewritten:

- `base.css` owns the `:root` design tokens referenced **48 times** by `layout.css` (5), `components.css`
  (24) and `calendar.css` (19);
- the content classes those files define are used by **9–26 JSPs each** (`two-column-grid` 9, `table-wrap`
  and `data-table` 16, `status-pill` 15, `empty-state` 21, `card`/`btn` 24, `alert` 26).

Revised: S7 keeps all four legacy stylesheets loaded **after** `app.build.css`, so not-yet-rewritten screens
render exactly as before and daisyUI only wins on class names the legacy CSS does not define
(`drawer`, `navbar`, `menu`). Deletion moves to **S10** (`components.css`) and **S17** (base, layout,
responsive). Consequence: during P2–P4 the shell is daisyUI while content is still legacy — a deliberate
hybrid, verified by both marker sets (shell 26/26 **and** baseline content 26/26).

### S7 — the drawer wrapper is a 25-file change, not a fragments-only change

The shell fragments cannot introduce the daisyUI drawer on their own: `drawer` requires
`input.drawer-toggle` + `.drawer-side` + `.drawer-content` as its children, and that wrapper lives in each
page. Mechanical two-token change applied to the 25 shell pages (login has no shell):
`class="app-shell"` → `class="drawer lg:drawer-open"`, `class="app-main"` → `class="drawer-content"`.

### S7 — two JSP/EL traps hit while moving nav highlighting server-side

1. **`pageContext.request.requestURI` is the forward target, not the request URL.** Spring forwards to the
   JSP, so the container rewrites the URI to `/WEB-INF/jsp/admin/blocos/lista.jsp`; every nav link failed to
   match and no item was ever active. Fix: read `jakarta.servlet.forward.request_uri` (servlet spec forward
   attribute) with `requestURI` only as a fallback.
2. `fn:replace(path, ctx, '')` is wrong when the context path is empty (deployed as ROOT, `ctx == ""`).
   Use `fn:substringAfter` guarded by a non-empty context path.

Both are recorded because they are exactly the class of problem the map's §4 "JSP barrier" warns about: the
template layer has no compile-time feedback, so these fail silently and only show up in rendered output.

### S2/S7 — the route matrix needed a third marker set

`baseline` (legacy) and `new` (post-rewrite) are not enough for an incremental rewrite: between S7 and S16
only the shell is converted, so `new` markers false-fail. `ui-routes.sh` now takes
`baseline | shell | new`, and the extra `shell` column (all 25 shell pages → `drawer-side`) is what S7 and
S8 gate on. Running `baseline` as well proves the unfinished pages' content is untouched.

### S2 — fixture realities

The JSON API is not usable (no `/api/auth/**` controller; the `jwt` cookie is never written), the CSRF token
is BREACH-masked and must be re-read from a rendered form because authentication clears the cookie, and
reservation status is stored as the enum `valor` (`Solicitado`), not the enum name. Details in the evidence
log.
