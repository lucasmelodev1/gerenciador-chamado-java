# infrastructure/config

- `SecurityConfig.java`: três `SecurityFilterChain` (estáticos/OpenAPI, `/api/**` stateless com JWT, web com sessão + CSRF), `PasswordEncoder` BCrypt e CORS.
- `AdminBootstrapConfig.java`: garante os status iniciais e cria o admin inicial (`app.bootstrap.admin.*`).
- `JspViewConfig.java`: `ViewResolver` para `/WEB-INF/jsp/*.jsp`.
- `OpenApiConfig.java`: metadados e agrupamento do springdoc.
