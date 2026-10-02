/*
 * S30 — Teste de comportamento do `calendar.js` sem navegador.
 *
 * O ambiente nao tem browser, entao a unica forma de EXECUTAR o JS (em vez de so inspecionar
 * a fonte) e um DOM minimo em Node, com um FullCalendar de mentira: o stub guarda a
 * configuracao passada e deixa o teste disparar o `eventClick` como o calendario faria.
 *
 * O risco desta mudanca nao esta no CSS. Esta em tres coisas que so rodando aparecem:
 *   1. o clique no evento precisa ABRIR o drawer e PREENCHER a lista de detalhes;
 *   2. a acao de cancelar e reescrita a cada evento (`data-drawer-acao`) — o mesmo dialogo
 *      serve todas as reservas;
 *   3. o `_method=delete` tem de chegar ao form do dialogo pelo `drawer.js` de verdade.
 * Por isso o cenario carrega `core.js`, `drawer.js` e `calendar.js` juntos, e o caso do
 * cancelamento termina clicando no botao — nao so conferindo o atributo.
 *
 * O cenario abaixo espelha o markup que `reservas-agenda.jspf` +
 * `reservas-agenda-paineis.jspf` renderizam; quem garante que o HTML de verdade tem essa
 * forma e `scripts/ui-agenda.sh` (secao A).
 *
 *   node scripts/ui-calendar-js.mjs    -> imprime os casos e sai 1 na primeira falha
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

// Casa um composto simples: `tag`, `.classe`, `[attr]`, `[attr="valor"]`.
function casarComposto(el, composto) {
    const tag = composto.match(/^[a-z]+/i);
    if (tag && el.tagName !== tag[0].toUpperCase()) return false;
    for (const classe of composto.matchAll(/\.([A-Za-z0-9_-]+)/g)) {
        if (!el.classes.has(classe[1])) return false;
    }
    return [...composto.matchAll(/\[([^\]=]+)(?:=("?)([^"\]]*)\2)?\]/g)]
        .every((m) => (m[3] === undefined ? el.hasAttribute(m[1]) : el.getAttribute(m[1]) === m[3]));
}

// Suporta descendencia (`#reservas-data .reserva-data`), que o calendar.js usa.
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
        this.hidden = false;
        this._texto = "";
        this._filhos = [];
        this._listeners = {};
        this.disparados = [];
        this.classes = new Set(String(attrs.class || "").split(/\s+/).filter(Boolean));

        const dono = this;
        this.classList = {
            add: (c) => dono.classes.add(c),
            remove: (c) => dono.classes.delete(c),
            contains: (c) => dono.classes.has(c),
        };

        // `elemento.dataset` como o do navegador: `data-inicio-formatado` -> `inicioFormatado`.
        this.dataset = {};
        for (const [chave, valor] of Object.entries(this.attrs)) {
            if (!chave.startsWith("data-")) continue;
            this.dataset[chave.slice(5).replace(/-([a-z])/g, (_, letra) => letra.toUpperCase())] = valor;
        }

        this.value = this.hasAttribute("value") ? this.getAttribute("value") : "";
        this.valorPadrao = this.value;
    }

    // O suficiente para o `form.reset()` do `drawer.js` (reporInicial).
    reset() {
        const visitar = (no) => no._filhos.forEach((f) => {
            f.value = f.valorPadrao;
            visitar(f);
        });
        visitar(this);
        return this;
    }

    get textContent() { return this._texto + this._filhos.map((f) => f.textContent).join(""); }
    set textContent(v) { this._texto = String(v); }

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
    matches(sel) { return casar(this, sel); }
    closest(sel) {
        let atual = this;
        while (atual) {
            if (atual.matches(sel)) return atual;
            atual = atual.parent;
        }
        return null;
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
    focus() { ambienteAtual.document.activeElement = this; }
    clicar() {
        const ev = new CustomEvent("click", { bubbles: true });
        ev.target = this;
        this.dispatchEvent(ev);
        return ev;
    }
    trocar(valor) {
        this.value = valor;
        const ev = new CustomEvent("change", { bubbles: true });
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

// FullCalendar de mentira: guarda a configuracao e deixa o teste disparar o `eventClick`.
class CalendarioFalso {
    constructor(container, config) {
        this.container = container;
        this.config = config;
        this.eventos = config.events.slice();
        this.trocas = [];
        this.renderizado = false;
        ultimoCalendario = this;
    }
    render() { this.renderizado = true; }
    removeAllEvents() { this.eventos = []; }
    addEventSource(lista) { this.trocas.push(lista); this.eventos = this.eventos.concat(lista); }
    clicarEvento(id) {
        const evento = this.eventos.find((e) => e.id === id);
        if (!evento) throw new Error(`evento ${id} nao esta no calendario`);
        this.config.eventClick({ event: evento });
    }
}

let ambienteAtual = null;
let ultimoCalendario = null;

function criarAmbiente(elementos) {
    const body = new El("body");
    const document = {
        body,
        activeElement: body,
        _listeners: {},
        addEventListener(t, fn) { (this._listeners[t] ||= []).push(fn); },
        getElementById(id) { return elementos.find((e) => e.id === id) || null; },
        querySelector(sel) { return body.querySelector(sel); },
        querySelectorAll(sel) { return body.querySelectorAll(sel); },
        _disparar(t, ev) { (this._listeners[t] || []).forEach((fn) => fn(ev)); },
    };
    const contexto = vm.createContext({ window: {}, document, CustomEvent, console });
    contexto.window = contexto;
    contexto.window.document = document;
    contexto.window.CustomEvent = CustomEvent;
    contexto.document = document;
    contexto.FullCalendar = { Calendar: CalendarioFalso };
    ambienteAtual = contexto;

    for (const arq of ["core.js", "drawer.js", "calendar.js"]) {
        vm.runInContext(
            fs.readFileSync(`src/main/resources/static/js/${arq}`, "utf8"),
            contexto,
            { filename: arq },
        );
    }
    return { contexto, document, body };
}

// ---------------------------------------------------------------- cenario

// Espelha um `<span class="reserva-data">` de reservas-agenda.jspf.
function reserva(dados) {
    return new El("span", {
        class: "reserva-data",
        "data-id": dados.id,
        "data-area-id": dados.areaId || "area-1",
        "data-start": dados.inicio,
        "data-end": dados.fim,
        "data-area": dados.area || "Piscina",
        "data-morador": dados.morador || "Ana",
        "data-unidade": dados.unidade === undefined ? "CA-01-01" : dados.unidade,
        "data-status": dados.status || "Solicitado",
        "data-inicio-formatado": dados.inicioFormatado || "01/03/2026 10:00",
        "data-fim-formatado": dados.fimFormatado || "01/03/2026 12:00",
        "data-motivo": dados.motivo || "",
    });
}

const CAMPOS_DETALHE = ["area", "morador", "unidade", "inicio", "fim", "status", "motivo"];

function montarCenario({ view = "mes", reservas = [] } = {}) {
    const container = new El("div", {
        id: "calendar",
        "data-view": view,
        "data-referencia": "2026-03-01",
        "data-base-url": "/admin/reservas",
        "data-modo": "admin",
        "data-painel-detalhe": "drawer-reserva",
    });

    const dados = new El("div", { id: "reservas-data", class: "reservas-data" });
    reservas.forEach((r) => dados.appendChild(reserva(r)));

    const filtro = new El("select", { id: "filtro-area" });
    filtro.appendChild(new El("option", { value: "" }));
    filtro.appendChild(new El("option", { value: "area-1" }));

    // ui:drawer informativo (`reservas-agenda-paineis.jspf`)
    const painel = new El("aside", { id: "drawer-reserva", "data-drawer": "" });
    const cabecalho = new El("header", { class: "app-drawer-topo" });
    const titulo = new El("h2", { id: "drawer-reserva-titulo", "data-drawer-titulo": "" });
    titulo.textContent = "Detalhes da reserva";
    cabecalho.appendChild(titulo);
    const botaoX = new El("button", { type: "button", "data-drawer-fechar": "" });
    cabecalho.appendChild(botaoX);

    const corpo = new El("div", { class: "app-drawer-corpo" });
    const lista = new El("dl", { class: "app-detalhe-lista" });
    const linhas = {};
    for (const campo of CAMPOS_DETALHE) {
        const linha = new El("div", { class: "app-detalhe-linha" });
        linha.appendChild(new El("dt", { class: "app-detalhe-rotulo" }));
        const valor = new El("dd", { class: "app-detalhe-valor", "data-detalhe": campo });
        linha.appendChild(valor);
        lista.appendChild(linha);
        linhas[campo] = { linha, valor };
    }
    corpo.appendChild(lista);

    const rodape = new El("footer", { class: "app-drawer-rodape" });
    const cancelar = new El("button", {
        type: "button",
        class: "btn btn-error",
        "data-drawer-editar": "dialog-cancelamento",
        "data-campo-_method": "delete",
    });
    const fechar = new El("button", { type: "button", class: "btn", "data-drawer-fechar": "" });
    fechar.textContent = "Fechar";
    rodape.appendChild(cancelar);
    rodape.appendChild(fechar);

    [cabecalho, corpo, rodape].forEach((f) => painel.appendChild(f));
    const backdrop = new El("div", { id: "drawer-reserva-backdrop", "data-drawer-backdrop": "drawer-reserva" });

    // ui:dialog de cancelamento
    const dialogo = new El("aside", { id: "dialog-cancelamento", "data-drawer": "" });
    const form = new El("form", {
        id: "dialog-cancelamento-form",
        "data-drawer-form": "",
        method: "post",
        action: "/admin/reservas",
        class: "app-dialog-corpo app-dialog-corpo--vazio",
    });
    form.appendChild(new El("input", { type: "hidden", name: "_csrf", value: "token" }));
    const campoMetodo = new El("input", { type: "hidden", name: "_method", value: "" });
    form.appendChild(campoMetodo);
    dialogo.appendChild(form);
    const backdropDialogo = new El("div", {
        id: "dialog-cancelamento-backdrop", "data-drawer-backdrop": "dialog-cancelamento",
    });

    const elementos = [container, dados, filtro, painel, backdrop, dialogo, backdropDialogo, botaoX, cancelar, fechar];
    const ambiente = criarAmbiente(elementos);
    [container, dados, filtro, backdrop, painel, backdropDialogo, dialogo].forEach((e) => {
        ambiente.document.body.appendChild(e);
    });

    ambiente.document._disparar("DOMContentLoaded", new CustomEvent("DOMContentLoaded"));
    return {
        ...ambiente, container, dados, filtro, painel, backdrop, dialogo, form, campoMetodo,
        cancelar, fechar, botaoX, linhas,
    };
}

const RESERVA_1 = {
    id: "r1", areaId: "area-1", inicio: "2099-03-01T10:00", fim: "2099-03-01T12:00",
    area: "Piscina", morador: "Ana", unidade: "CA-01-01", status: "Solicitado",
    inicioFormatado: "01/03/2099 10:00", fimFormatado: "01/03/2099 12:00",
};

const RESERVA_2 = {
    id: "r2", areaId: "area-2", inicio: "2099-03-02T14:00", fim: "2099-03-02T16:00",
    area: "Salão", morador: "Bruno", unidade: "CB-02-05", status: "Aprovado",
    inicioFormatado: "02/03/2099 14:00", fimFormatado: "02/03/2099 16:00",
};

// ---------------------------------------------------------------- casos

const casos = [];
function caso(nome, fn) { casos.push([nome, fn]); }

caso("monta o calendario com a view e os eventos do periodo", () => {
    montarCenario({ reservas: [RESERVA_1, RESERVA_2] });
    const cal = ultimoCalendario;
    assert.equal(cal.renderizado, true, "deveria renderizar");
    assert.equal(cal.config.initialView, "dayGridMonth", "data-view=mes deveria ser dayGridMonth");
    assert.equal(cal.config.initialDate, "2026-03-01", "a data de referencia deveria ser a do HTML");
    assert.equal(cal.config.locale, "pt-br");
    assert.equal(cal.config.headerToolbar, false, "a toolbar do FullCalendar nao pode aparecer");
    assert.equal(cal.eventos.length, 2, "deveria montar um evento por .reserva-data");
    assert.equal(cal.eventos[0].id, "r1");
    assert.equal(cal.eventos[0].title, "Piscina - Ana");
    assert.equal(cal.eventos[0].start, "2099-03-01T10:00");
    assert.equal(cal.eventos[0].extendedProps.unidade, "CA-01-01");
});

caso("data-view=semana monta a view de semana", () => {
    montarCenario({ view: "semana", reservas: [RESERVA_1] });
    assert.equal(ultimoCalendario.config.initialView, "timeGridWeek");
});

caso("status pinta o evento: Solicitado vazado, Aprovado cheio", () => {
    montarCenario({ reservas: [RESERVA_1, RESERVA_2] });
    const [solicitado, aprovado] = ultimoCalendario.eventos;
    assert.equal(solicitado.backgroundColor, "#ffffff", "solicitado deveria ser vazado");
    assert.equal(solicitado.borderColor, solicitado.textColor, "a borda e o texto usam a cor da area");
    assert.notEqual(aprovado.backgroundColor, "#ffffff", "aprovado deveria ser cheio");
    assert.equal(aprovado.backgroundColor, aprovado.borderColor);
});

caso("clicar no evento abre o drawer e preenche a lista de detalhes", () => {
    const { painel, linhas, body } = montarCenario({ reservas: [RESERVA_1] });
    ultimoCalendario.clicarEvento("r1");

    assert.equal(painel.hasAttribute("data-drawer-aberto"), true, "o drawer deveria abrir");
    assert.equal(body.classes.has("app-drawer-trava-scroll"), true, "deveria travar o scroll");
    assert.equal(linhas.area.valor.textContent, "Piscina");
    assert.equal(linhas.morador.valor.textContent, "Ana");
    assert.equal(linhas.unidade.valor.textContent, "CA-01-01");
    assert.equal(linhas.inicio.valor.textContent, "01/03/2099 10:00");
    assert.equal(linhas.fim.valor.textContent, "01/03/2099 12:00");
    assert.equal(linhas.status.valor.textContent, "Solicitado");
    assert.equal(painel.querySelector("[data-drawer-titulo]").textContent, "Detalhes da reserva",
        "o titulo nao deveria mudar a cada clique");
});

caso("valor ausente vira '-'", () => {
    const { linhas } = montarCenario({ reservas: [{ ...RESERVA_1, unidade: "" }] });
    ultimoCalendario.clicarEvento("r1");
    assert.equal(linhas.unidade.valor.textContent, "-");
});

caso("a linha Motivo aparece so quando ha motivo", () => {
    const { linhas } = montarCenario({
        reservas: [RESERVA_1, { ...RESERVA_2, id: "r3", status: "Negado", motivo: "Manutenção" }],
    });
    ultimoCalendario.clicarEvento("r1");
    assert.equal(linhas.motivo.linha.hidden, true, "sem motivo a linha inteira sai");
    assert.equal(linhas.motivo.valor.textContent, "-");

    ultimoCalendario.clicarEvento("r3");
    assert.equal(linhas.motivo.linha.hidden, false, "com motivo a linha volta");
    assert.equal(linhas.motivo.valor.textContent, "Manutenção");
});

caso("o detalhe de uma reserva nao vaza para a seguinte", () => {
    const { linhas } = montarCenario({ reservas: [RESERVA_1, RESERVA_2] });
    ultimoCalendario.clicarEvento("r1");
    ultimoCalendario.clicarEvento("r2");
    assert.equal(linhas.area.valor.textContent, "Salão");
    assert.equal(linhas.morador.valor.textContent, "Bruno");
    assert.equal(linhas.status.valor.textContent, "Aprovado");
});

caso("o mesmo drawer e reaproveitado: o segundo clique nao reabre", () => {
    const { painel } = montarCenario({ reservas: [RESERVA_1, RESERVA_2] });
    ultimoCalendario.clicarEvento("r1");
    ultimoCalendario.clicarEvento("r2");
    assert.equal(painel.hasAttribute("data-drawer-aberto"), true);
    assert.equal(painel.disparados.filter((e) => e.type === "drawer:aberto").length, 1,
        "o evento de abertura deveria sair uma vez so (abrir e idempotente)");
});

caso("Cancelar aponta a acao da reserva clicada e abre o dialogo com _method=delete", () => {
    const { cancelar, dialogo, form, campoMetodo } = montarCenario({ reservas: [RESERVA_1, RESERVA_2] });

    ultimoCalendario.clicarEvento("r1");
    assert.equal(cancelar.getAttribute("data-drawer-acao"), "/admin/reservas/r1",
        "o gatilho deveria levar a acao da reserva clicada");
    assert.equal(cancelar.hidden, false, "reserva solicitada e futura pode ser cancelada");

    // O clique passa pelo `drawer.js` de verdade: e ele que copia a acao e o `_method`.
    cancelar.clicar();
    assert.equal(dialogo.hasAttribute("data-drawer-aberto"), true, "o dialogo deveria abrir");
    assert.equal(form.getAttribute("action"), "/admin/reservas/r1");
    assert.equal(campoMetodo.value, "delete", "_method deveria chegar como delete");
});

caso("a acao de cancelar e reescrita a cada reserva", () => {
    const { cancelar, form } = montarCenario({ reservas: [RESERVA_1, RESERVA_2] });
    ultimoCalendario.clicarEvento("r1");
    cancelar.clicar();
    assert.equal(form.getAttribute("action"), "/admin/reservas/r1");

    ultimoCalendario.clicarEvento("r2");
    assert.equal(cancelar.getAttribute("data-drawer-acao"), "/admin/reservas/r2");
    cancelar.clicar();
    assert.equal(form.getAttribute("action"), "/admin/reservas/r2",
        "a acao nao pode ficar presa na reserva anterior");
});

caso("Cancelar some quando o servidor recusaria a acao", () => {
    const { cancelar } = montarCenario({
        reservas: [
            { ...RESERVA_1, id: "negado", status: "Negado" },
            { ...RESERVA_1, id: "cancelado", status: "Cancelado" },
            { ...RESERVA_1, id: "passado", status: "Aprovado", inicio: "2000-03-01T10:00" },
            { ...RESERVA_1, id: "futuro", status: "Aprovado" },
        ],
    });

    for (const id of ["negado", "cancelado", "passado"]) {
        ultimoCalendario.clicarEvento(id);
        assert.equal(cancelar.hidden, true, `${id} nao pode oferecer Cancelar`);
    }
    ultimoCalendario.clicarEvento("futuro");
    assert.equal(cancelar.hidden, false, "aprovada e futura continua cancelavel");
});

caso("o Fechar do rodape fecha o drawer", () => {
    const { painel, fechar, body } = montarCenario({ reservas: [RESERVA_1] });
    ultimoCalendario.clicarEvento("r1");
    fechar.clicar();
    assert.equal(painel.hasAttribute("data-drawer-aberto"), false, "deveria fechar");
    assert.equal(body.classes.has("app-drawer-trava-scroll"), false, "deveria destravar o scroll");
});

caso("com o dialogo aberto, Esc fecha o dialogo (o de cima) e nao o drawer", () => {
    const { document, painel, dialogo, cancelar } = montarCenario({ reservas: [RESERVA_1] });
    ultimoCalendario.clicarEvento("r1");
    cancelar.clicar();

    document._disparar("keydown", dialogo.teclar("Escape"));
    assert.equal(dialogo.hasAttribute("data-drawer-aberto"), false, "Esc deveria fechar o dialogo");
    assert.equal(painel.hasAttribute("data-drawer-aberto"), true, "o drawer de baixo continua aberto");
});

caso("o filtro por area e local: troca a fonte de eventos sem recarregar", () => {
    const { filtro } = montarCenario({ reservas: [RESERVA_1, RESERVA_2] });
    filtro.trocar("area-1");

    assert.equal(ultimoCalendario.trocas.length, 1, "deveria trocar a fonte uma vez");
    assert.equal(ultimoCalendario.trocas[0].length, 1);
    assert.equal(ultimoCalendario.trocas[0][0].extendedProps.areaId, "area-1");

    filtro.trocar("");
    assert.equal(ultimoCalendario.trocas[1].length, 2, "sem area deveria voltar tudo");
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
console.log(`\n${casos.length - falhas}/${casos.length} casos de comportamento do calendar.js`);
process.exit(falhas === 0 ? 0 : 1);
