# src/main/webapp/WEB-INF/tags

Componentes JSP reutilizáveis (tag files), servidos pelo prefixo `ui` declarado em
`../jsp/fragments/taglibs.jspf`. Ficam fora de `jsp/` de propósito: são componentes, não
páginas, e por isso ficam fora do diretório que os resolvers de view varrem.

## Índice (S31)

| Tag | Para |
|---|---|
| `ui:shell` / `ui:shell-fim` | casca da página: doctype, `<head>` (com o token CSRF), drawer, lateral, topbar, `<main>` e flash; o par fecha com os scripts |
| `ui:nav-grupo` / `ui:nav-item` | navegação lateral: grupo com rótulo + item (ícone, rótulo e estado ativo no servidor) |
| `ui:card-head` | cabeçalho de card (título, descrição, `subtitulo` opcional; corpo = ação) |
| `ui:busca` | campo de busca local da faixa de filtros |
| `ui:paginacao` | Anterior/Próxima + "Página X de Y", preservando os filtros (`parametros`) |
| `ui:badge` | `<span class="badge badge-<variante>">` |
| `ui:acao-link` | ação de linha que navega: ícone + tooltip, ou `texto` visível |
| `ui:acao-painel` | ação de linha que abre um painel já preenchido (`data-drawer-editar`) |
| `ui:acao-form` | ação que envia formulário — dono do par CSRF + `_method`; ícone ou `texto` |
| `ui:tabela-chamados` | as 5 tabelas de chamados (colunas por flag, ação por texto ou ícone) |
| `ui:detalhe-chamado` | as 3 telas de detalhe do chamado |
| `ui:painel` | implementação única do drawer/diálogo (backdrop, topo, corpo, form, rodapé) |
| `ui:drawer` / `ui:dialog` | cascas finas sobre `ui:painel` (lateral / centralizado) |
| `ui:detalhe-linha` | linha "rótulo à esquerda, valor à direita" |
| `ui:icone` | glifo Tabler por alias (`nome` + `classe`) |
| `ui:vazio` | estado vazio (`.empty-state`) |
| `ui:reserva-status` | badge de status de reserva com cor semântica |
| `ui:flash` | mensagens de redirect (`successMessage`/`errorMessage`) |

Os fragmentos `vazio.jspf`, `icone.jspf`, `reserva-status.jspf` e `alerts.jspf` foram
substituídos por esses tags na S31 — não os recrie.

---

# Padrão de tela de tabela (S26)

Toda tela de listagem do admin — **reservas, areas, blocos, chamados, status-chamado,
tipos-chamado e usuarios** — é montada com os mesmos componentes (seis tags de listagem e
os dois paineis: `ui:drawer` e `ui:dialog`). Uma tela nova é ~15 linhas de estrutura:

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
                            <th><span class="sr-only">Ações</span></th>
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
| `ui:acao-painel` | abrir um painel preenchido | `painel`, `titulo`, `acao`; opcionais `metodo` (padrão `patch`), `rotulo`, `icone` |
| `ui:acao-form` | enviar um formulário | `acao`, `rotulo`, `icone`; opcionais `metodo` (padrão `delete`), `confirmacao`, `perigo` |

`ui:acao-painel` recebe os campos do painel no **corpo**, como inputs escondidos (chamava-se
`ui:acao-editar` até a S32: em reservas ele abre o diálogo de negação e o de cancelamento, que
não são edição de registro nenhum):

```jsp
<ui:acao-painel painel="drawer-area" titulo="Editar area" acao="${ctx}/admin/areas/${area.id}">
    <input type="hidden" data-campo="nome" value="${fn:escapeXml(area.nome)}">
    <input type="hidden" data-campo="status" value="${fn:escapeXml(area.status)}">
</ui:acao-painel>
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

**Casca fina sobre `ui:painel` (S31)**: o esqueleto é um só; o `drawer.tag` existe para manter
o nome e os atributos que as telas já usavam. Toda a regra de posicionamento/CSRF/travados
está em `painel.tag`.

Painel lateral que desliza da borda, em três faixas:

| Faixa | Conteúdo |
|---|---|
| topo | `titulo`, `descricao` (opcional) e o botão X |
| meio | `<jsp:doBody/>` — slot livre, com scroll próprio |
| rodapé | **só** o Salvar com ícone (com `acao`); **Fechar** + a ação declarada (sem `acao`) |

São duas formas, decididas por `acao`:

- **com `acao`** — é um formulário. Fechar é responsabilidade do X no topo, do Esc e do clique
  fora: não há botão "Fechar" no rodapé.
- **sem `acao`** — é um painel **informativo** (um detalhe, por exemplo). O rodapé passa a ter o
  botão **Fechar**, e `rotuloAcao` acrescenta um segundo botão à esquerda.

Atributos: `id` e `titulo` (obrigatórios); `descricao`, `acao`, `metodo`, `tamanho`
(`sm` padrão/estreito, `md`, `lg`), `lado` (`end` padrão/direita, `start`), `rotuloSalvar`
(padrão "Salvar"), `rotuloFechar` (o `aria-label` do X e o rótulo do Fechar informativo),
`aberto`, `travar`.

### Drawer informativo e painéis empilhados (S30)

`rotuloAcao` (com `iconeAcao` e `varianteAcao` — `primary` padrão, `error` para vermelho) cria o
botão da esquerda, e `painelAcao` + `metodoAcao` fazem esse botão **abrir outro painel** pelo
mesmo protocolo do gatilho de editar (`data-drawer-editar` + `data-campo-_method`). É assim que o
detalhe da reserva, na agenda, abre o diálogo central de cancelamento sem JS próprio: o
`calendar.js` só reescreve o `data-drawer-acao` do botão a cada evento.

Um painel pode, então, abrir outro por cima. Esc, o Tab e o foco preso valem sempre para o painel
de **cima** (o último aberto — a pilha `abertos` do `drawer.js`), e o de baixo continua aberto por
trás: é o que faz o "Voltar" do diálogo devolver a reserva detalhada. Por isso o diálogo precisa
ser renderizado **depois** do drawer no DOM (mesmo `z-index`; quem vem depois pinta por cima).

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
e evento `drawer:fechado` (borbulha, `detail = { id, valor }`). Esc, foco preso no painel de
cima, devolução do foco e trava de scroll são implementados no JS, já que não há `<dialog>`.

---

## `ui:detalhe-linha` (`detalhe-linha.tag`)

Uma linha de lista de detalhes: **rótulo à esquerda, valor em negrito à direita**. O
`<dl class="app-detalhe-lista">` em volta é declarado por quem usa — a lista é a composição de
várias linhas irmãs, e um tag não abre a lista.

```jsp
<dl class="app-detalhe-lista">
    <ui:detalhe-linha rotulo="Aberta em">${area.criadoEm}</ui:detalhe-linha>
    <ui:detalhe-linha rotulo="Área" campo="area" />
</dl>
```

Atributos: `rotulo` (obrigatório) e `campo` (opcional). Com `campo`, o `<dd>` sai com
`data-detalhe="<campo>"` para o JS preencher (`calendar.js` faz isso nas 7 linhas do detalhe da
reserva); sem ele a linha é estática e o valor vem do corpo.

A geometria está em `custom.css` sob `.app-detalhe-*`: `space-between` na linha (valor à direita),
`font-weight: 700` e `text-align: end` no valor, os dois `margin` do navegador zerados (`<dl>` e o
recuo de 40px do `<dd>`) e `min-width: 0` para um valor longo não estourar o painel.

---

## `ui:dialog` (`dialog.tag`)

**Casca fina sobre `ui:painel` (S31)**, pelo mesmo motivo do `ui:drawer`.

Mesmo componente do `ui:drawer`, outra forma: em vez de deslizar da borda, aparece
**centrado** na tela (fade + escala). Serve para confirmar uma decisao — negar uma reserva
pedindo o motivo, cancelar uma reserva sem motivo.

| Atributo | |
|---|---|
| `id`, `titulo` | obrigatorios |
| `descricao` | opcional — a explicacao abaixo do titulo |
| `acao` | action do form; sem ela o dialogo e so informativo |
| `metodo` | method do form (padrao `post`; o `_method` vem do gatilho) |
| `tamanho` | `sm`, `md` (padrao), `lg` |
| `rotuloConfirmar` | padrao "Confirmar" |
| `varianteConfirmar` | `primary` (padrao) ou `error` — vermelho |
| `iconeConfirmar` | alias opcional do icone do botao de confirmar |
| `rotuloCancelar` | botao esmaecido que fecha; sem ela o rodape so confirma |
| `aberto` | `true` abre no carregamento |

**Por baixo e o mesmo protocolo do `ui:drawer`**: os atributos `data-drawer*` e o
`drawer.js`. Backdrop, Esc, foco preso, trava de scroll e o conteudo dinamico
(`data-drawer-editar` + `data-drawer-acao`) sao o mesmo codigo — um dialogo e um drawer
centralizado, e duplicar o comportamento seria duplicar os bugs. O que muda e o CSS
(`.app-dialog`) e o rodape, que confirma em vez de salvar.

Como no drawer, precisa ser renderizado **fora de `.page-content`**. Um dialogo so e
reaproveitado por varias linhas: o gatilho de cada linha leva a acao daquele registro e o
`reporInicial` limpa o que foi digitado entre uma e outra.

Em reservas isso resolve o motivo da negacao, que antes era um `<input>` solto dentro da
celula de acoes e estourava a coluna.

O dialogo **nao tem filetes** (nem sob o titulo, nem sobre o rodape): a forma e dada pelo raio
e pela sombra, e como o corpo e opcional um filete viraria uma linha solta numa confirmacao
pura. Um dialogo sem campos sai com `app-dialog-corpo--vazio` (padding zero) para nao sobrar
faixa em branco entre o titulo e os botoes.

O corpo tem **respiro vertical minimo**, e pelos dois lados por motivos diferentes: `0.25rem`
em cima (o corpo e o `overflow-y: auto`, e sem respiro ele corta o anel de foco do primeiro
campo, que ocupa 4px) e `1rem` embaixo (separa o ultimo campo do rodape). Um `padding` cheio
dos quatro lados abria um vao entre a descricao e o primeiro campo; zero corta o anel.

O painel tem **altura de conteudo** (`height: fit-content` + `max-height` de viewport): cresce
com o formulario, para num teto e so entao o corpo rola. Sem o `fit-content` o `inset: 0` do
`position: fixed` estica o painel entre top e bottom e o dialogo ocupa a tela inteira.

---

## Ícones

`../jsp/fragments/icone.jspf` é um `include`, não um tag: quem inclui define `icone` (alias)
e `iconeClasse`. Alias desconhecido cai num círculo de fallback — que `ui-shell.sh` e
`ui-tabelas.sh` reprovam, para o erro não passar despercebido.

`negar` e `bloquear` são o mesmo glifo (círculo cortado) com dois nomes: cada tela usa o
vocabulário dela (negar a reserva × cancelar/bloquear a reserva).

## Verificação

- `bash scripts/ui-tabelas.sh` — contrato das **7 telas** de tabela: cabeçalho, faixa de
  filtros, coluna de ações, badges, paineis, as regras do `custom.css`, as classes do bundle,
  e o `tables.js` executado. Traz self-test negativo (15 sabotagens de markup + 18 de CSS).
- `bash scripts/ui-drawer.sh` — contrato do `ui:drawer` nos dois estados, posição fora de
  `.page-content`, escopo de uso (nas telas e nos fragmentos), fluxo criar→editar→remover e o
  `drawer.js` executado por `node scripts/ui-drawer-js.mjs` (**24 casos**, incluindo os painéis
  empilhados).
- `bash scripts/ui-agenda.sh` — a agenda de reservas (admin e morador): o detalhe no drawer
  informativo com a lista `ui:detalhe-linha`, o diálogo de cancelamento, as regras do
  `custom.css` da lista e o fluxo real de cancelamento.
- `bash scripts/ui-invariants.sh check` — congela o contrato que os JSPs compartilham com
  controllers, JS, testes e build.
