# AGENTS.md

Condominium Tickets & Common Area Reservations Management System.

## 1. Core Rules & Guardrails
- Limit edits strictly to relevant files. Never refactor surrounding code unless requested.
- Do NOT modify `ESPECIFICACAO.md` or any existing Flyway migration (`V1` to `V21`).
- Never introduce H2 or in-memory DBs for tests; integration tests run against PostgreSQL.
- Language: Brazilian Portuguese for code, identifiers, and UI messages; technical terms in English (`PageRequest`, `repository`, etc.).
- Formatting: 4 spaces indentation, K&R braces, no wildcard imports, ~120 chars line width. No inline comments in method bodies.

## 2. Fast Verification & Commands
- Fast compile check: `./mvnw test-compile`
- Run single test: `docker compose run --rm test mvn test -Dtest=<TestClass>` (or `./mvnw test -Dtest=<TestClass>`)
- Run full test suite: `docker compose run --rm test`
- Build frontend CSS (required when new Tailwind classes are added): `npm run build:css`
- Local app run: `docker compose up --build`
- Secrets and config loaded exclusively via `.env`.

## 3. Architecture & Patterns
- `application/UserCase/`: Use-case facades (`AreaUseCase`, `SolicitacaoAreaUseCase`, `ChamadoUseCase`, `UsuarioUseCase`, etc.). Methods named by intent in Portuguese (`solicitarReserva`, `aprovarReserva`). Keep exact package name `UserCase`.
- `application/Security/` & `pagination/`: Records (`AuthenticatedUser`, `PageRequest`, `PageResult`).
- `domain/model/`: JPA entities (`Usuario`, `Administrador`, `Colaborador`, `Morador`, `Bloco`, `Unidade`, `Chamado`, `Comentario`, `AnexoChamado`, `AnexoComentario`, `Area`, `SolicitacaoArea`). Lombok `@Getter/@Setter`, `@ManyToOne(fetch = LAZY)`, UUID IDs.
  - Soft delete: `Usuario` uses `ativo = true/false`; `Area` and `SolicitacaoArea` use `@SoftDelete(strategy = SoftDeleteType.TIMESTAMP, columnName = "deleted_at")`.
- `domain/validation/`: Constants in `ValidationLimits`. Input normalized via `InputValidationSupport`.
- `infrastructure/controller/`:
  - `web/`: GET endpoints returning JSP view names (`/admin/**`, `/colaborador/**`, `/morador/**`, `/auth/**`).
  - `api/`: Mutations (POST/PATCH/DELETE) receiving `Form` POJOs, returning `redirect:` with flash messages (`successMessage`/`errorMessage`).
  - Forms are simple Lombok POJOs; do NOT use Bean Validation annotations on them (validation is done in services).
- `infrastructure/service/`: Business rules implementing `UserCase` (`@Service`, `@Transactional(readOnly = true)`).
  - Always constructor injection; never `@Autowired` on fields.
  - Defense-in-depth: `@PreAuthorize` on controllers + `AuthenticatedUserValidator` checks in services.
  - Throw domain exceptions only (`BusinessRuleException`, `ResourceNotFoundException`, `UnauthorizedOperationException`), handled by `WebExceptionHandler`.
- `infrastructure/repository/`: Spring Data JPA (`JpaRepository<T, UUID>`). Complex filters in PL/pgSQL via `nativeQuery`.
- `infrastructure/security/`: Spring Security + JWT cookie (`/api/**`) and session + CSRF cookie (`/`). Passwords hashed with BCrypt.
- `src/main/resources/db/migration/`: Flyway migrations. Schema strictly validated (`ddl-auto=validate`). Any schema change requires a new `V{N+1}__*.sql`.

## 4. Frontend & Views (JSP + Tailwind/DaisyUI)
- Every `.jsp`, `.jspf`, and `.tag` file containing non-ASCII text MUST start with:
  `<%@ page pageEncoding="UTF-8" %>` (Jasper defaults to ISO-8859-1; omitting this causes mojibake).
- Use custom tags under `WEB-INF/tags/` (`ui:shell`, `ui:shell-fim`, `ui:painel`, `ui:dialog`, `ui:drawer`, `ui:campo`, `ui:campo-senha`, `ui:tabela-chamados`, `ui:detalhe-chamado`, `ui:metrica`, `ui:paginacao`, `ui:vazio`, `ui:acao-form`, `ui:acao-painel`, `ui:badge`, `ui:card-head`). Do not hand-code raw form/table boilerplate.

## 5. Domain & Business Rules
- **Roles:** `ROLE_ADMINISTRADOR`, `ROLE_COLABORADOR`, `ROLE_MORADOR`. Colaborador has no access to reservations.
- **Chamados:** SLA overdue tracked by background scheduler (`ChamadoAtrasoScheduler`), comment & attachment history.
- **Reservations:** Lifecycle `SOLICITADO` -> `APROVADO` / `NEGADO` / `CANCELADO` (masculine form in enum and DB).
  - PostgreSQL `btree_gist` exclusion constraint prevents overlapping `[inicio, fim)` intervals for `APROVADO` reservations where `deleted_at IS NULL`.
  - Negation requires non-empty justification (`motivo_negacao`). Cancellation only allowed before start time.
  - Timezone handled uniformly via `APP_TIMEZONE`.

## 6. Testing Strategy
- **Flow & Integration Tests:** Sensitive/API flows must have integration tests extending `IntegrationTestSupport` (`@SpringBootTest` + MockMvc simulating full HTTP cycles against PostgreSQL).
- **Unit Tests:** Business logic, security validations, and date/SLA calculations covered by JUnit 5 + Mockito without Spring context.
