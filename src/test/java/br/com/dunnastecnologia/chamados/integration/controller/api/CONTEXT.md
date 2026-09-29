# integration/controller/api

E2E dos endpoints de mutação: `@SpringBootTest` + `MockMvc` sobre o PostgreSQL da suíte, com schema criado pelo Flyway.

- `SolicitacaoAreaApiIntegrationTest.java`: reservas de áreas comuns (solicitação, disponibilidade, aprovação/negação/cancelamento, visibilidade por perfil, agendas e aprovação simultânea com `CyclicBarrier`).
- `AreaApiIntegrationTest.java`: cadastro/manutenção de áreas e bloqueio de solicitação em área inativa.
