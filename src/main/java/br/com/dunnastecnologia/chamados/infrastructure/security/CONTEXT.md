# infrastructure/security

Componentes de autenticação e autorização.

## Arquivos
- `JwtService.java`: gera e valida tokens JWT (subject = e-mail, expiração de 24h, segredo em `api.security.token.secret`).
- `JwtAuthenticationFilter.java`: `OncePerRequestFilter` que extrai o JWT do cookie `jwt` e popula o `SecurityContext`.
- `adapter/UserDetailsImpl.java`: adapta `Usuario` para `UserDetails`; `getAuthorities()` converte a role do domínio.

## Relacionados
- `../config/SecurityConfig.java`
- `../../application/Security/CONTEXT.md`
- `../service/AuthenticationService.java`
