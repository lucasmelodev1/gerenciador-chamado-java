# Testes

Estratégia: E2E para toda funcionalidade, integração para fluxos sensíveis e unitário para segurança/cálculos (regras em `AGENTS.md`).

- `unit/service/`: JUnit + Mockito, sem contexto Spring.
- `unit/domain/model/`: converters/enums de status.
- `unit/config/AdminBootstrapConfigTest.java`.
- `integration/support/`: base compartilhada dos testes de integração.
- `integration/controller/web/`: slices `@WebMvcTest` + `MockMvc`.
- `integration/controller/api/`: E2E (`@SpringBootTest` + `MockMvc`), inclui `SolicitacaoAreaApiIntegrationTest` e `AreaApiIntegrationTest`.
- `integration/repository/`: `ChamadoRepositoryIntegrationTest`.

## Execução
- `docker compose run --rm test`: suíte completa (banco PostgreSQL da suíte, `TEST_DB_NAME`, criado no container `db`).
- `./mvnw test`: exige o banco acessível na URL de `application.properties`.
- Cobertura unitária das reservas, sem banco: `./mvnw -B clean verify -Dtest='SolicitacaoAreaServiceTest,AreaServiceTest,StatusAreaConverterTest,StatusSolicitacaoAreaConverterTest' -Dsurefire.failIfNoSpecifiedTests=false`. O JaCoCo mede só as classes de regra das reservas (`includes` no `pom.xml`); exclusões em `ESPECIFICACAO.md`.
