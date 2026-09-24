# integration/controller/web

Testes de integração web com `@WebMvcTest` + `MockMvc` e `@MockitoBean` nos use cases. Validam rotas, autorização por perfil, view renderizada e redirects dos controllers de páginas e de ações.

## Arquivos
- `AdminWebControllerIntegrationTest.java`: fluxos do administrador (blocos, áreas, usuários, vínculos, catálogos, chamados e anexos).
- `ColaboradorWebControllerIntegrationTest.java`: fila de atendimento e ações do colaborador.
- `MoradorWebControllerIntegrationTest.java`: abertura/listagem/detalhe, comentários e anexos do morador.
- `AuthAndHomeWebControllerIntegrationTest.java`: login e redirecionamento por perfil.
- `WebTestAuthenticationFactory.java`: cria `Authentication` de admin/colaborador/morador e o `RequestPostProcessor autenticacao(...)` que injeta principal na request e no `SecurityContextHolder` (filtros desabilitados).

## Convenções
- Os testes ficam no pacote `infrastructure.controller.web` para acessar utilitários e controllers.
- Os slices `@WebMvcTest` declaram `@MockitoBean JwtService` (o `JwtAuthenticationFilter` entra no slice e não encontra o service).
- Integração de repositório fica em `../../repository/ChamadoRepositoryIntegrationTest.java` (`@SpringBootTest` sobre o PostgreSQL da suíte, via `integration/support`).

## Relacionados
- `../../../CONTEXT.md`
