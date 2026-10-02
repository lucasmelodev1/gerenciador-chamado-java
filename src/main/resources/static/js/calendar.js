/*
 * Calendario de reservas — telas `admin/reservas/agenda.jsp` e `morador/reservas/agenda.jsp`,
 * montadas por `WEB-INF/jsp/fragments/reservas-agenda.jspf` (calendario) e
 * `reservas-agenda-paineis.jspf` (paineis).
 *
 * Contrato, congelado por `scripts/ui-agenda.sh` e `scripts/ui-invariants.sh`:
 *   #calendar        container do FullCalendar + configuracao por `data-*`
 *   #reservas-data   os `.reserva-data` que viram eventos (cada `data-*` e um dado)
 *   #filtro-area     filtro local por area (nao vai ao servidor)
 *   data-painel-detalhe  no #calendar: id do painel de detalhe (o fragmento declara; o JS
 *                        nao conhece o id `drawer-reserva`)
 *   [data-drawer-editar] dentro do painel: botao Cancelar do rodape (o JS acha pelo painel,
 *                        nao pelo id `dialog-cancelamento`)
 *
 * O detalhe deixou de ser um painel no fim da pagina (S30) e o cancelamento deixou de ser
 * um form escondido nele: o detalhe e um `ui:drawer` e o cancelamento e um `ui:dialog`
 * centrado. O protocolo com o `drawer.js` e o mesmo das telas de tabela — o gatilho leva a
 * acao daquela reserva (`data-drawer-acao`) e o painel e reaproveitado por todos os eventos.
 *
 * A paleta dos eventos vive em `css/calendar.css` (tokens `--reserva-*`), lida por
 * `token()`; os literais abaixo sao o fallback de quando nao ha CSS (o harness em Node, por
 * exemplo). Sem isso a cor de cada status era um hex duplicado aqui e no tema.
 */
(function () {
    function token(nome, padrao) {
        if (typeof window.getComputedStyle !== "function" || !document.documentElement) {
            return padrao;
        }
        var valor = window.getComputedStyle(document.documentElement).getPropertyValue(nome);
        return valor && valor.trim() ? valor.trim() : padrao;
    }

    var CORES_AREAS = [
        token("--reserva-cor-1", "#0d5c63"),
        token("--reserva-cor-2", "#dba24a"),
        token("--reserva-cor-3", "#167c5b"),
        token("--reserva-cor-4", "#b64134"),
        token("--reserva-cor-5", "#5f6c80"),
        token("--reserva-cor-6", "#7c3aed"),
        token("--reserva-cor-7", "#0ea5e9"),
        token("--reserva-cor-8", "#c2410c")
    ];

    function corDaArea(areaId) {
        var texto = areaId || "";
        var soma = 0;
        for (var i = 0; i < texto.length; i++) {
            soma += texto.charCodeAt(i);
        }
        return CORES_AREAS[soma % CORES_AREAS.length];
    }

    function estiloDoStatus(status, cor) {
        if (status === "Aprovado") {
            return {
                backgroundColor: cor,
                borderColor: cor,
                textColor: token("--reserva-cor-texto", "#ffffff")
            };
        }
        if (status === "Negado") {
            var corNegado = token("--reserva-negado-cor", "#b64134");
            return {
                backgroundColor: token("--reserva-negado-fundo", "#ffffff"),
                borderColor: corNegado,
                textColor: corNegado
            };
        }
        if (status === "Cancelado") {
            return {
                backgroundColor: token("--reserva-cancelado-fundo", "#e9edf2"),
                borderColor: token("--reserva-cancelado-borda", "#9aa4b2"),
                textColor: token("--reserva-cancelado-texto", "#5f6c80")
            };
        }
        return {
            backgroundColor: token("--reserva-pendente-fundo", "#ffffff"),
            borderColor: cor,
            textColor: cor
        };
    }

    function montarEvento(elemento) {
        var dados = Object.assign({}, elemento.dataset);
        var estilo = estiloDoStatus(dados.status, corDaArea(dados.areaId));
        return {
            id: dados.id,
            title: dados.area + " - " + dados.morador,
            start: dados.start,
            end: dados.end,
            backgroundColor: estilo.backgroundColor,
            borderColor: estilo.borderColor,
            textColor: estilo.textColor,
            extendedProps: dados
        };
    }

    // Preenche um valor da lista de detalhes. O gancho vem do `ui:detalhe-linha`
    // (`data-detalhe="<campo>"`). Ausente vira "-", a mesma convencao da coluna Motivo da
    // lista de reservas.
    function definir(painel, campo, valor) {
        var alvo = painel.querySelector('[data-detalhe="' + campo + '"]');
        if (alvo) {
            alvo.textContent = valor || "-";
        }
    }

    // Motivo so existe em reserva negada; nas outras a LINHA inteira sai, em vez de sobrar
    // um campo vazio no meio da lista.
    function definirMotivo(painel, motivo) {
        var alvo = painel.querySelector('[data-detalhe="motivo"]');
        if (!alvo) {
            return;
        }
        alvo.textContent = motivo || "-";
        var linha = alvo.closest(".app-detalhe-linha");
        if (linha) {
            linha.hidden = !motivo;
        }
    }

    function mostrarDetalhe(painel, dados) {
        if (!painel) {
            return;
        }
        definir(painel, "area", dados.area);
        definir(painel, "morador", dados.morador);
        definir(painel, "unidade", dados.unidade);
        definir(painel, "inicio", dados.inicioFormatado);
        definir(painel, "fim", dados.fimFormatado);
        definir(painel, "status", dados.status);
        definirMotivo(painel, dados.motivo);
    }

    // A acao do dialogo de cancelamento muda a cada evento: o `drawer.js` le
    // `data-drawer-acao` no clique, entao basta reescrever o atributo do gatilho (que e o
    // botao Cancelar do rodape do drawer — ver `ui:drawer` > `painelAcao`).
    //
    // A acao so aparece quando o servidor aceitaria: reserva solicitada ou aprovada
    // (`cancelar` recusa os outros status) e ainda nao iniciada (`SolicitacaoAreaService`
    // recusa reserva com inicio ja alcancado).
    function apontarCancelamento(gatilho, base, dados) {
        if (!gatilho) {
            return;
        }
        var decidivel = dados.status === "Solicitado" || dados.status === "Aprovado";
        var inicio = new Date(dados.start);
        var futuro = !isNaN(inicio.getTime()) && inicio.getTime() > Date.now();
        gatilho.hidden = !(decidivel && futuro);
        gatilho.setAttribute("data-drawer-acao", base + "/" + dados.id);
    }

    function initCalendario() {
        var container = document.getElementById("calendar");
        if (!container || typeof FullCalendar === "undefined") {
            return;
        }

        var base = container.getAttribute("data-base-url");
        var initialView = container.getAttribute("data-view") === "semana" ? "timeGridWeek" : "dayGridMonth";
        var eventos = window.AppDom.bySelector("#reservas-data .reserva-data").map(montarEvento);
        // O painel de detalhe e declarado pelo fragmento (`data-painel-detalhe`), nao pelo id:
        // renomear `drawer-reserva` deixa de ser um contrato implicito com este arquivo.
        var painel = document.getElementById(container.getAttribute("data-painel-detalhe"));
        // O gatilho do cancelamento e o botao do rodape DESTE painel (o `painelAcao` do
        // `ui:drawer`), entao o id do dialogo nao aparece aqui.
        var gatilhoCancelar = painel ? painel.querySelector("[data-drawer-editar]") : null;

        var calendario = new FullCalendar.Calendar(container, {
            initialView: initialView,
            initialDate: container.getAttribute("data-referencia"),
            locale: "pt-br",
            dayMaxEvents: true,
            headerToolbar: false,
            eventTimeFormat: {
                hour: "2-digit",
                minute: "2-digit",
                hour12: false
            },
            events: eventos,
            eventClick: function (info) {
                var dados = info.event.extendedProps;
                mostrarDetalhe(painel, dados);
                apontarCancelamento(gatilhoCancelar, base, dados);
                if (painel) {
                    window.AppDrawer.abrir(painel.id);
                }
            }
        });
        calendario.render();

        var selecao = document.getElementById("filtro-area");
        if (selecao) {
            selecao.addEventListener("change", function () {
                var areaId = selecao.value;
                var filtrados = areaId
                    ? eventos.filter(function (evento) {
                        return evento.extendedProps.areaId === areaId;
                    })
                    : eventos;
                calendario.removeAllEvents();
                calendario.addEventSource(filtrados);
            });
        }
    }

    window.AppDom.onReady(initCalendario);
})();
