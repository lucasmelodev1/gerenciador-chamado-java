# infrastructure/repository

Interfaces Spring Data JPA; parte das consultas chama funções PL/pgSQL das migrations (visibilidade por perfil no banco).

- `ChamadoRepository.java`: listagens/detalhe por perfil e `marcarChamadosAtrasados()`.
- `UsuarioRepository.java`, `AdministradorRepository.java`, `ColaboradorRepository.java`, `MoradorRepository.java`: usuários, perfis ativos e vínculos.
- `BlocoRepository.java`, `UnidadeRepository.java`: estrutura física.
- `TipoChamadoRepository.java`, `StatusChamadoRepository.java`, `ComentarioRepository.java`, `AnexoChamadoRepository.java`, `AnexoComentarioRepository.java`: catálogos, comentários e anexos.
- `AreaRepository.java`, `SolicitacaoAreaRepository.java`: áreas comuns e reservas (disponibilidade, posse, pré-checagem de conflito e buscas por janela).
