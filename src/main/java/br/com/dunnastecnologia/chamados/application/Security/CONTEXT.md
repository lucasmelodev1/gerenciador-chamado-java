# application/Security

- `AuthenticatedUser.java`: record `(UUID id, String username, String role)` do usuário autenticado; username é o e-mail e role segue `ROLE_*`. Os controllers o montam e os services validam o perfil com `infrastructure/service/support/AuthenticatedUserValidator`.
