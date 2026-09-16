# domain/model

Entidades JPA e tipos de domínio mapeados na tabela do banco (Flyway). Herança de usuários é `JOINED` sobre `usuarios`.

## Entidades
- `Usuario.java`: classe base abstrata (`id`, `nome`, `email`, `senha`, `ativo`); método abstrato `getRole()`.
- `Administrador.java`, `Colaborador.java`, `Morador.java`: subtipos de `Usuario` com a role correspondente.
- `Bloco.java`: estrutura física; origem da geração automática de unidades.
- `Unidade.java`: apartamento gerado a partir de bloco, andar e identificação.
- `TipoChamado.java`: catálogo de tipos com `prazoHoras` (SLA).
- `StatusChamado.java`: status do fluxo e flag `inicialPadrao`.
- `Chamado.java`: ocorrência com descrição, datas, morador, unidade, tipo e status.
- `Comentario.java`: histórico textual do chamado.
- `AnexoChamado.java` e `AnexoComentario.java`: metadados e conteúdo binário de anexos.

## Relacionados
- `../validation/CONTEXT.md` (limites de tamanho usados nas colunas)
- `../../infrastructure/repository/CONTEXT.md`
