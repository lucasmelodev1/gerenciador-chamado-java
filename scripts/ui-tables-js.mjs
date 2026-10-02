/*
 * S24 — Teste de comportamento do filtro da tela de areas, sem navegador.
 *
 * O ambiente nao tem browser, entao a unica forma de EXECUTAR o `tables.js` (em vez de
 * so inspecionar a fonte) e um DOM minimo em Node.
 *
 * O risco real desta mudanca nao esta no CSS: a busca passou a ficar DENTRO de um
 * `<label class="input">` (para o icone entrar na moldura, sem `position: absolute`).
 * `tables.js` descobre o campo com `document.querySelectorAll("[data-filter-input]")`,
 * entao o teste prova justamente que o aninhamento nao quebrou a descoberta, o `value`
 * nem o roteamento por `data-filter-target`.
 *
 * O cenario abaixo espelha o markup que `admin/areas/lista.jsp` renderiza; quem garante
 * que o HTML de verdade tem essa forma e `scripts/ui-tabelas.sh` (secao A).
 *
 *   node scripts/ui-tables-js.mjs      -> imprime os casos e sai 1 na primeira falha
 */
import assert from "node:assert/strict";
import fs from "node:fs";
import vm from "node:vm";

// ---------------------------------------------------------------- DOM minimo

class CustomEvent {
    constructor(type, init = {}) {
        this.type = type;
        this.detail = init.detail;
        this.bubbles = Boolean(init.bubbles);
        this.target = null;
        this.defaultPrevented = false;
    }
    preventDefault() { this.defaultPrevented = true; }
}

// Casa um composto simples: `tag`, `.classe`, `[attr]`, `[attr="valor"]` e combinacoes.
function casarComposto(el, composto) {
    const tag = composto.match(/^[a-z]+/i);
    if (tag && el.tagName !== tag[0].toUpperCase()) return false;
    for (const classe of composto.matchAll(/\.([A-Za-z0-9_-]+)/g)) {
        if (!el.classes.has(classe[1])) return false;
    }
    return [...composto.matchAll(/\[([^\]=]+)(?:=("?)([^"\]]*)\2)?\]/g)]
        .every((m) => (m[3] === undefined ? el.hasAttribute(m[1]) : el.getAttribute(m[1]) === m[3]));
}

// Suporta descendencia (`tbody tr`), que e o unico combinador que o tables.js usa.
function casar(el, sel) {
    const partes = sel.trim().split(/\s+/).filter(Boolean);
    if (!partes.length) return false;
    if (!casarComposto(el, partes[partes.length - 1])) return false;

    let ancestral = el.parent;
    for (let i = partes.length - 2; i >= 0; i--) {
        let achou = false;
        while (ancestral) {
            if (casarComposto(ancestral, partes[i])) { achou = true; ancestral = ancestral.parent; break; }
            ancestral = ancestral.parent;
        }
        if (!achou) return false;
    }
    return true;
}

class El {
    constructor(tag, attrs = {}) {
        this.tagName = tag.toUpperCase();
        this.attrs = { ...attrs };
        this.id = attrs.id || "";
        this.parent = null;
        this._texto = "";
        this._filhos = [];
        this._listeners = {};
        this.classes = new Set(String(attrs.class || "").split(/\s+/).filter(Boolean));

        const dono = this;
        this.classList = {
            add: (c) => dono.classes.add(c),
            remove: (c) => dono.classes.delete(c),
            contains: (c) => dono.classes.has(c),
            toggle: (c, forcar) => {
                const ligar = forcar === undefined ? !dono.classes.has(c) : Boolean(forcar);
                if (ligar) dono.classes.add(c); else dono.classes.delete(c);
                return ligar;
            },
        };

        // suficiente para `input.value` do campo de busca
        this.value = this.hasAttribute("value") ? this.getAttribute("value") : "";
    }
    // `textContent` de verdade: concatena os descendentes (e o que o tables.js compara).
    get textContent() { return this._texto + this._filhos.map((f) => f.textContent).join(""); }
    set textContent(v) { this._texto = String(v); }

    hasAttribute(n) { return Object.prototype.hasOwnProperty.call(this.attrs, n); }
    getAttribute(n) { return this.hasAttribute(n) ? this.attrs[n] : null; }
    setAttribute(n, v) { this.attrs[n] = v; }
    addEventListener(t, fn) { (this._listeners[t] ||= []).push(fn); }
    appendChild(filho) { filho.parent = this; this._filhos.push(filho); return filho; }
    dispatchEvent(evento) {
        if (!evento.target) evento.target = this;
        (this._listeners[evento.type] || []).forEach((fn) => fn(evento));
        return true;
    }
    querySelector(sel) { return this.querySelectorAll(sel)[0] || null; }
    querySelectorAll(sel) {
        const alvos = sel.split(",").map((s) => s.trim());
        const achados = [];
        const visitar = (no) => no._filhos.forEach((f) => {
            if (alvos.some((a) => casar(f, a))) achados.push(f);
            visitar(f);
        });
        visitar(this);
        return achados;
    }
    // Dispara o mesmo evento que o navegador emite ao digitar no campo.
    digitar(texto) {
        this.value = texto;
        const ev = new CustomEvent("input", { bubbles: true });
        ev.target = this;
        this.dispatchEvent(ev);
        return ev;
    }
}

function criarAmbiente() {
    const body = new El("body");
    const document = {
        body,
        _listeners: {},
        addEventListener(t, fn) { (this._listeners[t] ||= []).push(fn); },
        querySelector(sel) { return body.querySelector(sel); },
        querySelectorAll(sel) { return body.querySelectorAll(sel); },
        _disparar(t, ev) { (this._listeners[t] || []).forEach((fn) => fn(ev)); },
    };
    const contexto = vm.createContext({ window: {}, document, CustomEvent, console });
    contexto.window = contexto;
    contexto.window.document = document;
    contexto.document = document;

    for (const arq of ["core.js", "tables.js"]) {
        vm.runInContext(
            fs.readFileSync(`src/main/resources/static/js/${arq}`, "utf8"),
            contexto,
            { filename: arq },
        );
    }
    return { contexto, document, body };
}

// ---------------------------------------------------------------- cenario
// Espelha o que admin/areas/lista.jsp renderiza: cabecalho + faixa de filtros
// (com a busca dentro do `label.input`) + a tabela alvo.

function linha(...celulas) {
    const tr = new El("tr");
    celulas.forEach((texto) => {
        const td = new El("td");
        td.textContent = texto;
        tr.appendChild(td);
    });
    return tr;
}

function tabela(nome, linhas) {
    const table = new El("table", { class: "table table-zebra", "data-filter-table": nome });
    const tbody = new El("tbody");
    linhas.forEach((tr) => tbody.appendChild(tr));
    table.appendChild(tbody);
    return table;
}

function busca(alvo, placeholder = "Pesquisar...") {
    const label = new El("label", { class: "input input-sm" });
    label.appendChild(new El("svg", { class: "size-4 shrink-0 opacity-60" }));
    const campo = new El("input", {
        type: "search",
        placeholder,
        "aria-label": "Pesquisar areas",
        "data-filter-input": "",
        "data-filter-target": alvo,
    });
    label.appendChild(campo);
    return { label, campo };
}

function montarCenario() {
    const ambiente = criarAmbiente();
    const { document, body } = ambiente;

    // cabecalho da tabela
    const texto = new El("div", { class: "app-card-head__texto" });
    const descricao = new El("p", { class: "eyebrow" });
    descricao.textContent = "Espacos do condominio";
    const titulo = new El("h2");
    titulo.textContent = "Areas cadastradas";
    texto.appendChild(descricao);
    texto.appendChild(titulo);

    const cabecalho = new El("div", { class: "app-card-head" });
    cabecalho.appendChild(texto);
    cabecalho.appendChild(new El("button", {
        type: "button", class: "btn btn-primary btn-sm", "data-drawer-abrir": "drawer-area",
    }));

    // faixa de filtros
    const filtros = new El("div", { class: "app-card-filtros" });
    const alvo = busca("areas-table");
    filtros.appendChild(alvo.label);

    // a tabela da tela e uma segunda tabela com o seu proprio filtro, para provar
    // que `data-filter-target` roteia e que um filtro nao mexe na tabela do outro
    const outraBusca = busca("outra-tabela", "Outro filtro");
    filtros.appendChild(outraBusca.label);

    const tabelaAreas = tabela("areas-table", [
        linha("Piscina", "Ativo"),
        linha("Salao de festas", "Inativo"),
    ]);
    const tabelaOutra = tabela("outra-tabela", [
        linha("Piscina", "Ativo"),
        linha("Salao de festas", "Inativo"),
    ]);

    body.appendChild(cabecalho);
    body.appendChild(filtros);
    body.appendChild(tabelaAreas);
    body.appendChild(tabelaOutra);

    document._disparar("DOMContentLoaded", new CustomEvent("DOMContentLoaded"));

    const linhasAreas = tabelaAreas.querySelectorAll("tbody tr");
    const linhasOutra = tabelaOutra.querySelectorAll("tbody tr");
    return {
        ...ambiente, cabecalho, filtros, campo: alvo.campo, campoOutro: outraBusca.campo,
        tabelaAreas, tabelaOutra, linhasAreas, linhasOutra,
    };
}

const escondida = (tr) => tr.classes.has("hidden");

// ---------------------------------------------------------------- casos

const casos = [];
function caso(nome, fn) { casos.push([nome, fn]); }

caso("a busca dentro do label.input e descoberta pelo tables.js", () => {
    const { campo, linhasAreas } = montarCenario();
    assert.equal(campo._listeners.input?.length, 1, "o campo deveria ter recebido o listener de `input`");
    campo.digitar("pis");
    assert.equal(escondida(linhasAreas[0]), false, "o filtro nao chegou a rodar (aninhamento quebrou?)");
});

caso("digitar filtra as linhas da tabela alvo", () => {
    const { campo, linhasAreas } = montarCenario();
    campo.digitar("pis");
    assert.equal(escondida(linhasAreas[0]), false, "a linha 'Piscina' deveria continuar visivel");
    assert.equal(escondida(linhasAreas[1]), true, "a linha 'Salao de festas' deveria sumir");
});

caso("a comparacao e case-insensitive", () => {
    const { campo, linhasAreas } = montarCenario();
    campo.digitar("PISCINA");
    assert.equal(escondida(linhasAreas[0]), false);
    assert.equal(escondida(linhasAreas[1]), true);
});

caso("espacos em volta do termo sao ignorados", () => {
    const { campo, linhasAreas } = montarCenario();
    campo.digitar("  pis  ");
    assert.equal(escondida(linhasAreas[0]), false);
    assert.equal(escondida(linhasAreas[1]), true);
});

caso("so espacos nao esconde nada", () => {
    const { campo, linhasAreas } = montarCenario();
    campo.digitar("   ");
    assert.equal(linhasAreas.some(escondida), false, "com o campo 'vazio' tudo continua visivel");
});

caso("limpar o campo devolve todas as linhas", () => {
    const { campo, linhasAreas } = montarCenario();
    campo.digitar("piscina");
    assert.equal(escondida(linhasAreas[1]), true);
    campo.digitar("");
    assert.equal(linhasAreas.some(escondida), false, "limpar deveria mostrar todas");
});

caso("sem correspondencia esconde todas as linhas", () => {
    const { campo, linhasAreas } = montarCenario();
    campo.digitar("zzz-inexistente");
    assert.equal(linhasAreas.every(escondida), true);
});

caso("data-filter-target roteia: o filtro nao toca na outra tabela", () => {
    const { campo, linhasAreas, linhasOutra } = montarCenario();
    campo.digitar("pis");
    assert.equal(escondida(linhasAreas[1]), true, "a tabela alvo deveria ser filtrada");
    assert.equal(linhasOutra.some(escondida), false, "a outra tabela nao pode ser afetada");
});

caso("cada campo filtra so a sua tabela", () => {
    const { campo, campoOutro, linhasAreas, linhasOutra } = montarCenario();
    campoOutro.digitar("salao");
    assert.equal(escondida(linhasOutra[0]), true, "a outra tabela deveria ser filtrada pelo seu campo");
    assert.equal(escondida(linhasOutra[1]), false);
    assert.equal(linhasAreas.some(escondida), false, "a tabela de areas nao pode ser afetada");
});

caso("o texto casado inclui todas as celulas da linha (nao so a primeira)", () => {
    const { campo, linhasAreas } = montarCenario();
    campo.digitar("inativo");   // esta na 2a celula, nao na 1a
    assert.equal(escondida(linhasAreas[1]), false, "deveria casar pela coluna Status");
    assert.equal(escondida(linhasAreas[0]), true);
});

caso("duas buscas na pagina nao interferem uma na outra", () => {
    const { campo, campoOutro, linhasAreas, linhasOutra } = montarCenario();
    campo.digitar("piscina");
    campoOutro.digitar("salao");
    assert.equal(escondida(linhasAreas[1]), true);
    assert.equal(escondida(linhasOutra[0]), true);
    assert.equal(escondida(linhasAreas[0]), false);
    assert.equal(escondida(linhasOutra[1]), false);
});

// ---------------------------------------------------------------- execucao

let falhas = 0;
for (const [nome, fn] of casos) {
    try {
        fn();
        console.log(`  OK   ${nome}`);
    } catch (erro) {
        falhas += 1;
        console.log(`  FAIL ${nome}\n         ${erro.message}`);
    }
}
console.log(`\n${casos.length - falhas}/${casos.length} casos de comportamento do filtro de areas`);
process.exit(falhas === 0 ? 0 : 1);
