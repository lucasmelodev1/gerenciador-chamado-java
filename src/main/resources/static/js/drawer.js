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
 *
 * Um painel pode abrir outro por cima: o botao declarado por `painelAcao` de um `ui:drawer`
 * informativo abre um `ui:dialog`. Nesse caso Esc, Tab e o foco preso valem para o painel de
 * CIMA (o ultimo aberto), e o de baixo continua aberto por tras.
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

    // Ids dos paineis abertos, na ordem de abertura. Um painel pode abrir outro por cima
    // (o detalhe da reserva abre o dialogo de cancelamento), e nesse caso Esc, Tab e o foco
    // pertencem ao de CIMA — que e o ultimo aberto e o mesmo que o CSS pinta por cima.
    var abertos = [];

    function registrarAbertura(id) {
        if (abertos.indexOf(id) === -1) {
            abertos.push(id);
        }
    }

    function registrarFechamento(id) {
        var indice = abertos.indexOf(id);
        if (indice !== -1) {
            abertos.splice(indice, 1);
        }
    }

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
            alternarTravados(form, false);
        }

        var titulo = tituloDoPainel(painel);
        if (titulo && inicial && inicial.titulo !== null) {
            titulo.textContent = inicial.titulo;
        }
    }

    // Valor de um campo do gatilho. Duas formas, as duas suportadas:
    //   1. `data-campo-<name>="<valor>"` no proprio botao (formato da S23);
    //   2. `<input data-campo="<name>" value="<valor>">` DENTRO do botao (S26, o formato
    //      que o tag `ui:acao-editar` usa).
    // A forma 2 vence quando as duas definem o mesmo campo: como `value` de um input, o
    // dado do usuario passa pelo escape normal do HTML e nao precisa de codificacao em
    // string (um nome com `;` ou `|` quebraria qualquer formato concatenado).
    function valorDoGatilho(gatilho, nome) {
        var filho = gatilho.querySelector('[data-campo="' + nome + '"]');
        if (filho) {
            return filho.value;
        }
        return gatilho.getAttribute("data-campo-" + nome);
    }

    // Campos que a edicao NAO pode mudar (ex.: o perfil de um usuario — o servidor
    // recusa a troca). O par controle visivel + espelho escondido ja vem renderizado
    // pelo `ui:drawer`; aqui so se escolhe qual dos dois envia, porque campo
    // `disabled` nao e submetido.
    function nomesTravados(form) {
        var lista = form.getAttribute("data-drawer-travar");
        return lista ? lista.split(/[,\s]+/).filter(Boolean) : [];
    }

    function alternarTravados(form, travado) {
        nomesTravados(form).forEach(function (nome) {
            var campo = form.querySelector('[name="' + nome + '"]:not([data-drawer-espelho])');
            var espelho = form.querySelector('[data-drawer-espelho="' + nome + '"]');
            if (!campo || !espelho) {
                return;
            }
            if (travado) {
                espelho.value = campo.value;
            } else {
                espelho.value = "";
            }
            campo.disabled = travado;
            espelho.disabled = !travado;
        });
    }

    // Aplica o que o gatilho carrega: `data-drawer-acao`, `data-drawer-titulo` e um
    // valor por campo do formulario (inclusive `_method`), nas duas formas acima.
    function aplicarGatilho(painel, gatilho) {
        var form = formDoPainel(painel);
        var acao = gatilho.getAttribute("data-drawer-acao");
        if (form && acao) {
            form.setAttribute("action", acao);
        }

        if (form) {
            Array.from(form.querySelectorAll("[name]")).forEach(function (campo) {
                var valor = valorDoGatilho(gatilho, campo.getAttribute("name"));
                if (valor !== null && valor !== undefined) {
                    campo.value = valor;
                }
            });
            alternarTravados(form, true);
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
            registrarAbertura(id);
        } else {
            painel.removeAttribute(ATRIBUTO_ABERTO);
            if (backdrop) {
                backdrop.removeAttribute(ATRIBUTO_ABERTO);
            }
            registrarFechamento(id);
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

    // Painel de cima: o ultimo aberto (ver `abertos`). Com um painel so, e ele mesmo.
    function painelDoTopo() {
        var id = abertos[abertos.length - 1];
        return id ? painelPorId(id) : null;
    }

    // Esc fecha e Tab fica preso no painel — o que o <dialog> faria sozinho. Quem responde
    // e o painel de CIMA: fechar o de baixo com um dialogo aberto por cima seria surpresa.
    function aoTeclar(evento) {
        var painel = painelDoTopo();
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

        // Editar: mesmo drawer, preenchido com o que o gatilho carrega. Passa antes pelo
        // estado inicial porque nem todo campo e declarado pelo gatilho (a `senha` de
        // usuario, por exemplo): sem o reset, o que foi digitado numa edicao vazaria
        // para a edicao seguinte.
        window.AppDom.bySelector("[data-drawer-editar]").forEach(function (gatilho) {
            gatilho.addEventListener("click", function (evento) {
                evento.preventDefault();
                var id = gatilho.getAttribute("data-drawer-editar");
                var painel = painelPorId(id);
                if (painel) {
                    reporInicial(painel);
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
            registrarAbertura(painel.id);
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
