# integration/support

Base dos testes de integração.

- `IntegrationTestSupport.java`: `@SpringBootTest` + `@AutoConfigureMockMvc(addFilters = false)`, repositórios injetados, helpers `autenticarComo*`, `criarReservaDireta(...)` e `autenticacao(...)` (injeta o principal na request e no `SecurityContextHolder`, necessário com filtros desabilitados).
- Sobe o schema real via Flyway no banco PostgreSQL da suíte.
