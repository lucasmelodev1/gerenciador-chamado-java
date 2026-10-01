# src/main/webapp/WEB-INF/tags

Componentes JSP reutilizáveis (tag files), servidos pelo prefixo `ui` declarado em
`../jsp/fragments/taglibs.jspf`. Ficam fora de `jsp/` de propósito: são componentes, não
páginas, e por isso ficam fora do diretório que os resolvers de view varrem.

## `ui:drawer` (`drawer.tag`)

Painel lateral que desliza da borda, em três faixas:

| Faixa | Conteúdo |
|---|---|
| topo | `titulo`, `descricao` (opcional) e o botão X |
| meio | `<jsp:doBody/>` — slot livre, com scroll próprio |
| rodapé | Salvar (só quando `acao` é informado) + Fechar |

Atributos: `id` e `titulo` (obrigatórios); `descricao`, `acao`, `metodo`, `tamanho`
(`sm` padrão/estreito, `md`, `lg`), `lado` (`end` padrão/direita, `start`), `rotuloSalvar`,
`rotuloFechar`, `aberto`.

- **Não é `<dialog>`.** São dois elementos irmãos: o backdrop e o `<aside>`. O porquê
  está em `baseline/EVIDENCE.md` > S23 (o `modal` da daisyUI não tem `::backdrop` e o
  legado espremia o escurecimento).
- **Renderize FORA de `.page-content`** — como filho direto do `<body>`. Lá o legado
  aplica `.page-content > * { width: min(100%, 1360px); margin-inline: auto }` (sem
  cascade layer, logo vence qualquer utilitário) e o backdrop deixaria as bordas da tela
  claras, além de o `animation: fadeLift` criar containing block.
- O corpo é renderizado **dentro** do `<form>`; o botão Salvar fica fora e o referencia
  por `form="<id>-form"`. Assim o rodapé pode mudar sem quebrar o envio dos campos.
- **O `<form>` inclui o `fragments/csrf.jspf`.** Se o formulário mudar de lugar, o
  `_csrf` vai junto — não remova.
- `acao="${ctx}/..."` — o `${acao}` aparece no snapshot de `action-urls` do
  `scripts/ui-invariants.sh`; é o único placeholder de action do repositório.

Comportamento em `static/js/drawer.js`: `AppDrawer.abrir(id)` / `AppDrawer.fechar(id)`,
gatilho declarativo `data-drawer-abrir="id"`, abertura no carregamento via `aberto="true"`
e evento `drawer:fechado` (borbulha, `detail = { id, valor }`). Esc, foco preso no painel,
devolução do foco e trava de scroll são implementados no JS, já que não há `<dialog>`.

Verificação: `bash scripts/ui-drawer.sh` (contrato do markup nos dois estados, posição fora
de `.page-content`, escopo de uso, fluxo criar/editar/remover e contrato do JS, incluindo
`node scripts/ui-drawer-js.mjs`, que executa o comportamento num DOM mínimo).
