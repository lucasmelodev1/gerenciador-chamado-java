/*
 * S23 — Teste de comportamento do `drawer.js` sem navegador.
 *
 * O ambiente nao tem browser, entao a unica forma de EXECUTAR o JS (em vez de so
 * inspecionar a fonte) e um DOM minimo em Node. Nao e um teste de renderizacao: e um
 * teste da logica de abrir/fechar/evento/foco/conteudo — que e onde mora o risco real,
 * ainda mais agora que o componente nao usa <dialog> e todo o comportamento e manual.
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
        // suficiente para `input.value` / `form.reset()` do drawer
        this.valorPadrao = this.hasAttribute("value") ? this.getAttribute("value") : "";
        this.value = this.valorPadrao;
        this.textContent = "";
    }
    reset() {
        const visitar = (no) => no._filhos.forEach((f) => {
            f.value = f.valorPadrao;
            visitar(f);
        });
        visitar(this);
        return this;
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
    matches(sel) { return casar(this, sel); }
    querySelector(sel) {
        return this.querySelectorAll(sel)[0] || null;
    }
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
// Espelha o markup de drawer.tag + o gatilho de editar da tela de areas.

function montarCenario({ aberto = false } = {}) {
    const painel = new El("aside", { id: "drawer-area", "data-drawer": "" });

    const titulo = new El("h2", { id: "drawer-area-titulo", "data-drawer-titulo": "" });
    titulo.textContent = "Nova area";
    const botaoX = new El("button", { "data-drawer-fechar": "" });
    const cabecalho = new El("header");
    [titulo, botaoX].forEach((f) => cabecalho.appendChild(f));

    const form = new El("form", {
        id: "drawer-area-form", "data-drawer-form": "", action: "/admin/areas", method: "post",
    });
    const campoMetodo = new El("input", { type: "hidden", name: "_method", value: "" });
    const campoNome = new El("input", { name: "nome", value: "" });
    const campoStatus = new El("select", { name: "status", value: "" });
    [campoMetodo, campoNome, campoStatus].forEach((f) => form.appendChild(f));

    const botaoSalvar = new El("button", { type: "submit", form: "drawer-area-form" });
    const rodape = new El("footer");
    rodape.appendChild(botaoSalvar);

    [cabecalho, form, rodape].forEach((f) => painel.appendChild(f));

    const backdrop = new El("div", { id: "drawer-area-backdrop", "data-drawer-backdrop": "drawer-area" });

    // "Nova area"
    const gatilho = new El("button", { "data-drawer-abrir": "drawer-area" });

    // "Editar" de uma linha da tabela
    const gatilhoEditar = new El("button", {
        "data-drawer-editar": "drawer-area",
        "data-drawer-titulo": "Editar area",
        "data-drawer-acao": "/admin/areas/abc",
        "data-campo-_method": "patch",
        "data-campo-nome": "Piscina",
        "data-campo-status": "Inativo",
    });

    if (aberto) {
        painel.setAttribute("data-drawer-aberto", "");
        backdrop.setAttribute("data-drawer-aberto", "");
    }

    const elementos = [painel, backdrop, gatilho, gatilhoEditar, botaoX, botaoSalvar, campoNome, campoStatus];
    const ambiente = criarAmbiente(elementos);
    ambiente.document.body.appendChild(backdrop);
    ambiente.document.body.appendChild(painel);
    ambiente.document.body.appendChild(gatilho);
    ambiente.document.body.appendChild(gatilhoEditar);

    ambiente.document._disparar("DOMContentLoaded", new CustomEvent("DOMContentLoaded"));
    return {
        ...ambiente, painel, backdrop, gatilho, gatilhoEditar, botaoX, botaoSalvar,
        form, titulo, campoMetodo, campoNome, campoStatus,
    };
}

// ---------------------------------------------------------------- cenario (S26)
// Campos do gatilho como INPUTS ESCONDIDOS dentro do botao (formato do tag
// `ui:acao-painel`) + um campo travado, que a edicao nao pode mudar.

function montarCenarioTravado() {
    const painel = new El("aside", { id: "drawer-usuario", "data-drawer": "" });

    const titulo = new El("h2", { id: "drawer-usuario-titulo", "data-drawer-titulo": "" });
    titulo.textContent = "Novo usuario";
    const botaoX = new El("button", { "data-drawer-fechar": "" });
    const cabecalho = new El("header");
    [titulo, botaoX].forEach((f) => cabecalho.appendChild(f));

    const form = new El("form", {
        id: "drawer-usuario-form", "data-drawer-form": "", action: "/admin/usuarios", method: "post",
        "data-drawer-travar": "tipo",
    });
    const campoMetodo = new El("input", { type: "hidden", name: "_method", value: "" });
    const campoNome = new El("input", { name: "nome", value: "" });
    const campoTipo = new El("select", { name: "tipo", value: "" });
    const campoSenha = new El("input", { type: "password", name: "senha", value: "" });
    // Espelho renderizado pelo `ui:drawer`: mesmo `name`, desabilitado no modo criacao.
    const espelhoTipo = new El("input", { type: "hidden", name: "tipo", "data-drawer-espelho": "tipo" });
    espelhoTipo.disabled = true;
    [campoMetodo, campoNome, campoTipo, campoSenha, espelhoTipo].forEach((f) => form.appendChild(f));

    const botaoSalvar = new El("button", { type: "submit", form: "drawer-usuario-form" });
    const rodape = new El("footer");
    rodape.appendChild(botaoSalvar);
    [cabecalho, form, rodape].forEach((f) => painel.appendChild(f));

    const backdrop = new El("div", { id: "drawer-usuario-backdrop", "data-drawer-backdrop": "drawer-usuario" });

    const gatilhoNovo = new El("button", { "data-drawer-abrir": "drawer-usuario" });

    // "Editar": os valores vao em inputs escondidos DENTRO do botao.
    const gatilhoEditar = new El("button", {
        "data-drawer-editar": "drawer-usuario",
        "data-drawer-titulo": "Editar usuario",
        "data-drawer-acao": "/admin/usuarios/abc",
    });
    [
        new El("input", { type: "hidden", "data-campo": "_method", value: "patch" }),
        new El("input", { type: "hidden", "data-campo": "nome", value: "Ana" }),
        new El("input", { type: "hidden", "data-campo": "tipo", value: "MORADOR" }),
    ].forEach((f) => gatilhoEditar.appendChild(f));

    const elementos = [painel, backdrop, gatilhoNovo, gatilhoEditar, botaoX, botaoSalvar, campoNome, campoTipo];
    const ambiente = criarAmbiente(elementos);
    ambiente.document.body.appendChild(backdrop);
    ambiente.document.body.appendChild(painel);
    ambiente.document.body.appendChild(gatilhoNovo);
    ambiente.document.body.appendChild(gatilhoEditar);

    ambiente.document._disparar("DOMContentLoaded", new CustomEvent("DOMContentLoaded"));
    return {
        ...ambiente, painel, backdrop, gatilhoNovo, gatilhoEditar, titulo, form,
        campoMetodo, campoNome, campoTipo, campoSenha, espelhoTipo,
    };
}

// ---------------------------------------------------------------- cenario (S30)
// Dois paineis empilhados: o drawer de detalhe da reserva e o dialogo de cancelamento que
// ele abre por cima (botao declarado pelo `painelAcao` do `ui:drawer`).

function montarCenarioEmpilhado() {
    const deBaixo = new El("aside", { id: "drawer-reserva", "data-drawer": "" });
    const xBaixo = new El("button", { "data-drawer-fechar": "" });
    deBaixo.appendChild(xBaixo);
    const backdropBaixo = new El("div", {
        id: "drawer-reserva-backdrop", "data-drawer-backdrop": "drawer-reserva",
    });

    const deCima = new El("aside", { id: "dialog-cancelamento", "data-drawer": "" });
    const xCima = new El("button", { "data-drawer-fechar": "" });
    const confirmar = new El("button", { type: "submit" });
    deCima.appendChild(xCima);
    deCima.appendChild(confirmar);
    const backdropCima = new El("div", {
        id: "dialog-cancelamento-backdrop", "data-drawer-backdrop": "dialog-cancelamento",
    });

    // O gatilho e o botao Cancelar do rodape do drawer informativo.
    const gatilho = new El("button", {
        "data-drawer-editar": "dialog-cancelamento",
        "data-drawer-acao": "/admin/reservas/r1",
        "data-campo-_method": "delete",
    });

    const elementos = [deBaixo, backdropBaixo, deCima, backdropCima, gatilho, xBaixo, xCima, confirmar];
    const ambiente = criarAmbiente(elementos);
    ambiente.document.body.appendChild(backdropBaixo);
    ambiente.document.body.appendChild(deBaixo);
    ambiente.document.body.appendChild(backdropCima);
    ambiente.document.body.appendChild(deCima);
    ambiente.document.body.appendChild(gatilho);

    ambiente.document._disparar("DOMContentLoaded", new CustomEvent("DOMContentLoaded"));
    return { ...ambiente, deBaixo, deCima, backdropBaixo, backdropCima, gatilho, xBaixo, xCima, confirmar };
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
    assert.equal(ev.defaultPrevented, true, "o gatilho nao pode navegar (era o reload que quebrava)");
});

caso("abrir move o foco para o primeiro focavel do painel", () => {
    const { contexto, document, botaoX } = montarCenario();
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

caso("o X fecha o painel ancestral", () => {
    const { contexto, painel, botaoX } = montarCenario();
    contexto.AppDrawer.abrir("drawer-area");
    botaoX.clicar();
    assert.equal(painel.hasAttribute("data-drawer-aberto"), false, "o X deveria fechar");
});

caso("Tab no ultimo focavel volta para o primeiro", () => {
    const { contexto, painel, botaoX, botaoSalvar, document } = montarCenario();
    contexto.AppDrawer.abrir("drawer-area");
    document.activeElement = botaoSalvar;                    // ultimo focavel
    const ev = painel.teclar("Tab");
    document._disparar("keydown", ev);
    assert.equal(ev.defaultPrevented, true, "deveria interceptar o Tab");
    assert.equal(document.activeElement, botaoX, "o foco deveria voltar ao primeiro");
});

caso("Shift+Tab no primeiro focavel vai para o ultimo", () => {
    const { contexto, painel, botaoX, botaoSalvar, document } = montarCenario();
    contexto.AppDrawer.abrir("drawer-area");
    document.activeElement = botaoX;                         // primeiro focavel
    const ev = painel.teclar("Tab", true);
    document._disparar("keydown", ev);
    assert.equal(ev.defaultPrevented, true);
    assert.equal(document.activeElement, botaoSalvar, "deveria ir para o ultimo");
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

// --- conteudo dinamico (o que conserta o "salvar nao fecha" e o "segundo clique") ---

caso("o gatilho de editar preenche acao, _method, campos e titulo", () => {
    const { gatilhoEditar, form, campoMetodo, campoNome, campoStatus, titulo, painel } = montarCenario();
    gatilhoEditar.clicar();

    assert.equal(form.getAttribute("action"), "/admin/areas/abc", "acao deveria ser a da area");
    assert.equal(campoMetodo.value, "patch", "_method deveria virar patch");
    assert.equal(campoNome.value, "Piscina", "o campo nome deveria ser preenchido");
    assert.equal(campoStatus.value, "Inativo", "o campo status deveria ser preenchido");
    assert.equal(titulo.textContent, "Editar area", "o titulo deveria mudar");
    assert.equal(painel.hasAttribute("data-drawer-aberto"), true, "deveria abrir");
});

caso("depois de editar, o gatilho de novo devolve o formulario ao modo de criacao", () => {
    const { gatilhoEditar, gatilho, form, campoMetodo, campoNome, campoStatus, titulo } = montarCenario();

    gatilhoEditar.clicar();
    contextoFechar();
    gatilho.clicar();

    assert.equal(form.getAttribute("action"), "/admin/areas", "a acao deveria voltar para a de criacao");
    assert.equal(campoMetodo.value, "", "_method deveria voltar a vazio (POST)");
    assert.equal(campoNome.value, "", "o nome deveria ser limpo");
    assert.equal(campoStatus.value, "", "o status deveria ser limpo");
    assert.equal(titulo.textContent, "Nova area", "o titulo deveria voltar ao de criacao");
});

caso("o gatilho de novo abre em um clique, sem reload", () => {
    const { gatilho, painel } = montarCenario();
    const ev = gatilho.clicar();
    assert.equal(ev.defaultPrevented, true, "nao pode navegar");
    assert.equal(painel.hasAttribute("data-drawer-aberto"), true, "deveria abrir de primeira");
});

caso("id desconhecido nao quebra", () => {
    const { contexto } = montarCenario();
    assert.equal(contexto.AppDrawer.abrir("nao-existe"), null);
    assert.equal(contexto.AppDrawer.fechar("nao-existe"), null);
});

// fecha o drawer aberto pelo cenario anterior, para o caso seguinte comecar limpo
function contextoFechar() {
    const aberto = ambienteAtual.document.querySelectorAll("[data-drawer][data-drawer-aberto]")[0];
    if (aberto) ambienteAtual.AppDrawer.fechar(aberto.id);
}

// --- campos do gatilho como inputs escondidos + campo travado (S26) ---

caso("o gatilho com inputs escondidos preenche acao, _method, campos e titulo", () => {
    const { gatilhoEditar, form, campoMetodo, campoNome, campoTipo, titulo, painel } = montarCenarioTravado();
    gatilhoEditar.clicar();

    assert.equal(form.getAttribute("action"), "/admin/usuarios/abc", "acao deveria ser a do usuario");
    assert.equal(campoMetodo.value, "patch", "_method deveria virar patch");
    assert.equal(campoNome.value, "Ana", "o nome deveria vir do input escondido");
    assert.equal(campoTipo.value, "MORADOR", "o tipo deveria vir do input escondido");
    assert.equal(titulo.textContent, "Editar usuario", "o titulo deveria mudar");
    assert.equal(painel.hasAttribute("data-drawer-aberto"), true, "deveria abrir");
});

caso("campo travado: desabilita o controle e o espelho passa a enviar o valor", () => {
    const { gatilhoEditar, campoTipo, espelhoTipo } = montarCenarioTravado();
    gatilhoEditar.clicar();

    assert.equal(campoTipo.disabled, true, "o controle visivel deveria ficar desabilitado na edicao");
    assert.equal(espelhoTipo.disabled, false, "o espelho deveria assumir o envio");
    assert.equal(espelhoTipo.value, "MORADOR", "o espelho deveria carregar o valor atual");
});

caso("campo travado volta ao normal no modo de criacao", () => {
    const { gatilhoEditar, gatilhoNovo, campoTipo, espelhoTipo } = montarCenarioTravado();
    gatilhoEditar.clicar();
    contextoFechar();
    gatilhoNovo.clicar();

    assert.equal(campoTipo.disabled, false, "a criacao precisa poder escolher o valor");
    assert.equal(espelhoTipo.disabled, true, "o espelho deveria voltar a ficar fora do envio");
    assert.equal(espelhoTipo.value, "", "o espelho nao pode vazar o valor da edicao anterior");
    assert.equal(campoTipo.value, "", "o campo deveria voltar ao padrao do HTML");
});

caso("o formato antigo (data-campo-* no botao) continua valendo", () => {
    const { gatilhoEditar, form, campoMetodo, campoNome, campoStatus } = montarCenario();
    gatilhoEditar.clicar();
    assert.equal(form.getAttribute("action"), "/admin/areas/abc");
    assert.equal(campoMetodo.value, "patch");
    assert.equal(campoNome.value, "Piscina");
    assert.equal(campoStatus.value, "Inativo");
});

caso("uma edicao nao herda o que foi digitado na edicao anterior", () => {
    const { gatilhoEditar, campoSenha } = montarCenarioTravado();
    gatilhoEditar.clicar();
    campoSenha.value = "digitado-na-edicao-1";   // a `senha` nao vem do gatilho
    contextoFechar();
    gatilhoEditar.clicar();

    assert.equal(campoSenha.value, "", "campo nao declarado pelo gatilho deveria voltar ao padrao");
    assert.equal(campoSenha.disabled, undefined, "campo comum nao deve ser tocado pelo travamento");
});

// --- paineis empilhados: o de cima e quem responde (S30) ---

caso("empilhado: Esc fecha o painel de cima, nao o de baixo", () => {
    const { contexto, document, deBaixo, deCima, gatilho } = montarCenarioEmpilhado();
    contexto.AppDrawer.abrir("drawer-reserva");
    gatilho.clicar();                       // o `drawer.js` le a acao do gatilho e abre o dialogo
    assert.equal(deCima.hasAttribute("data-drawer-aberto"), true, "o dialogo deveria abrir");

    document._disparar("keydown", deCima.teclar("Escape"));
    assert.equal(deCima.hasAttribute("data-drawer-aberto"), false, "Esc deveria fechar o de cima");
    assert.equal(deBaixo.hasAttribute("data-drawer-aberto"), true, "o de baixo continua aberto");
});

caso("empilhado: o foco preso vale para o painel de cima", () => {
    const { contexto, document, deCima, gatilho, xCima, confirmar } = montarCenarioEmpilhado();
    contexto.AppDrawer.abrir("drawer-reserva");
    gatilho.clicar();

    document.activeElement = confirmar;     // ultimo focavel do painel de cima
    const ev = deCima.teclar("Tab");
    document._disparar("keydown", ev);
    assert.equal(ev.defaultPrevented, true, "deveria interceptar o Tab");
    assert.equal(document.activeElement, xCima, "o foco deveria voltar ao primeiro do de cima");
});

caso("empilhado: o scroll so destrava quando nao sobra painel aberto", () => {
    const { contexto, body, deBaixo, gatilho } = montarCenarioEmpilhado();
    contexto.AppDrawer.abrir("drawer-reserva");
    gatilho.clicar();

    contexto.AppDrawer.fechar("dialog-cancelamento");
    assert.equal(body.classes.has("app-drawer-trava-scroll"), true,
        "com o drawer de baixo aberto a pagina continua travada");

    contexto.AppDrawer.fechar("drawer-reserva");
    assert.equal(deBaixo.hasAttribute("data-drawer-aberto"), false);
    assert.equal(body.classes.has("app-drawer-trava-scroll"), false, "sem painel aberto, destrava");
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
