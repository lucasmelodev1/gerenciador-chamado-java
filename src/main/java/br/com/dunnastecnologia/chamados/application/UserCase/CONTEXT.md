# application/UserCase

Interfaces (portas) dos casos de uso do sistema. São implementadas em `infrastructure/service` e chamadas pelos controllers. Os métodos recebem `AuthenticatedUser` quando há regra de autorização e retornam modelos de domínio ou `PageResult`.

## Interfaces
- `AdminUseCases.java`: operações do administrador (blocos, unidades, usuários, vínculos, tipos/status de chamado, chamados e comentários). Agrega os demais use cases.
- `ChamadoUseCase.java`: abertura, listagem/detalhe por perfil (admin, colaborador, morador), atualização de status e reabertura.
- `MoradorUseCases.java`: unidades do morador, abertura/listagem/detalhe dos próprios chamados, comentário e reabertura.
- `ColaboradorUseCases.java`: status/tipos disponíveis, fila de chamados no escopo, detalhe, atualização de status e comentário.
- `ComentarioUseCase.java`: comentar e listar comentários de um chamado.
- `AnexoChamadoUseCases.java`: adicionar/listar/baixar anexos do chamado (records `AnexoChamadoInfo`/`AnexoChamadoConteudo`).
- `AnexoComentarioUseCases.java`: adicionar/baixar anexos de comentário (records `AnexoComentarioInfo`/`AnexoComentarioConteudo`).
- `UsuarioUseCase.java`: CRUD de usuários e vínculos morador-unidade / colaborador-tipo.
- `TipoChamadoUseCase.java`: cadastro, listagem, busca e atualização de tipos de chamado.
- `StatusChamadoUseCase.java`: cadastro, listagem, busca, atualização e definição do status inicial padrão.

## Relacionados
- `../Security/CONTEXT.md`, `../pagination/CONTEXT.md`
- `../../infrastructure/service/CONTEXT.md` (implementações)
