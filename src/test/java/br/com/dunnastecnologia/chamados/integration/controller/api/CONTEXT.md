# integration/controller/api

Testes E2E dos endpoints de mutação (`controller/api`) com `@SpringBootTest` + `MockMvc` sobre o banco PostgreSQL dedicado da suíte (`gerenciador_chamados_test`), com schema criado pelo Flyway. O `AreaUseCase` real é injetado para conferir o resultado persistido pela própria busca por id.

## Arquivos
- `AreaApiIntegrationTest.java`: cadastro (inclusive status padrão), listagem, atualização (inclusive preservação de status), remoção com soft delete, validações (nome vazio/acima do limite e status inválido) e negação para não-admin. Estende `integration/support/IntegrationTestSupport`, usa `@Transactional` (rollback por teste) e `autenticacao(...)` para injetar o admin no MockMvc.

## Convenções
- Herda a configuração de contexto e a autenticação de admin de `IntegrationTestSupport`.
- Dados únicos por teste (sufixo `UUID`) para não dependerem de estado externo.

## Relacionados
- `../../../CONTEXT.md`
- `../../support/CONTEXT.md`
- `../../../../../../../main/java/br/com/dunnastecnologia/chamados/infrastructure/controller/api/CONTEXT.md`
