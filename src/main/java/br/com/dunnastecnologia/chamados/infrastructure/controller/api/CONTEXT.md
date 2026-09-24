# infrastructure/controller/api

Controllers de ações via formulário (POST/PATCH/PUT/DELETE) que executam operações e redirecionam. Apesar do nome "api", não retornam JSON; representam as mutações separadas dos controllers de páginas. Protegidos por `@PreAuthorize`.

## Controllers
- `AdminChamadoApiController.java`: atualizar status, comentar e baixar anexos do chamado (admin).
- `BlocoApiController.java`: cadastro de blocos.
- `UsuarioApiController.java`: cadastro/atualização/remoção de usuários.
- `MoradorUnidadeApiController.java`: vincular/desvincular unidade de morador.
- `ColaboradorTipoChamadoApiController.java`: vincular/desvincular tipo de chamado ao colaborador.
- `TipoChamadoApiController.java`: cadastro/atualização de tipos.
- `StatusChamadoApiController.java`: cadastro/atualização e status inicial padrão.
- `AreaApiController.java`: cadastro, atualização e remoção de áreas (admin); usa `AreaUseCase` diretamente; `status` ausente assume `Ativo` no cadastro e é preservado na atualização.
- `ColaboradorChamadoApiController.java`: atualizar status, comentar e baixar anexos do chamado (colaborador).
- `MoradorChamadoApiController.java`: abrir/reabrir chamado, comentar e anexos (morador).

## Relacionados
- `../web/CONTEXT.md` (páginas), `../web/form/CONTEXT.md`
