# infrastructure/config

Configurações transversais da aplicação.

## Arquivos
- `SecurityConfig.java`: três `SecurityFilterChain` ordenados — estáticos/OpenAPI (permit all), `/api/**` (stateless + JWT) e web (sessão + CSRF por cookie + form login). Define `PasswordEncoder` (BCrypt), `AuthenticationProvider` e CORS.
- `AdminBootstrapConfig.java`: `CommandLineRunner` que garante os status `Solicitado`/`Finalizado`/`Atrasado`, define o status inicial padrão e cria o admin inicial (`app.bootstrap.admin.*`).
- `JspViewConfig.java`: `ViewResolver` para `/WEB-INF/jsp/*.jsp` usando JSTL.
- `OpenApiConfig.java`: metadados do springdoc e agrupamento dos endpoints web.

## Relacionados
- `../security/CONTEXT.md`
- `../../resources/application.properties`
