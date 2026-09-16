# infrastructure/controller/web

Controllers MVC que renderizam páginas JSP. Cada perfil tem seu controller, protegido por `@PreAuthorize`. As mutações (POST/PATCH/DELETE) ficam em `../api`.

## Controllers
- `HomeWebController.java`: redireciona para login ou para o painel do perfil.
- `AuthWebController.java`: exibe a tela de login (`auth/login.jsp`).
- `AdminWebController.java`: páginas de blocos, usuários, vínculos, escopo, catálogos e chamados do administrador.
- `ColaboradorWebController.java`: dashboard e fila de atendimento.
- `MoradorWebController.java`: dashboard, listagem, abertura e detalhe de chamados.
- `WebControllerSupport.java`: `@Component` com conversão de `Authentication` em `AuthenticatedUser`, paginação, mapas para a view, upload/download e rótulos de perfil.
- `WebExceptionHandler.java`: `@ControllerAdvice` que trata exceções conhecidas redirecionando com `errorMessage`.
- `WebModelAttributeAdvice.java`: `@ControllerAdvice` que injeta `appName` e atributos do usuário no model.

## Relacionados
- `api/CONTEXT.md` (mutações), `form/CONTEXT.md` (form objects)
- `../../../application/UserCase/CONTEXT.md`
