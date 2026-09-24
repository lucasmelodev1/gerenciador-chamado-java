# Testes

Estratégia de testes do sistema. Regras em `AGENTS.md`: toda funcionalidade tem teste E2E; fluxos sensíveis/de integração têm teste de integração (API); segurança e cálculos complexos têm teste unitário.

## Estrutura
- `unit/`: testes unitários com JUnit + Mockito (`@ExtendWith(MockitoExtension.class)`).
  - `unit/service/CONTEXT.md`
  - `unit/config/AdminBootstrapConfigTest.java`
- `integration/`: testes de integração.
  - `integration/support/CONTEXT.md` (`IntegrationTestSupport`: contexto + utilitários)
  - `integration/controller/web/CONTEXT.md` (MockMvc + `@WebMvcTest`)
  - `integration/controller/api/CONTEXT.md` (`@SpringBootTest` + MockMvc, E2E dos endpoints de mutação)
  - `integration/repository/ChamadoRepositoryIntegrationTest.java` (`@SpringBootTest` transacional sobre PostgreSQL)

## Banco de dados
- Os testes de integração usam o banco PostgreSQL dedicado da suíte (`TEST_DB_NAME`, padrão `gerenciador_chamados_test`), criado no container `db` e migrado pelo Flyway.
- Suba a suíte pelo compose: `docker compose run --rm test` (serviço `test`, depende de `db` saudável).

## Comando
- `./mvnw test` (requer o banco acessível na URL configurada em `application.properties`).
