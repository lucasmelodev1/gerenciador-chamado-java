# application/pagination

Tipos de paginação da camada de aplicação, desacoplados do `Page` do Spring Data.

## Arquivos
- `PageRequest.java`: record `(int page, int size, String sortBy, String direction)`.
- `PageResult.java`: record `(List<T> content, long totalElements, int totalPages, int page, int size)`.

## Relacionados
- `../UserCase/CONTEXT.md`
- `../../infrastructure/service/support/PageResultMapper.java`
