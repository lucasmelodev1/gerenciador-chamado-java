# infrastructure/security

- `JwtService.java`: emite e valida JWT (`api.security.token.secret`).
- `JwtAuthenticationFilter.java`: lê o JWT do cookie `jwt` e popula o `SecurityContext`.
- `adapter/UserDetailsImpl.java`: adapta `Usuario` para `UserDetails`.
