# infrastructure/repository

Interfaces Spring Data JPA (`@Repository`). Parte das consultas delega para funções PL/pgSQL definidas nas migrations, garantindo as regras de visibilidade por perfil no banco.

## Repositórios
- `ChamadoRepository.java`: listagem/detalhe por perfil via funções nativas e `marcarChamadosAtrasados()` (SLA).
- `UsuarioRepository.java`: busca por e-mail ativo/soft delete e existência de administrador.
- `AdministradorRepository.java`, `ColaboradorRepository.java`, `MoradorRepository.java`: validação de usuário ativo por perfil e vínculos.
- `BlocoRepository.java`, `UnidadeRepository.java`: estrutura física e unidades por morador.
- `TipoChamadoRepository.java`, `StatusChamadoRepository.java`: catálogos (status inicial padrão).
- `ComentarioRepository.java`: comentários por chamado.
- `AnexoChamadoRepository.java`, `AnexoComentarioRepository.java`: anexos e conteúdo binário.

## Relacionados
- `../../resources/db/migration/CONTEXT.md` (funções e views)
- `../service/CONTEXT.md`
