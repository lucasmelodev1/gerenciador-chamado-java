# src/main/resources/db/migration

Migrations Flyway do PostgreSQL. Dividem-se em estrutura (tabelas/índices/colunas) e funções PL/pgSQL que concentram regras de autorização e consultas usadas pelos repositórios.

## Estrutura
- `V1__init.sql`: tabelas base (usuários, perfis, blocos, unidades, morador_unidade, tipos/status, chamados, comentários) e índices.
- `V7__status_default_flag.sql`: flag de status inicial padrão.
- `V8__anexos_chamado.sql` / `V15__anexos_comentario.sql`: anexos (metadados + binário).
- `V12__soft_delete_usuarios.sql`: coluna `ativo` para exclusão lógica.
- `V16__input_validation_limits.sql`: restrições de tamanho de campos e anexos (5MB).

## Funções e consultas
- `V2__morador_authorization_functions.sql`: permissões/assertivas do morador e listagem.
- `V3__admin_business_functions.sql`: autorização do admin, geração automática de unidades e consulta de chamados.
- `V4__colaborador_business_functions.sql`: escopo, permissão de atendimento e consultas do colaborador.
- `V5__repository_query_functions.sql`: buscas de detalhe e listagens de apoio aos repositories.
- `V6__chamado_visibility_rules.sql`: consolida regras de visibilidade por perfil.
- `V9`/`V10`/`V11`/`V13`/`V17`/`V18`: evoluções de filtros (morador, tipo/unidade, data/antiguidade) e escopo do colaborador por tipo.
- `V14__status_atrasado.sql`: status `Atrasado` por SLA.

## Convenções
- Chamadas pelos métodos nativos dos repositórios em `infrastructure/repository`.
- Ao mudar assinatura de função, a migration remove a versão anterior antes de recriar.
