# integration/controller/web

Testes de integração web com `@WebMvcTest` + `MockMvc` e `@MockitoBean` nos use cases. Validam rotas, autorização por perfil, view renderizada e redirects dos controllers de páginas e de ações.

## Arquivos
- `AdminWebControllerIntegrationTest.java`: fluxos do administrador (blocos, usuários, vínculos, catálogos, chamados e anexos).
- `ColaboradorWebControllerIntegrationTest.java`: fila de atendimento e ações do colaborador.
- `MoradorWebControllerIntegrationTest.java`: abertura/listagem/detalhe, comentários e anexos do morador.
- `AuthAndHomeWebControllerIntegrationTest.java`: login e redirecionamento por perfil.
- `WebTestAuthenticationFactory.java`: cria `Authentication` de admin/colaborador/morador para os testes.

## Convenções
- Os testes ficam no pacote `infrastructure.controller.web` para acessar utilitários e controllers.
- Integração de repositório fica em `../../repository/ChamadoRepositoryIntegrationTest.java` (`@DataJpaTest`).

## Relacionados
- `../../../CONTEXT.md`
