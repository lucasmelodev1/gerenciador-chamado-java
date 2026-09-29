# infrastructure/controller/web/form

Form objects (Lombok) usados como `@ModelAttribute`; a validação fica nos services.

- `AbrirChamadoForm.java`, `AtualizarStatusForm.java`, `ComentarioForm.java`: fluxo de chamados.
- `BlocoForm.java`, `UsuarioForm.java`, `VincularMoradorUnidadeForm.java`, `VincularColaboradorTipoChamadoForm.java`, `TipoChamadoForm.java`, `StatusChamadoForm.java`: cadastros do admin.
- `AreaForm.java`, `SolicitacaoAreaForm.java`, `NegarReservaForm.java`: áreas comuns e reservas.
