/*
 * S23 — Teste de comportamento do `drawer.js` sem navegador.
 *
 * O ambiente nao tem browser, entao a unica forma de EXECUTAR o JS (em vez de so
 * inspecionar a fonte) e um DOM minimo em Node. Nao e um teste de renderizacao: e um
 * teste da logica de abrir/fechar/evento/foco — que e onde mora o risco real, ainda
 * mais agora que o componente nao usa <dialog> e todo o comportamento e manual.
 *
 *   node scripts/ui-drawer-js.mjs      -> imprime os casos e sai 1 na primeira falha
 *
 * O que fica de fora, por depender do motor do navegador: a animacao do `translate`,
 * `100dvh` e o layout real das tres faixas.
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

// Casa um seletor simples o suficiente para o que o drawer.js usa:
// `[attr]`, `[attr="valor"]`, `tag`, `tag[attr]`, `:not([attr])`, `:not([attr=valor])`.
function casarAtributos(el, sel) {
    return [...sel.matchAll(/\[([^\]=]+)(?:=("?)([^"\]]*)\2)?\]/g)]
        .every((m) => (m[3] === undefined ? el.hasAttribute(m[1]) : el.getAttribute(m[1]) === m[3]));
}

function casar(el, sel) {
    const alvo = sel.trim();
    if (!alvo) return false;

    const tag = alvo.match(/^[a-z]+/i);
    if (tag && el.tagName !== tag[0].toUpperCase()) return false;

    for (const negado of alvo.matchAll(/:not\(([^)]*)\)/g)) {
        if (casarAtributos(el, negado[1])) return false;
    }

    return casarAtributos(el, alvo.replace(/:not\([^)]*\)/g, ""));
}

class El {
    constructor(tag, attrs = {}) {
        this.tagName = tag.toUpperCase();
        this.attrs = { ...attrs };
        this.id = attrs.id || "";
        this.parent = null;
        this._listeners = {};
        this._filhos = [];
        this.disparados = [];
        this.classes = new Set();
        this.classList = {
            add: (c) => this.classes.add(c),
            remove: (c) => this.classes.delete(c),
            contains: (c) => this.classes.has(c),
        };
    }
    hasAttribute(n) { return Object.prototype.hasOwnProperty.call(this.attrs, n); }
    getAttribute(n) { return this.hasAttribute(n) ? this.attrs[n] : null; }
    setAttribute(n, v) { this.attrs[n] = v; }
    removeAttribute(n) { delete this.attrs[n]; }
    addEventListener(t, fn) { (this._listeners[t] ||= []).push(fn); }
    appendChild(filho) { filho.parent = this; this._filhos.push(filho); return filho; }
    dispatchEvent(evento) {
        if (!evento.target) evento.target = this;
        this.disparados.push(evento);
        (this._listeners[evento.type] || []).forEach((fn) => fn(evento));
        return true;
    }
    closest(sel) {
        let atual = this;
        while (atual) {
            if (atual.matches(sel)) return atual;
            atual = atual.parent;
        }
        return null;
    }
    matches(sel) {
        return casar(this, sel);
    }
    querySelectorAll(sel) {
        // suficiente para os seletores que o drawer.js usa
        const alvos = sel.split(",").map((s) => s.trim());
        const achados = [];
        const visitar = (no) => no._filhos.forEach((f) => {
            if (alvos.some((a) => f.matches(a))) achados.push(f);
            visitar(f);
        });
        visitar(this);
        return achados;
    }
    focus() { ambienteAtual.document.activeElement = this; }
    clicar() {
        const ev = new CustomEvent("click", { bubbles: true });
        ev.target = this;
        this.dispatchEvent(ev);
        return ev;
    }
    teclar(key, shiftKey = false) {
        const ev = new CustomEvent("keydown", { bubbles: true });
        ev.key = key;
        ev.shiftKey = shiftKey;
        ev.target = this;
        return ev;
    }
}

let ambienteAtual = null;

function criarAmbiente(elementos) {
    const body = new El("body");
    const document = {
        body,
        activeElement: body,
        _listeners: {},
        addEventListener(t, fn) { (this._listeners[t] ||= []).push(fn); },
        getElementById(id) { return elementos.find((e) => e.id === id) || null; },
        querySelectorAll(sel) { return body.querySelectorAll(sel); },
        _disparar(t, ev) { (this._listeners[t] || []).forEach((fn) => fn(ev)); },
    };
    const contexto = vm.createContext({ window: {}, document, CustomEvent, console });
    contexto.window = contexto;
    contexto.window.document = document;
    contexto.window.CustomEvent = CustomEvent;
    contexto.document = document;
    ambienteAtual = contexto;

    for (const arq of ["core.js", "drawer.js"]) {
        vm.runInContext(
            fs.readFileSync(`src/main/resources/static/js/${arq}`, "utf8"),
            contexto,
            { filename: arq },
        );
    }
    return { contexto, document, body };
}

// ---------------------------------------------------------------- cenario

function montarCenario({ aberto = false } = {}) {
    // <aside id="drawer-area" data-drawer> = topo (X + titulo) + corpo + rodape
    const painel = new El("aside", { id: "drawer-area", "data-drawer": "" });
    const titulo = new El("h2", { id: "drawer-area-titulo" });
    const botaoX = new El("button", { "data-drawer-fechar": "" });
    const campoNome = new El("input", { name: "nome" });
    const botaoSalvar = new El("button", { type: "submit" });
    const botaoFecharRodape = new El("button", { "data-drawer-fechar": "" });
    [titulo, botaoX, campoNome, botaoSalvar, botaoFecharRodape].forEach((f) => painel.appendChild(f));

    const backdrop = new El("div", { id: "drawer-area-backdrop", "data-drawer-backdrop": "drawer-area" });
    const gatilho = new El("button", { "data-drawer-abrir": "drawer-area" });

    if (aberto) {
        painel.setAttribute("data-drawer-aberto", "");
        backdrop.setAttribute("data-drawer-aberto", "");
    }

    const elementos = [painel, backdrop, gatilho, botaoX, botaoFecharRodape, campoNome];
    const ambiente = criarAmbiente(elementos);
    ambiente.document.body.appendChild(backdrop);
    ambiente.document.body.appendChild(painel);
    ambiente.document.body.appendChild(gatilho);

    ambiente.document._disparar("DOMContentLoaded", new CustomEvent("DOMContentLoaded"));
    return { ...ambiente, painel, backdrop, gatilho, botaoX, botaoFecharRodape, campoNome };
}

// ---------------------------------------------------------------- casos

const casos = [];
function caso(nome, fn) { casos.push([nome, fn]); }

caso("o gatilho data-drawer-abrir abre, trava o scroll e nao navega", () => {
    const { painel, backdrop, gatilho, body } = montarCenario();
    const ev = gatilho.clicar();
    assert.equal(painel.hasAttribute("data-drawer-aberto"), true, "o painel deveria abrir");
    assert.equal(backdrop.hasAttribute("data-drawer-aberto"), true, "o backdrop deveria aparecer");
    assert.equal(body.classes.has("app-drawer-trava-scroll"), true, "deveria travar o scroll");
    assert.equal(ev.defaultPrevented, true, "o gatilho nao pode navegar/enviar form");
});

caso("abrir move o foco para o primeiro focavel do painel", () => {
    const { contexto, document, painel, botaoX } = montarCenario();
    contexto.AppDrawer.abrir("drawer-area");
    assert.equal(document.activeElement, botaoX, "o foco deveria ir para dentro do painel");
});

caso("fechar dispara drawer:fechado com { id, valor } e destrava o scroll", () => {
    const { contexto, painel, backdrop, body } = montarCenario();
    contexto.AppDrawer.abrir("drawer-area");
    painel.disparados.length = 0;
    contexto.AppDrawer.fechar("drawer-area", "salvo");

    assert.equal(painel.hasAttribute("data-drawer-aberto"), false, "o painel deveria fechar");
    assert.equal(backdrop.hasAttribute("data-drawer-aberto"), false, "o backdrop deveria sumir");
    assert.equal(body.classes.has("app-drawer-trava-scroll"), false, "deveria destravar o scroll");

    const ev = painel.disparados.find((e) => e.type === "drawer:fechado");
    assert.ok(ev, "deveria emitir drawer:fechado");
    assert.equal(ev.detail.id, "drawer-area");
    assert.equal(ev.detail.valor, "salvo");
    assert.equal(ev.bubbles, true, "precisa borbulhar para ouvir no document");
});

caso("clique no backdrop fecha", () => {
    const { contexto, painel, backdrop } = montarCenario();
    contexto.AppDrawer.abrir("drawer-area");
    backdrop.clicar();
    assert.equal(painel.hasAttribute("data-drawer-aberto"), false, "o clique fora deveria fechar");
});

caso("Esc fecha", () => {
    const { contexto, painel, document } = montarCenario();
    contexto.AppDrawer.abrir("drawer-area");
    document._disparar("keydown", painel.teclar("Escape"));
    assert.equal(painel.hasAttribute("data-drawer-aberto"), false, "Esc deveria fechar");
});

caso("Esc com o drawer fechado nao emite evento", () => {
    const { painel, document } = montarCenario();
    document._disparar("keydown", painel.teclar("Escape"));
    assert.equal(painel.disparados.filter((e) => e.type === "drawer:fechado").length, 0);
});

caso("o botao de fechar do rodape fecha o painel ancestral", () => {
    const { contexto, painel, botaoFecharRodape } = montarCenario();
    contexto.AppDrawer.abrir("drawer-area");
    botaoFecharRodape.clicar();
    assert.equal(painel.hasAttribute("data-drawer-aberto"), false, "o X/rodape deveria fechar");
});

caso("Tab no ultimo focavel volta para o primeiro", () => {
    const { contexto, painel, botaoX, botaoFecharRodape, document } = montarCenario();
    contexto.AppDrawer.abrir("drawer-area");
    document.activeElement = botaoFecharRodape;              // ultimo focavel
    const ev = painel.teclar("Tab");
    document._disparar("keydown", ev);
    assert.equal(ev.defaultPrevented, true, "deveria interceptar o Tab");
    assert.equal(document.activeElement, botaoX, "o foco deveria voltar ao primeiro");
});

caso("Shift+Tab no primeiro focavel vai para o ultimo", () => {
    const { contexto, painel, botaoX, botaoFecharRodape, document } = montarCenario();
    contexto.AppDrawer.abrir("drawer-area");
    document.activeElement = botaoX;                          // primeiro focavel
    const ev = painel.teclar("Tab", true);
    document._disparar("keydown", ev);
    assert.equal(ev.defaultPrevented, true);
    assert.equal(document.activeElement, botaoFecharRodape, "deveria ir para o ultimo");
});

caso("abrir e idempotente (nao reemite drawer:aberto)", () => {
    const { contexto, painel } = montarCenario();
    contexto.AppDrawer.abrir("drawer-area");
    contexto.AppDrawer.abrir("drawer-area");
    assert.equal(painel.disparados.filter((e) => e.type === "drawer:aberto").length, 1,
        "drawer:aberto deve sair uma vez so");
});

caso("fechar num drawer ja fechado nao emite evento", () => {
    const { contexto, painel } = montarCenario();
    contexto.AppDrawer.fechar("drawer-area");
    assert.equal(painel.disparados.filter((e) => e.type === "drawer:fechado").length, 0);
});

caso("aberto=true do servidor: ja aberto, foca e trava o scroll", () => {
    const { painel, body, document } = montarCenario({ aberto: true });
    assert.equal(painel.hasAttribute("data-drawer-aberto"), true);
    assert.equal(body.classes.has("app-drawer-trava-scroll"), true, "deveria travar o scroll no load");
    assert.equal(painel.disparados.filter((e) => e.type === "drawer:aberto").length, 1,
        "deveria emitir drawer:aberto no load");
    assert.notEqual(document.activeElement, body, "deveria focar dentro do painel");
});

caso("id desconhecido nao quebra", () => {
    const { contexto } = montarCenario();
    assert.equal(contexto.AppDrawer.abrir("nao-existe"), null);
    assert.equal(contexto.AppDrawer.fechar("nao-existe"), null);
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
console.log(`\n${casos.length - falhas}/${casos.length} casos de comportamento do drawer.js`);
process.exit(falhas === 0 ? 0 : 1);
