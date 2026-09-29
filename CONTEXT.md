# Gerenciador de Chamados

Backend Spring Boot 4 (Java 21, WAR) com views JSP/JSTL e PostgreSQL via JPA/Flyway. Camadas: `application` (portas), `domain` (modelo), `infrastructure` (adaptadores). Regras em `AGENTS.md`, padrões em `STANDARDS.md`.

## Documentos
- `ESPECIFICACAO.md`: decisões, uso de IA e evidências de cobertura.
- `diagrama-relacional.drawio.svg`: modelo de dados.

## Comandos
- `docker compose up --build`: ambiente local (http://localhost:8080).
- `./mvnw clean package`: build.
- `docker compose run --rm test`: suíte completa (PostgreSQL do container `db`).
- Cobertura unitária das reservas: comando em `src/test/java/br/com/dunnastecnologia/chamados/CONTEXT.md`.
- Volume `postgres_data` sem o banco de testes: `docker compose down -v` uma vez.

## Configuração
- `pom.xml` (dependências e JaCoCo), `application.properties`, `.env`/`.env.example`, `Dockerfile`/`docker-compose.yml`.

## Índice
- `src/main/java/br/com/dunnastecnologia/chamados/`: código da aplicação.
- `src/main/resources/db/migration/`: migrations Flyway.
- `src/main/webapp/WEB-INF/jsp/`: views JSP.
- `src/main/resources/static/`: CSS/JS.
- `src/test/java/br/com/dunnastecnologia/chamados/`: testes.
