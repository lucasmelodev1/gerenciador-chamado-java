# infrastructure/service

Implementações das interfaces de `application/UserCase`. Concentram regra de negócio, validações e orquestração dos repositórios. Anotadas com `@Service`/`@Transactional`.

## Serviços
- `AdminService.java`: implementa `AdminUseCases`; delega para os demais services e repositórios de bloco/unidade/morador.
- `ChamadoService.java`: implementa `ChamadoUseCase`; abertura, listagem/detalhe por perfil, atualização de status e reabertura (finaliza e calcula atraso).
- `MoradorService.java`: implementa `MoradorUseCases`.
- `ColaboradorService.java`: implementa `ColaboradorUseCases`.
- `ComentarioService.java`: implementa `ComentarioUseCase`.
- `AnexoChamadoService.java` / `AnexoComentarioService.java`: implementam os use cases de anexos.
- `UsuarioService.java`: implementa `UsuarioUseCase`.
- `TipoChamadoService.java` / `StatusChamadoService.java`: implementam os catálogos.
- `AreaService.java`: implementa `AreaUseCase` (cadastro, listagem, busca, atualização e remoção com soft delete); leituras exigem administrador; `status` nulo assume `Ativo` no cadastro e é preservado na atualização.
- `AuthenticationService.java`: `UserDetailsService` que carrega usuário ativo por e-mail.
- `ChamadoAtrasoScheduler.java`: job agendado que marca chamados atrasados conforme SLA (controlado por `app.chamado.atraso.scheduler.*`).

## Relacionados
- `support/CONTEXT.md` (validadores e utilitários)
- `../repository/CONTEXT.md`, `../../application/UserCase/CONTEXT.md`
