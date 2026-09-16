# br.com.dunnastecnologia.chamados

Raiz do código da aplicação. Divide o sistema em `application` (contratos/portas), `domain` (modelo) e `infrastructure` (adaptadores).

## Arquivos
- `GerenciadorChamadosApplication.java`: entrypoint Spring Boot (`@EnableScheduling`); define o timezone default a partir de `APP_TIMEZONE`/`TZ`.
- `ServletInitializer.java`: ponto de entrada para deploy do WAR.

## Índice de CONTEXT.md
- `application/UserCase/`: interfaces (portas) dos casos de uso.
- `application/Security/`: contexto do usuário autenticado.
- `application/pagination/`: tipos de paginação da camada de aplicação.
- `domain/model/`: entidades JPA e tipos de domínio.
- `domain/validation/`: limites de validação compartilhados.
- `infrastructure/controller/web/`: controllers de páginas JSP.
- `infrastructure/controller/api/`: controllers de ações via formulário (POST/PATCH/DELETE).
- `infrastructure/controller/web/form/`: form objects dos controllers.
- `infrastructure/service/`: implementações dos use cases.
- `infrastructure/service/support/`: colaboradores dos services.
- `infrastructure/repository/`: interfaces Spring Data JPA.
- `infrastructure/security/`: JWT, filtro e adaptador de UserDetails.
- `infrastructure/config/`: configurações de segurança, views, OpenAPI e bootstrap.
- `infrastructure/exception/`: exceções de negócio e recursos.
