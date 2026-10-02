# src/main/webapp/WEB-INF/tags

Componentes JSP reutilizáveis (tag files), servidos pelo prefixo `ui` declarado em
`../jsp/fragments/taglibs.jspf`. Ficam fora de `jsp/` de propósito: são componentes, não
páginas, e por isso ficam fora do diretório que os resolvers de view varrem.

---

# Padrão de tela de tabela (S26)

Toda tela de listagem do admin — **areas, blocos, chamados, status-chamado, tipos-chamado e
usuarios** — é montada com os mesmos seis tags. Uma tela nova é ~15 linhas de estrutura:

```jsp
<section class="card">
    <div class="card-body">
        <ui:card-head titulo="Blocos cadastrados" descricao="Estrutura do condominio">
            <button type="button" class="btn btn-primary btn-sm" data-drawer-abrir="drawer-bloco">
                Novo bloco
            </button>
        </ui:card-head>

        <div class="app-card-filtros">
            <ui:busca alvo="blocos-table" rotulo="Pesquisar blocos" />
        </div>

        <c:choose>
            <c:when test="${empty blocos}">… vazio.jspf …</c:when>
            <c:otherwise>
                <div class="overflow-x-auto">
                    <table class="table table-zebra" data-filter-table="blocos-table">
                        <thead><tr>
                            <th>Identificacao</th> …
                            <th><span class="sr-only">Acoes</span></th>
                        </tr></thead>
                        <tbody>
                        <c:forEach items="${blocos}" var="bloco">
                            <tr>
                                <td>${bloco.identificacao}</td> …
                                <td class="cell-actions app-tabela-acoes">… ações …</td>
                            </tr>
                        </c:forEach>
                        </tbody>
                    </table>
                </div>
            </c:otherwise>
        </c:choose>

        <div class="pagination">…</div>
    </div>
</section>

<ui:drawer id="drawer-bloco" titulo="Novo bloco" acao="${ctx}/admin/blocos">…campos…</ui:drawer>
```

O que **não** muda de tela para tela, e por isso saiu do JSP: o cabeçalho com o filete, a
molduras da busca, o badge, e a moldura das três ações de linha. O que muda é só o
conteúdo — títulos, colunas e os valores de cada linha.

Estilo compartilhado em `custom.css`: `.app-card-head`, `.app-card-filtros`,
`.app-tabela-acoes`, `.app-btn-perigo` e o alinhamento do balão do tooltip.

## `ui:card-head` (`card-head.tag`)

Descrição e título colados (`gap: 2px`) à esquerda, o corpo à direita
(`space-between`), fechado por um filete que separa o cabeçalho da faixa de filtros.

| Atributo | |
|---|---|
| `titulo` | obrigatório — vai no `<h2>` |
| `descricao` | opcional — vai no `.eyebrow` |
| corpo | opcional — a ação primária (normalmente o gatilho do drawer) |

Sem corpo (chamados do admin, que é só leitura) sai só título e descrição, com o filete.

## `ui:busca` (`busca.tag`)

Campo de busca local na faixa de filtros: um `label.input` da daisyUI com a lupa dentro da
própria moldura, à esquerda do texto.

| Atributo | |
|---|---|
| `alvo` | obrigatório — valor de `data-filter-target`; casa com o `data-filter-table` da tabela |
| `rotulo` | opcional — `aria-label` (padrão "Pesquisar"); o campo não tem texto visível |
| `placeholder` | opcional — padrão "Pesquisar..." |

O filtro é **local**: `static/js/tables.js` compara `textContent` das linhas e alterna
`is-hidden`. Não há requisição ao servidor, então ele só enxerga a página atual e se perde
ao paginar. Telas com filtro de servidor (chamados) põem o `<form method="get">` direto na
faixa, com a classe extra `app-card-filtros--campos` (alinha as ações pela base dos
controles, já que ali há rótulo acima).

## `ui:badge` (`badge.tag`)

`<span class="badge badge-<variante>">` com o corpo como texto.

| Atributo | |
|---|---|
| `variante` | `success`, `warning`, `error`, `neutral`, `ghost`, `info` (padrão `neutral`) |

A **cor não é decidida aqui**: quem chama escolhe a variante a partir do valor do domínio, e
o mapeamento tem de ser literal no JSP
(`variante="${area.status eq 'Ativo' ? 'success' : 'neutral'}"`). O nome da classe é montado
por variável e o Tailwind **não** extrai classe montada — as variantes vivem em
`static/ui-preview.html`, que é a safelist explícita, e `scripts/ui-tabelas.sh` confere no
bundle que toda variante usada no HTML existe.

## Ações de linha

As três saem com a mesma moldura — `btn btn-ghost btn-sm btn-square tooltip`, ícone em
`size-4` (o mesmo tamanho dos ícones da lateral), `data-tip` e `aria-label` com o rótulo. A
coluna é `<td class="cell-actions app-tabela-acoes">`, que alinha à direita e zera o
`padding-inline` para a ação encostar na borda da tabela.

| Tag | Para | Atributos |
|---|---|---|
| `ui:acao-link` | navegar (detalhe, unidades) | `href`, `rotulo`, `icone` |
| `ui:acao-editar` | abrir o drawer preenchido | `drawer`, `titulo`, `acao`; opcionais `metodo` (padrão `patch`), `rotulo`, `icone` |
| `ui:acao-form` | enviar um formulário | `acao`, `rotulo`, `icone`; opcionais `metodo` (padrão `delete`), `confirmacao`, `perigo` |

`ui:acao-editar` recebe os campos do drawer no **corpo**, como inputs escondidos:

```jsp
<ui:acao-editar drawer="drawer-area" titulo="Editar area" acao="${ctx}/admin/areas/${area.id}">
    <input type="hidden" data-campo="nome" value="${fn:escapeXml(area.nome)}">
    <input type="hidden" data-campo="status" value="${fn:escapeXml(area.status)}">
</ui:acao-editar>
```

Isso substituiu o formato `data-campo-<name>="<valor>"` direto no botão. O motivo é dado de
usuário: um nome com `;` ou `|` corromperia qualquer codificação em string, enquanto `value`
de um input passa pelo escape normal do HTML e aceita quantos campos forem. O `drawer.js` lê
as duas formas (a nova vence).

`ui:acao-form` gera `<form method="post">` + `csrf.jspf` + `_method`, então a tela não repete
esse trio. O corpo dele é opcional e recebe campos escondidos extras. `perigo="true"` pinta o
ícone com a cor de erro — **não** use `btn-ghost btn-error` no lugar: o `--btn-fg` do
`btn-error` é quase branco e o `.btn:hover` (layer pai) o aplicaria no hover.

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
(padrão "Salvar"), `rotuloFechar` (só o `aria-label` do X), `aberto`, `travar`.

### Conteúdo dinâmico (criar e editar no mesmo drawer)

O drawer é **sempre renderizado no modo de criação** — nunca vem aberto do servidor. Quem
decide o que abrir é o gatilho:

| Gatilho | Efeito |
|---|---|
| `data-drawer-abrir="<id>"` | devolve o formulário ao estado renderizado (`action` original, `reset()`, campos travados destravados) e abre |
| `data-drawer-editar="<id>"` | passa pelo estado inicial e depois aplica `data-drawer-acao`, `data-drawer-titulo` e os campos declarados, e abre |

O `_method` é um campo como outro qualquer: o componente renderiza
`<input type="hidden" name="_method" value="">` e o gatilho de edição o preenche com
`patch`/`put`. Vazio = POST (o `HiddenHttpMethodFilter` ignora parâmetro sem valor).

O gatilho de edição **passa pelo estado inicial antes de aplicar**: sem isso o que foi
digitado numa edição vazaria para a seguinte em campo que o gatilho não declara — a `senha`
de usuário, por exemplo, é obrigatória em toda edição e não vem da linha.

Isso existe para **não depender de parâmetro de query** (`?areaId=`, `?statusId=`,
`?tipoId=`): o reload era o que deixava o drawer fechado depois de salvar e exigia um segundo
clique no "Novo". Os `GET` correspondentes continuam existindo nos controllers, mas nenhuma
tela aponta para eles.

### Campos travados (`travar`)

`travar="tipo"` (lista separada por vírgula) marca campos que a **edição** não pode mudar mas
a **criação** pode. O componente renderiza, para cada um, um espelho escondido com o mesmo
`name`, já `disabled`; o `drawer.js` desabilita o controle visível e habilita o espelho ao
editar, e desfaz ao criar. É necessário porque campo `disabled` não é enviado.

Uso hoje: o **perfil** do usuário. O `PATCH /admin/usuarios/{id}` deriva o tipo do papel
persistido e o serviço recusa a troca (`Nao e permitido alterar o tipo do usuario`).

### Posicionamento e CSRF

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
  `scripts/ui-invariants.sh`; é o placeholder de action compartilhado com `ui:acao-form`.

Comportamento em `static/js/drawer.js`: `AppDrawer.abrir(id)` / `AppDrawer.fechar(id)`,
gatilho declarativo `data-drawer-abrir="id"`, abertura no carregamento via `aberto="true"`
e evento `drawer:fechado` (borbulha, `detail = { id, valor }`). Esc, foco preso no painel,
devolução do foco e trava de scroll são implementados no JS, já que não há `<dialog>`.

---

## Ícones

`../jsp/fragments/icone.jspf` é um `include`, não um tag: quem inclui define `icone` (alias)
e `iconeClasse`. Alias desconhecido cai num círculo de fallback — que `ui-shell.sh` e
`ui-tabelas.sh` reprovam, para o erro não passar despercebido.

## Verificação

- `bash scripts/ui-tabelas.sh` — contrato das **6 telas** de tabela: cabeçalho, faixa de
  filtros, coluna de ações, badges, drawers, as regras do `custom.css`, as classes do bundle,
  e o `tables.js` executado. Traz self-test negativo (11 sabotagens de markup + 10 de CSS).
- `bash scripts/ui-drawer.sh` — contrato do `ui:drawer` nos dois estados, posição fora de
  `.page-content`, escopo de uso, fluxo criar→editar→remover e o `drawer.js` executado
  por `node scripts/ui-drawer-js.mjs` (21 casos).
- `bash scripts/ui-invariants.sh check` — congela o contrato que os JSPs compartilham com
  controllers, JS, testes e build.
