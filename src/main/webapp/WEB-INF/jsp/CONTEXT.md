# src/main/webapp/WEB-INF/jsp

Views JSP/JSTL dos controllers web; prefixo/sufixo em `application.properties`.

- `fragments/`: `taglibs`, `head`, `topbar`, `sidebar`, `alerts`, `scripts`, `csrf` e `reservas-agenda.jspf` (calendário compartilhado entre admin e morador).
- `auth/`: `login.jsp`.
- `morador/`, `admin/`, `colaborador/`: páginas por perfil (`chamados/`, `reservas/`, cadastros do admin).
- Os controllers enviam mapas prontos (`WebControllerSupport`); atributos comuns vêm de `WebModelAttributeAdvice`.
