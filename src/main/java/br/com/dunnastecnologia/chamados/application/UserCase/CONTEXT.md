# application/UserCase

Interfaces (portas) dos casos de uso, implementadas em `infrastructure/service`.

- `AdminUseCases.java`: operações do administrador; agrega os demais use cases.
- `ChamadoUseCase.java`, `MoradorUseCases.java`, `ColaboradorUseCases.java`, `ComentarioUseCase.java`: ciclo dos chamados por perfil.
- `AnexoChamadoUseCases.java`, `AnexoComentarioUseCases.java`: anexos (records de info/conteúdo).
- `UsuarioUseCase.java`: usuários e vínculos.
- `TipoChamadoUseCase.java`, `StatusChamadoUseCase.java`: catálogos.
- `AreaUseCase.java`: manutenção de áreas comuns.
- `SolicitacaoAreaUseCase.java`: reservas de áreas comuns (morador e admin, com listagens por janela para as agendas).
