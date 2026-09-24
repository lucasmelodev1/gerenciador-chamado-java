# Plano: CRUD de Áreas (API)

## Git

- **Origem:** `main`
- **Destino:** `feat/cadastro-area` (branch já existente, worktree atual)
- **Observação:** `git checkout -b feat/cadastro-area main` não é executado porque a branch já existe localmente e em `origin`. Trabalhamos no worktree atual.

## Escopo confirmado

- CRUD completo do `AreaUseCase`.
- Somente API: sem JSP, sem link na sidebar, sem página GET em `AdminWebController`.
- Nome **não** precisa ser único.
- `status` com default `Ativo`.
- `removerArea` é soft delete (`@SoftDelete`, coluna `deleted_at`).
- Cobertura atual (`AreaApiIntegrationTest`) é suficiente; sem testes novos.
- Sem dependências novas.

## Estado atual

Já existentes (WIP na branch): `Area`, `StatusArea`, `StatusAreaConverter`, `AreaRepository`,
`AreaUseCase`, `V19__area.sql`, `AreaApiController`, `AreaForm`, `AreaApiIntegrationTest` e
atualizações parciais de CONTEXT.md.

Pendente/broken: `AreaService` lança `UnsupportedOperationException` em todos os métodos e
`AreaApiController` quebra quando `status` é nulo/blank (`StatusArea.fromValor(null)`).

## Arquivos a alterar

### 1. `src/main/java/br/com/dunnastecnologia/chamados/infrastructure/service/AreaService.java`

Implementar os 5 métodos:

- `cadastrarArea(AuthenticatedUser admin, String nome, StatusArea status)`
  - `authenticatedUserValidator.assertAdministrador(admin)`.
  - Normalizar `nome` com `InputValidationSupport.normalizeRequiredText` usando
    `ValidationLimits.AREA_NOME_MAX_LENGTH` (mensagens: obrigatório / máximo 255).
  - `status` nulo → `StatusArea.ATIVO`.
  - `areaRepository.save(area)`.
- `listarAreas(PageRequest pageRequest)`
  - `PageResultMapper.fromPage(areaRepository.findAll(pageRequest))`.
- `buscarAreaPorId(UUID areaId)`
  - `areaRepository.findById(areaId)` ou `ResourceNotFoundException("Area nao encontrada")`.
- `atualizarArea(AuthenticatedUser admin, UUID areaId, String nome, StatusArea status)`
  - `assertAdministrador`; buscar área; normalizar `nome`; `status` nulo → `ATIVO`; `save`.
- `removerArea(AuthenticatedUser admin, UUID areaId)`
  - `assertAdministrador`; buscar área; `areaRepository.delete(area)` (soft delete via Hibernate).

Motivo: único ponto que impede o fluxo e os testes existentes de funcionarem.

### 2. `src/main/java/br/com/dunnastecnologia/chamados/infrastructure/controller/api/AreaApiController.java`

- Normalizar status no `POST` (cadastrar) e `PATCH` (atualizar): quando nulo/blank usar
  `StatusArea.ATIVO`; caso contrário `StatusArea.fromValor`.
- Motivo: atender o default `Ativo` e evitar `IllegalArgumentException` indesejado.

### 3. `src/main/java/br/com/dunnastecnologia/chamados/infrastructure/service/CONTEXT.md`

- Atualizar a linha do `AreaService` (deixou de ser esqueleto).

### 4. `src/main/java/br/com/dunnastecnologia/chamados/application/UserCase/CONTEXT.md`

- Remover a observação "implementação funcional ainda pendente" do `AreaUseCase`.

## Fora de escopo / não alterar

- `V19__area.sql`: sem constraint de unicidade.
- `AreaRepository`, `Area`, `StatusArea`, `StatusAreaConverter`: já atendem.
- `AdminWebController`, JSPs, `sidebar.jspf`, `WebControllerSupport`: sem mudanças.

## Premissa

- Leitura (`listarAreas` / `buscarAreaPorId`) exposta apenas via use case (usada pelos testes),
  sem endpoint HTTP GET, pois não haverá página JSP nem camada REST JSON.

## Validação

- Rodar `docker compose run --rm test` (ou `./mvnw test` com o banco acessível) para validar
  `AreaApiIntegrationTest` (cadastro, listagem, atualização, remoção/soft delete e não encontrado).
