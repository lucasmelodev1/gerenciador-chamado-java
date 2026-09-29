# infrastructure/audit

Auditoria com Hibernate Envers (dependência `hibernate-envers`, versão gerenciada pelo Spring Boot).

- `Revisao.java`: entidade de revisão (`@RevisionEntity`) mapeada em `revinfo`; guarda `id`, `timestamp` (epoch) e snapshot do ator (`usuarioId`, `usuarioEmail`, `usuarioRole`).
- `RevisaoListener.java`: preenche o snapshot a partir do `SecurityContextHolder`; ações sem autenticação (bootstrap, login, scheduler) ficam com ator nulo (sistema).

Escopo inicial: `Area` e `SolicitacaoArea` (`@Audited`). Associações para entidades não auditadas usam `targetAuditMode = NOT_AUDITED` (grava só a FK). As tabelas `_aud` e `revinfo` são criadas por migration (V22), não pelo Hibernate.
