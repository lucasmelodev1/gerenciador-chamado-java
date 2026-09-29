# integration/controller/web

Slices `@WebMvcTest` + `MockMvc` com `@MockitoBean` nos use cases: rotas, autorização por perfil, view renderizada e redirects.

- `AdminWebControllerIntegrationTest.java`, `ColaboradorWebControllerIntegrationTest.java`, `MoradorWebControllerIntegrationTest.java`, `AuthAndHomeWebControllerIntegrationTest.java`.
- `WebTestAuthenticationFactory.java`: cria `Authentication` e o `RequestPostProcessor autenticacao(...)` (filtros desabilitados).
- Os slices precisam declarar `@MockitoBean JwtService`, pois o filtro JWT entra no slice.
