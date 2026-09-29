# application/pagination

Paginação desacoplada do Spring Data.

- `PageRequest.java`: record `(page, size, sortBy, direction)`.
- `PageResult.java`: record `(content, totalElements, totalPages, page, size)`, convertido por `infrastructure/service/support/PageResultMapper`.
