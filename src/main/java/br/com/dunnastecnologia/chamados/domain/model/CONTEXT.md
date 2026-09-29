# domain/model

Entidades JPA (schema criado pelo Flyway); herança de usuários é `JOINED` sobre `usuarios`.

- `Usuario.java` (abstrata) + `Administrador.java`, `Colaborador.java`, `Morador.java`: perfis e `getRole()`.
- `Bloco.java`, `Unidade.java`: estrutura física.
- `TipoChamado.java`, `StatusChamado.java`, `Chamado.java`, `Comentario.java`, `AnexoChamado.java`, `AnexoComentario.java`: fluxo de chamados.
- `Area.java`, `StatusArea.java`/`StatusAreaConverter.java`: áreas comuns (`Ativo`/`Inativo`).
- `SolicitacaoArea.java`, `StatusSolicitacaoArea.java`/`StatusSolicitacaoAreaConverter.java`: reservas (`Solicitado`/`Aprovado`/`Negado`/`Cancelado`).
- Áreas e reservas usam exclusão lógica (`@SoftDelete`, coluna `deleted_at`).
