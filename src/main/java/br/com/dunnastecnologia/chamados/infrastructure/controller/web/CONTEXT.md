# infrastructure/controller/web

Controllers MVC que renderizam JSP; um por perfil, com `@PreAuthorize`. Mutações ficam em `../api`.

- `HomeWebController.java`, `AuthWebController.java`: redirecionamento por perfil e login.
- `AdminWebController.java`, `ColaboradorWebController.java`, `MoradorWebController.java`: páginas de chamados e cadastros de cada perfil.
- `AdminSolicitacaoAreaWebController.java`, `MoradorSolicitacaoAreaWebController.java`: lista, agenda/calendário, formulário de reserva (com escolha de unidade) e consulta de disponibilidade.
- `WebControllerSupport.java`: apoio (autenticação, paginação, mapas de view, período da agenda, upload/download).
- `WebExceptionHandler.java`, `WebModelAttributeAdvice.java`: tratam exceções conhecidas e injetam atributos comuns no model.
