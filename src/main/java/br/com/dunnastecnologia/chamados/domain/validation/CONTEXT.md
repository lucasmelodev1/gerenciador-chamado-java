# domain/validation

Limites de validação compartilhados entre domínio e infraestrutura.

## Arquivos
- `ValidationLimits.java`: constantes de tamanho máximo de campos (255, incluindo `AREA_NOME_MAX_LENGTH`/`AREA_STATUS_MAX_LENGTH`) e limite de anexo (`ANEXO_TAMANHO_MAX_BYTES = 5MB`).

## Relacionados
- `../model/CONTEXT.md`
- `../../infrastructure/service/support/InputValidationSupport.java`
