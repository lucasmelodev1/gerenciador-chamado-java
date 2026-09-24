# infrastructure/controller/web/form

Form objects (Lombok `@Getter`/`@Setter`) usados como `@ModelAttribute` nos controllers web e de ações. Sem validação por anotações; os limites são aplicados nos services.

## Formulários
- `AbrirChamadoForm.java`: `unidadeId`, `tipoChamadoId`, `descricao`.
- `AtualizarStatusForm.java`: atualização de status do chamado.
- `BlocoForm.java`: identificação, andares e apartamentos por andar.
- `ComentarioForm.java`: mensagem do comentário.
- `StatusChamadoForm.java`: nome do status.
- `TipoChamadoForm.java`: título e prazo em horas.
- `AreaForm.java`: nome e status da área.
- `UsuarioForm.java`: nome, e-mail, senha e tipo de perfil.
- `VincularColaboradorTipoChamadoForm.java`: vínculo colaborador-tipo.
- `VincularMoradorUnidadeForm.java`: vínculo morador-unidade.

## Relacionados
- `../CONTEXT.md`, `../../api/CONTEXT.md`
