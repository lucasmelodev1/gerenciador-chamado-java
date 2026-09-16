# infrastructure/service/support

Colaboradores reutilizados pelos services para autorização, validação e mapeamento.

## Arquivos
- `AuthenticatedUserValidator.java`: verifica perfil (`@Component`) e existência de usuário ativo no repositório (`assertAdministrador`/`assertColaborador`/`assertMorador`).
- `ChamadoAccessSupport.java`: resolve o chamado acessível ao usuário conforme o perfil e garante que está em aberto.
- `InputValidationSupport.java`: normaliza texto obrigatório e valida tamanho máximo/bytes.
- `PageResultMapper.java`: converte `Page` do Spring Data em `application.pagination.PageResult`.

## Relacionados
- `../CONTEXT.md`
- `../../../domain/validation/CONTEXT.md`
