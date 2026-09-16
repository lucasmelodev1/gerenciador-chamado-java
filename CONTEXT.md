# Gerenciador de Chamados

Sistema de gestão de chamados para condomínios. Backend em Spring Boot 4 (Java 21) empacotado como WAR, com frontend server-side em JSP/JSTL. Arquitetura em camadas: `application` (portas/use cases), `domain` (entidades) e `infrastructure` (adaptadores web, persistência, segurança). PostgreSQL via JPA/Hibernate e Flyway.

## Documentos
- `AGENTS.md`: regras de trabalho do projeto.
- `STANDARDS.md`: padrões de código (nomenclatura, camadas, persistência, testes e formatação).
- `ESPECIFICACAO.md`: decisões de uso de IA e validação.
- `diagrama-relacional.drawio.svg`: modelo de dados.

## Comandos
- Ambiente local: `docker compose up --build` (app em http://localhost:8080).
- Build: `./mvnw clean package`.
- Testes: `./mvnw test`.

## Configuração
- `pom.xml`: dependências (Spring Boot, Security, JPA, Flyway, Jasper/JSTL, JJWT, springdoc, PostgreSQL, Lombok).
- `src/main/resources/application.properties`: datasource, Flyway, upload de 5MB, bootstrap de admin, scheduler de atraso.
- `.env` / `.env.example`: variáveis usadas pelo `docker-compose.yml`.
- `Dockerfile` / `docker-compose.yml`: build multi-stage e ambiente local.

## Índice de CONTEXT.md
- Código da aplicação: `src/main/java/br/com/dunnastecnologia/chamados/CONTEXT.md`
- Migrations/DB: `src/main/resources/db/migration/CONTEXT.md`
- Views JSP: `src/main/webapp/WEB-INF/jsp/CONTEXT.md`
- Assets estáticos: `src/main/resources/static/CONTEXT.md`
- Testes: `src/test/java/br/com/dunnastecnologia/chamados/CONTEXT.md`
