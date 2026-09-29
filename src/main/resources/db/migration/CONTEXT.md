# src/main/resources/db/migration

Migrations Flyway do PostgreSQL: estrutura e funções PL/pgSQL usadas pelos repositórios.

- `V1__init.sql`: tabelas base (usuários, perfis, blocos, unidades, chamados, comentários).
- `V7`, `V12`, `V14`, `V16`: status inicial padrão, soft delete de usuários, status `Atrasado`, limites de campo/anexo.
- `V8__anexos_chamado.sql`, `V15__anexos_comentario.sql`: anexos.
- `V19__area.sql`: tabela `areas`.
- `V20__solicitacoes_area.sql`: tabela `solicitacoes_area` com colunas de texto em `TEXT` (`status`, `motivo_negacao`), `CHECK (inicio < fim)`, `CHECK` de status e `EXCLUDE USING gist` (requer `btree_gist`) que impede reservas `Aprovado` sobrepostas da mesma área. Os limites de tamanho ficam na aplicação (`ValidationLimits` e entidades).
- `V21__solicitacoes_area_indice_morador.sql`: índice `(morador_id, inicio)`.
- `V2` a `V6` e `V9` a `V11`, `V13`, `V17`, `V18`: funções e filtros de autorização/visibilidade por perfil.
- Ao alterar assinatura de função, remover a versão anterior na mesma migration.
