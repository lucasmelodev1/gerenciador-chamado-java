# br.com.dunnastecnologia.chamados

Raiz do código da aplicação.

## Arquivos
- `GerenciadorChamadosApplication.java`: entrypoint Spring Boot; define o timezone default (`APP_TIMEZONE`/`TZ`).
- `ServletInitializer.java`: entrypoint do deploy WAR.

## Índice
- `application/`: `UserCase/` (portas dos casos de uso), `Security/` (`AuthenticatedUser`), `pagination/`.
- `domain/`: `model/` (entidades JPA), `validation/` (`ValidationLimits`).
- `infrastructure/controller/`: `web/` (páginas JSP), `api/` (mutações), `web/form/` (form objects).
- `infrastructure/service/`: implementações dos use cases e `support/`.
- `infrastructure/`: `repository/`, `security/`, `config/`, `exception/`.
