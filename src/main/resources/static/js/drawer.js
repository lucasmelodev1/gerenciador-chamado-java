/*
 * Drawer lateral (S23) — comportamento do componente `WEB-INF/tags/drawer.tag`.
 *
 * Nao ha <dialog> aqui: o painel e um <aside> posicionado por `position: fixed` e
 * animado com `translate` (ver `custom.css`), e o backdrop e um elemento irmao. Todo o
 * comportamento que o <dialog> daria de graca — Esc, foco preso, devolver o foco — e
 * implementado aqui de forma explicita.
 *
 * API:
 *   AppDrawer.abrir(id)           -> abre (idempotente)
 *   AppDrawer.fechar(id[, valor]) -> fecha; `valor` chega em detail.valor
 *   AppDrawer.eventoAbertura      -> "drawer:aberto"
 *   AppDrawer.eventoFechamento    -> "drawer:fechado"
 *
 * Eventos (disparados no painel, com bubbles, detalhe { id, valor }):
 *   drawer:fechado — X, Fechar, Esc ou clique fora
 *   drawer:aberto
 *
 *   document.addEventListener("drawer:fechado", function (evento) {
 *       console.log(evento.detail.id, evento.detail.valor);
 *   });
 */
(function () {
    var EVENTO_ABERTURA = "drawer:aberto";
    var EVENTO_FECHAMENTO = "drawer:fechado";
    var ATRIBUTO_ABERTO = "data-drawer-aberto";
    var CLASSE_TRAVA_SCROLL = "app-drawer-trava-scroll";

    var SELETOR_FOCAVEIS = [
        "a[href]",
        "button:not([disabled])",
        "input:not([disabled]):not([type=hidden])",
        "select:not([disabled])",
        "textarea:not([disabled])",
        '[tabindex]:not([tabindex="-1"])'
    ].join(",");

    // id do drawer -> elemento que tinha o foco antes de abrir (para devolver ao fechar)
    var focoAnterior = {};

    // id do drawer -> estado com que o servidor o renderizou (acao e titulo). Serve para
    // o gatilho "novo" devolver o formulario ao modo de criacao depois de uma edicao.
    var estadoInicial = {};

    function formDoPainel(painel) {
        return painel.querySelector("[data-drawer-form]");
    }

    function tituloDoPainel(painel) {
        return painel.querySelector("[data-drawer-titulo]");
    }

    function guardarInicial(painel) {
        var form = formDoPainel(painel);
        var titulo = tituloDoPainel(painel);
        estadoInicial[painel.id] = {
            acao: form ? form.getAttribute("action") : null,
            titulo: titulo ? titulo.textContent : null
        };
    }

    // Volta o formulario ao que o servidor renderizou: acao original, sem sobrescrita de
    // metodo e campos com os valores padrao (o `reset()` restaura os `value` do HTML).
    function reporInicial(painel) {
        var inicial = estadoInicial[painel.id];
        var form = formDoPainel(painel);
        if (form) {
            if (inicial && inicial.acao !== null) {
                form.setAttribute("action", inicial.acao);
            }
            form.reset();
        }

        var titulo = tituloDoPainel(painel);
        if (titulo && inicial && inicial.titulo !== null) {
            titulo.textContent = inicial.titulo;
        }
    }

    // Aplica o que o gatilho carrega: `data-drawer-acao`, `data-drawer-titulo` e um
    // `data-campo-<name>="<valor>"` por campo do formulario (inclusive `_method`).
    function aplicarGatilho(painel, gatilho) {
        var form = formDoPainel(painel);
        var acao = gatilho.getAttribute("data-drawer-acao");
        if (form && acao) {
            form.setAttribute("action", acao);
        }

        if (form) {
            Array.from(form.querySelectorAll("[name]")).forEach(function (campo) {
                var valor = gatilho.getAttribute("data-campo-" + campo.getAttribute("name"));
                if (valor !== null) {
                    campo.value = valor;
                }
            });
        }

        var titulo = gatilho.getAttribute("data-drawer-titulo");
        if (titulo) {
            var h2 = tituloDoPainel(painel);
            if (h2) {
                h2.textContent = titulo;
            }
        }
    }

    function painelPorId(id) {
        var alvo = id ? document.getElementById(id) : null;
        return alvo && alvo.hasAttribute("data-drawer") ? alvo : null;
    }

    function backdropPorId(id) {
        return document.getElementById(id + "-backdrop");
    }

    function estaAberto(painel) {
        return painel.hasAttribute(ATRIBUTO_ABERTO);
    }

    function avisar(painel, nome, valor) {
        painel.dispatchEvent(new CustomEvent(nome, {
            bubbles: true,
            detail: { id: painel.id, valor: valor || "" }
        }));
    }

    function focaveis(painel) {
        return Array.from(painel.querySelectorAll(SELETOR_FOCAVEIS));
    }

    function marcar(id, aberto) {
        var painel = painelPorId(id);
        if (!painel) {
            return null;
        }

        var backdrop = backdropPorId(id);
        if (aberto) {
            painel.setAttribute(ATRIBUTO_ABERTO, "");
            if (backdrop) {
                backdrop.setAttribute(ATRIBUTO_ABERTO, "");
            }
        } else {
            painel.removeAttribute(ATRIBUTO_ABERTO);
            if (backdrop) {
                backdrop.removeAttribute(ATRIBUTO_ABERTO);
            }
        }
        return painel;
    }

    function travarScroll() {
        document.body.classList.add(CLASSE_TRAVA_SCROLL);
    }

    // So destrava quando nao sobrar nenhum drawer aberto.
    function destravarScroll() {
        if (!window.AppDom.bySelector("[data-drawer][" + ATRIBUTO_ABERTO + "]").length) {
            document.body.classList.remove(CLASSE_TRAVA_SCROLL);
        }
    }

    function focarPrimeiro(painel) {
        var primeiro = focaveis(painel)[0];
        if (primeiro && primeiro.focus) {
            primeiro.focus();
        }
    }

    function abrir(id) {
        var painel = painelPorId(id);
        if (!painel || estaAberto(painel)) {
            return painel;
        }

        focoAnterior[id] = document.activeElement;
        marcar(id, true);
        travarScroll();
        focarPrimeiro(painel);
        avisar(painel, EVENTO_ABERTURA, "");
        return painel;
    }

    function fechar(id, valor) {
        var painel = painelPorId(id);
        if (!painel || !estaAberto(painel)) {
            return painel;
        }

        marcar(id, false);
        destravarScroll();

        var anterior = focoAnterior[id];
        if (anterior && anterior.focus) {
            anterior.focus();
        }
        delete focoAnterior[id];

        avisar(painel, EVENTO_FECHAMENTO, valor);
        return painel;
    }

    function primeiroAberto() {
        return window.AppDom.bySelector("[data-drawer][" + ATRIBUTO_ABERTO + "]")[0] || null;
    }

    // Esc fecha e Tab fica preso no painel — o que o <dialog> faria sozinho.
    function aoTeclar(evento) {
        var painel = primeiroAberto();
        if (!painel) {
            return;
        }

        if (evento.key === "Escape" || evento.key === "Esc") {
            evento.preventDefault();
            fechar(painel.id);
            return;
        }

        if (evento.key !== "Tab") {
            return;
        }

        var lista = focaveis(painel);
        if (!lista.length) {
            return;
        }

        var primeiro = lista[0];
        var ultimo = lista[lista.length - 1];
        var ativo = document.activeElement;

        if (evento.shiftKey && (ativo === primeiro || ativo === painel)) {
            evento.preventDefault();
            ultimo.focus();
        } else if (!evento.shiftKey && ativo === ultimo) {
            evento.preventDefault();
            primeiro.focus();
        }
    }

    document.addEventListener("keydown", aoTeclar);

    window.AppDom.onReady(function () {
        window.AppDom.bySelector("[data-drawer]").forEach(guardarInicial);

        window.AppDom.bySelector("[data-drawer-backdrop]").forEach(function (backdrop) {
            backdrop.addEventListener("click", function () {
                fechar(backdrop.getAttribute("data-drawer-backdrop"));
            });
        });

        // Criar: devolve o formulario ao estado renderizado pelo servidor antes de abrir.
        window.AppDom.bySelector("[data-drawer-abrir]").forEach(function (gatilho) {
            gatilho.addEventListener("click", function (evento) {
                // O gatilho abre o drawer; nao navega nem envia formulario — e o que
                // evita o reload que deixava o drawer fechado depois de editar.
                evento.preventDefault();
                var painel = painelPorId(gatilho.getAttribute("data-drawer-abrir"));
                if (painel) {
                    reporInicial(painel);
                }
                abrir(gatilho.getAttribute("data-drawer-abrir"));
            });
        });

        // Editar: mesmo drawer, preenchido com o que o gatilho carrega.
        window.AppDom.bySelector("[data-drawer-editar]").forEach(function (gatilho) {
            gatilho.addEventListener("click", function (evento) {
                evento.preventDefault();
                var id = gatilho.getAttribute("data-drawer-editar");
                var painel = painelPorId(id);
                if (painel) {
                    aplicarGatilho(painel, gatilho);
                }
                abrir(id);
            });
        });

        // Vale para botoes de fechar que nao estejam no topo/rodape do painel.
        window.AppDom.bySelector("[data-drawer-fechar]").forEach(function (botao) {
            botao.addEventListener("click", function () {
                var painel = botao.closest("[data-drawer]");
                if (painel) {
                    fechar(painel.id);
                }
            });
        });

        // Render do servidor: o painel ja veio aberto no HTML (sem piscar). Falta so
        // aplicar o que o HTML nao carrega: trava de scroll, foco e o evento.
        window.AppDom.bySelector("[data-drawer][" + ATRIBUTO_ABERTO + "]").forEach(function (painel) {
            focoAnterior[painel.id] = document.activeElement;
            travarScroll();
            focarPrimeiro(painel);
            avisar(painel, EVENTO_ABERTURA, "");
        });
    });

    window.AppDrawer = {
        abrir: abrir,
        fechar: fechar,
        eventoAbertura: EVENTO_ABERTURA,
        eventoFechamento: EVENTO_FECHAMENTO
    };
})();
