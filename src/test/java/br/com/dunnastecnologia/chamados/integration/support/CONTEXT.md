# integration/support

Base compartilhada dos testes de integração. Centraliza a configuração do contexto Spring e utilitários de dados/autenticação reutilizados por todos os testes de integração.

## Arquivos
- `IntegrationTestSupport.java`: classe abstrata com `@SpringBootTest` + `@AutoConfigureMockMvc(addFilters = false)`, `MockMvc`/`UsuarioRepository` injetados, `autenticarComoAdministrador()`, `authenticatedUser(Authentication)` e `autenticacao(Authentication)` (injeta o principal na request e no `SecurityContextHolder`, necessário com filtros desabilitados).

## Convenções
- Contexto sobe o schema real via Flyway no banco PostgreSQL da suíte (`gerenciador_chamados_test`).
- Novos utilitários só entram conforme necessidade explícita de outro teste de integração.

## Relacionados
- `../../../CONTEXT.md`
- `../controller/api/CONTEXT.md`
