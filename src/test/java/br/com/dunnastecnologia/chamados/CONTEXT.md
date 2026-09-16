# Testes

Estratégia de testes do sistema. Regras em `AGENTS.md`: toda funcionalidade tem teste E2E; fluxos sensíveis/de integração têm teste de integração (API); segurança e cálculos complexos têm teste unitário.

## Estrutura
- `unit/`: testes unitários com JUnit + Mockito (`@ExtendWith(MockitoExtension.class)`).
  - `unit/service/CONTEXT.md`
  - `unit/config/AdminBootstrapConfigTest.java`
- `integration/`: testes de integração.
  - `integration/controller/web/CONTEXT.md` (MockMvc + `@WebMvcTest`)
  - `integration/repository/ChamadoRepositoryIntegrationTest.java` (`@DataJpaTest` com H2 em modo PostgreSQL)

## Comando
- `./mvnw test`
