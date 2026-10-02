# scripts

Verificação da reescrita de UI (`UI-REWRITE-PLAN.md` §3). Nada aqui é código de produção: são checagens
reprodutíveis. Os artefatos brutos ficam em `baseline/` (ignorado pelo git, exceto `baseline/EVIDENCE.md`).

## Ordem de execução

```bash
docker compose up -d app          # app de pé em http://localhost:8080
bash scripts/ui-seed.sh           # fixture + sessões em baseline/{admin,morador,colaborador}.jar
bash scripts/ui-routes.sh shell   # 26 rotas, 3 perfis -> baseline/html-shell/*.html
bash scripts/ui-shell.sh          # shell: lateral, ícones, grupos, item ativo, cartão do usuário
bash scripts/ui-drawer.sh         # componente ui:drawer: contrato, posição, escopo, fluxo real e JS
bash scripts/ui-tabelas.sh          # as 7 telas de tabela: cadastro/edição, filtros e ações
bash scripts/ui-invariants.sh check
docker compose run --rm test      # suíte + gate de cobertura
```

**As sessões de `ui-seed.sh` morrem a cada `docker compose up`** (recriação do container): rode o seed de
novo depois de qualquer restart, senão `ui-routes.sh` falha as 26 rotas.

## Scripts

| Script | Responsabilidade |
|---|---|
| `ui-baseline.sh` | Fotografa o estado pré-reescrita (contagem de classes legadas, HTML de referência) para comparação |
| `ui-seed.sh` | Fixture **idempotente**. Escreve pelos mesmos endpoints de formulário que os JSPs usam (sessão + CSRF), nunca pela API JSON — `/api/auth/**` não tem controller e o cookie `jwt` nunca é escrito. Leituras de idempotência vão por `psql` |
| `ui-routes.sh` | Matriz de rotas nos modos `baseline\|shell\|new`; grava o HTML renderizado em `baseline/html-{modo}/` |
| `ui-shell.sh` | Confere o HTML já gravado: estrutura da lateral (`dashboard-01`), 25 ícones Tabler, grupos, item ativo (prefixo mais longo), cartão do usuário e a topbar. Mais tres checagens de **fonte**: `head.jspf` materializa `${_csrf.token}`, todas as paginas incluem `head.jspf` e toda pagina declara `pageEncoding="UTF-8"` na primeira linha (sem isso o Jasper le o arquivo como ISO-8859-1 e os acentos saem duplicados — ver `jsp/CONTEXT.md`) |
| `ui-drawer.sh` | Componente `ui:drawer` (e, pelo mesmo protocolo, o `ui:dialog`): contrato do markup nos dois estados (cadastro/edição), **posição fora de `.page-content`**, escopo (as **5** telas de cadastro com tabela; chamados do admin é só leitura), fluxo real criar→editar→remover pelo formulário do drawer (com limpeza do resíduo) e contrato do `drawer.js`. O gatilho "Editar" é validado **por atributo** (`data-drawer-editar` + tooltip + `aria-label`), não pela classe, desde que virou botão só com ícone |
| `ui-drawer-js.mjs` | Executa o `drawer.js` num DOM mínimo em Node (não há navegador no ambiente): abrir/fechar, evento de fechamento, clique no backdrop, Esc, focus trap, trava de scroll, abertura server-side, o **conteúdo dinâmico** nas duas formas de declaração de campo (atributo no botão e input escondido), o **campo travado** e o reset que impede uma edição de herdar a anterior. Chamado por `ui-drawer.sh`; **21 casos** |
| `ui-tabelas.sh` | As **7 telas de tabela** do admin (reservas, areas, blocos, chamados, status-chamado, tipos-chamado, usuarios) em quatro camadas: markup renderizado de cada uma (cabeçalho com filete, faixa de filtros, coluna de ações encostada na direita, badges, drawers e o **nenhum marcador JSP vazado**), regras do `custom.css` + as classes do bundle, os dois harnesses executados, e a prova de que **não há requery**. Self-test negativo embutido: **15/15** sabotagens de markup (exercitam o próprio HTML, via `HTML_DIR`) e **18/18** de CSS. Substituiu `ui-areas.sh` na S26 |
| `ui-tables-js.mjs` | Executa o `tables.js` num DOM mínimo em Node sobre o cenário da tela de areas — inclusive a busca **dentro do `label.input`** (o aninhamento não pode quebrar a descoberta por `data-filter-input`), `data-filter-target` roteando entre duas tabelas e `textContent` multi-célula. Chamado por `ui-tabelas.sh`; self-test negativo: 3/3 sabotagens detectadas |
| `ui-invariants.sh` | Congela o contrato que os JSPs compartilham com controllers, JS, testes e build (`snapshot`/`check`). Verifica também o escopo de backend |

## CSRF (ler antes de mexer no shell)

O token é mascarado (BREACH) e o cookie `XSRF-TOKEN` é **limpo no login**, então todo POST precisa reler
`_csrf` de um formulário recém-renderizado. Além disso, `head.jspf` materializa o token no `<head>`: se o
primeiro acesso acontecer depois de a resposta passar do buffer de 8 KB do Tomcat, o `Set-Cookie` se perde e
**todo POST autenticado responde 403**. Ver `baseline/EVIDENCE.md` > S19.
