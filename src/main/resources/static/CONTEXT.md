# src/main/resources/static

Assets estáticos servidos diretamente pelo Spring (liberados em `SecurityConfig`). Carregados pelos fragmentos JSP (`head.jspf`/`scripts.jspf`).

## CSS (`css/`)
- `base.css`: reset e tokens.
- `layout.css`: estrutura de layout, sidebar e topbar.
- `components.css`: componentes (cards, tabelas, alertas, formulários).
- `responsive.css`: ajustes de responsividade.

## JS (`js/`)
- `core.js`: utilitário global `window.AppDom` (`bySelector`, `onReady`).
- `layout.js`: toggle da sidebar e destaque do item ativo do menu.
- `forms.js`: confirmação de submit, mostrar/ocultar senha, contador de caracteres e auto-submit.
- `tables.js`: filtro client-side de tabelas.
- `alerts.js`: dispensa de alertas.

## Relacionados
- `../../webapp/WEB-INF/jsp/CONTEXT.md`
