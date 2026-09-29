# infrastructure/service

Implementações dos use cases (`@Service`/`@Transactional`); concentram regra de negócio e orquestram repositórios.

- `AdminService.java`, `UsuarioService.java`, `TipoChamadoService.java`, `StatusChamadoService.java`: cadastros e vínculos do admin.
- `ChamadoService.java`, `MoradorService.java`, `ColaboradorService.java`, `ComentarioService.java`, `AnexoChamadoService.java`, `AnexoComentarioService.java`: ciclo dos chamados por perfil.
- `AreaService.java`, `SolicitacaoAreaService.java`: áreas comuns e reservas (disponibilidade, conflito de intervalos, estados e histórico).
- `AuthenticationService.java`, `ChamadoAtrasoScheduler.java`: login e SLA.
- Comparações de data/hora usam `LocalDateTime.now()` no servidor, com o timezone do container (`APP_TIMEZONE`/`TZ`).
