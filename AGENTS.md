# AGENTS.md

Apartment complex management system (Condominium Tickets & Common Area Reservations).

## Core Rules & Workflow
- Limit edits strictly to relevant files. Never refactor unless asked. Do not touch `ESPECIFICACAO.md`.
- Language: Brazilian Portuguese for code, identifiers, and UI messages; technical terms in English (`PageRequest`, `repository`, etc.).
- Testing: All new features need E2E tests. Sensitive/API flows need integration tests (`@SpringBootTest`). Security and calculations need unit tests (JUnit 5 + Mockito). Run via `docker compose run --rm test`.

## Architecture & Layers
- `application/UserCase/`: Use-case facades (`AreaUseCase`, `SolicitacaoAreaUseCase`, `ChamadoUseCase`, `UsuarioUseCase`, etc.). Methods named by intent in Portuguese (`solicitarReserva`, `aprovarReserva`).
- `application/Security/` & `pagination/`: Models (`AuthenticatedUser`, `PageRequest`, `PageResult`).
- `domain/model/`: JPA entities (`Usuario`, `Administrador`, `Colaborador`, `Morador`, `Bloco`, `Unidade`, `Chamado`, `Comentario`, `Anexos`, `Area`, `SolicitacaoArea`). Lombok `@Getter/@Setter`, `@ManyToOne(fetch = LAZY)`, UUID IDs.
- `domain/validation/`: Field limits in `ValidationLimits`. Required text normalized with `InputValidationSupport`.
- `infrastructure/controller/`:
  - `web/`: GET endpoints rendering JSP views (`/admin/**`, `/colaborador/**`, `/morador/**`, `/auth/**`).
  - `api/`: Mutations (POST/PATCH/DELETE) receiving `Form` POJOs, returning `redirect:` with flash messages.
- `infrastructure/service/`: Business rules implementing `UserCase` (`@Service`, `@Transactional(readOnly = true)`).
  - Always constructor injection; never `@Autowired` on fields.
  - Defense-in-depth: `@PreAuthorize` on controllers + `AuthenticatedUserValidator` checks in services.
  - Throw domain exceptions only (`BusinessRuleException`, `ResourceNotFoundException`, `UnauthorizedOperationException`).
- `infrastructure/repository/`: Spring Data JPA repositories (`JpaRepository<T, UUID>`). Complex filters in PL/pgSQL via `nativeQuery`. Soft delete via `ativo` column or `deletado_em`.
- `infrastructure/security/`: Spring Security + JWT cookie (`/api/**`) and session + CSRF cookie (`/`). Passwords hashed with BCrypt.
- `src/main/resources/db/migration/`: Flyway migrations (`V1` to `V21`). Schema is strictly owned by Flyway (`ddl-auto=validate`).
- `src/main/resources/static/`: Compiled Tailwind/DaisyUI CSS (`app.css`, `custom.css`), vanilla JS, FullCalendar.
- `src/main/webapp/WEB-INF/`: JSP templates under `jsp/` and reusable custom tags under `tags/` (`ui:shell`, `ui:painel`, `ui:dialog`, `ui:drawer`).

## Key Business & Technical Concepts
- **Roles:** `ROLE_ADMINISTRADOR`, `ROLE_COLABORADOR`, `ROLE_MORADOR`. Colaborador has no access to reservations.
- **Chamados:** Standard initial status, SLA overdue tracked by background scheduler, comment & attachment history.
- **Reservations:** Lifecycle `SOLICITADA` -> `APROVADA` / `NEGADA` / `CANCELADA`.
  - Exclusion constraint via PostgreSQL `btree_gist` prevents overlapping `[inicio, fim)` intervals for approved reservations.
  - Negation requires non-empty justification (`motivo_negacao`). Cancellation only allowed before start time.
  - Consistent timezone across app and DB (`APP_TIMEZONE`).

## Code Standards, Build & Environment
- 4 spaces indentation, K&R braces, no wildcard imports, ~120 chars line width. No inline comments in method bodies.
- Java 21, Spring Boot 4 (WAR), PostgreSQL 16. App config uses `app.*` prefix and `${ENV_VAR:default}` in `application.properties`.
- Local run: `docker compose up --build`. Secrets and config loaded exclusively via `.env`.
