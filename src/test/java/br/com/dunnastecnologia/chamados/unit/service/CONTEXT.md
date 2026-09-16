# unit/service

Testes unitários dos services com JUnit 5 + Mockito (`@ExtendWith(MockitoExtension.class)`), sem contexto Spring. Cobrem regras de negócio, validações e caminhos de exceção.

## Arquivos
- `ChamadoServiceTest.java`: abertura, atualização de status, reabertura e cálculo de atraso.
- `AnexoChamadoServiceTest.java` / `AnexoComentarioServiceTest.java`: anexos e validações de tamanho.
- `ComentarioServiceTest.java`, `StatusChamadoServiceTest.java`, `UsuarioServiceTest.java`.
- `AuthenticationServiceTest.java`: carregamento de usuário ativo.
- `ChamadoAtrasoSchedulerTest.java`: acionamento do job de atraso.

## Convenções
- O pacote de teste replica o pacote do service em `infrastructure/service`.
- `unit/config/AdminBootstrapConfigTest.java` cobre o bootstrap de admin/status.

## Relacionados
- `../../../CONTEXT.md`
- `../../../../../../main/java/br/com/dunnastecnologia/chamados/infrastructure/service/CONTEXT.md`
