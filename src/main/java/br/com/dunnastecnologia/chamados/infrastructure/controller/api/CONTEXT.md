# infrastructure/controller/api

Mutações (POST/PATCH/PUT/DELETE) que executam o use case e redirecionam; sem JSON apesar do nome. Protegidos por `@PreAuthorize`.

- `AdminChamadoApiController.java`, `ColaboradorChamadoApiController.java`, `MoradorChamadoApiController.java`: status, comentários e anexos do chamado.
- `BlocoApiController.java`, `UsuarioApiController.java`, `MoradorUnidadeApiController.java`, `ColaboradorTipoChamadoApiController.java`, `TipoChamadoApiController.java`, `StatusChamadoApiController.java`: cadastros e vínculos do admin.
- `AreaApiController.java`, `AdminSolicitacaoAreaApiController.java`, `SolicitacaoAreaApiController.java`: áreas comuns e reservas.
