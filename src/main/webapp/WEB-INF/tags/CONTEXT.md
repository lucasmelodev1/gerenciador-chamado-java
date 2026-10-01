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
| rodapé | **só** o botão Salvar com ícone (e só quando `acao` é informado) |

Fechar é responsabilidade do X no topo, do Esc e do clique fora — não há botão "Fechar"
no rodapé.

Atributos: `id` e `titulo` (obrigatórios); `descricao`, `acao`, `metodo`, `tamanho`
(`sm` padrão/estreito, `md`, `lg`), `lado` (`end` padrão/direita, `start`), `rotuloSalvar`
(padrão "Salvar"), `rotuloFechar` (só o `aria-label` do X), `aberto`.

### Conteúdo dinâmico (criar e editar no mesmo drawer)

O drawer é **sempre renderizado no modo de criação** — nunca vem aberto do servidor. Quem
decide o que abrir é o gatilho:

| Gatilho | Efeito |
|---|---|
| `data-drawer-abrir="<id>"` | devolve o formulário ao estado renderizado (`action` original, `reset()`) e abre |
| `data-drawer-editar="<id>"` | aplica `data-drawer-acao`, `data-drawer-titulo` e cada `data-campo-<name>="<valor>"` e abre |

O `_method` é um campo como outro qualquer: o componente renderiza
`<input type="hidden" name="_method" value="">` e o gatilho de edição o preenche com
`data-campo-_method="patch"`. Vazio = POST (o `HiddenHttpMethodFilter` ignora parâmetro
sem valor).

Isso existe para **não depender de `?areaId=`**: o reload era o que deixava o drawer
fechado depois de salvar e exigia um segundo clique no "Novo". O drawer, portanto, ignora
qualquer estado de edição vindo do servidor.

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
