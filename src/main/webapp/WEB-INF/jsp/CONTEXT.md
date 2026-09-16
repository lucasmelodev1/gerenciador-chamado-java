# src/main/webapp/WEB-INF/jsp

Views JSP/JSTL renderizadas pelos controllers de `infrastructure/controller/web`. Prefixo/sufixo configurados em `application.properties`. Os fragmentos (`fragments/`) são incluídos por todas as páginas.

## Estrutura
- `fragments/`: `taglibs.jspf` (taglibs e `ctx`), `head.jspf` (CSS), `topbar.jspf`, `sidebar.jspf` (navegação por perfil), `alerts.jspf`, `scripts.jspf`, `csrf.jspf`.
- `auth/`: `login.jsp`.
- `admin/`: `dashboard.jsp`, `blocos/`, `chamados/`, `escopo-colaborador/`, `status-chamado/`, `tipos-chamado/`, `usuarios/`, `vinculos-morador/`.
- `colaborador/`: `dashboard.jsp` e `chamados/`.
- `morador/`: `dashboard.jsp` e `chamados/` (`lista`, `novo`, `detalhe`).

## Convenções
- Os controllers enviam mapas prontos (via `WebControllerSupport`) e metadados de paginação.
- Atributos comuns (`appName`, `currentUser*`, flags de perfil) vêm de `WebModelAttributeAdvice`.

## Relacionados
- `../../resources/static/CONTEXT.md` (CSS/JS)
- `../../java/br/com/dunnastecnologia/chamados/infrastructure/controller/web/CONTEXT.md`
