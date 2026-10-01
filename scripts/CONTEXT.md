# scripts

Verificação da reescrita de UI (`UI-REWRITE-PLAN.md` §3). Nada aqui é código de produção: são checagens
reprodutíveis. Os artefatos brutos ficam em `baseline/` (ignorado pelo git, exceto `baseline/EVIDENCE.md`).

## Ordem de execução

```bash
docker compose up -d app          # app de pé em http://localhost:8080
bash scripts/ui-seed.sh           # fixture + sessões em baseline/{admin,morador,colaborador}.jar
bash scripts/ui-routes.sh shell   # 26 rotas, 3 perfis -> baseline/html-shell/*.html
bash scripts/ui-shell.sh          # shell: lateral, ícones, grupos, item ativo, cartão do usuário
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
| `ui-shell.sh` | Confere o HTML já gravado: estrutura da lateral (`dashboard-01`), 20 ícones Tabler, grupos, item ativo (prefixo mais longo), cartão do usuário e a topbar. Mais duas checagens de **fonte**: `head.jspf` materializa `${_csrf.token}` e todas as páginas incluem `head.jspf` |
| `ui-invariants.sh` | Congela o contrato que os JSPs compartilham com controllers, JS, testes e build (`snapshot`/`check`). Verifica também o escopo de backend |

## CSRF (ler antes de mexer no shell)

O token é mascarado (BREACH) e o cookie `XSRF-TOKEN` é **limpo no login**, então todo POST precisa reler
`_csrf` de um formulário recém-renderizado. Além disso, `head.jspf` materializa o token no `<head>`: se o
primeiro acesso acontecer depois de a resposta passar do buffer de 8 KB do Tomcat, o `Set-Cookie` se perde e
**todo POST autenticado responde 403**. Ver `baseline/EVIDENCE.md` > S19.
