/*
 * Calendario de reservas — telas `admin/reservas/agenda.jsp` e `morador/reservas/agenda.jsp`,
 * montadas por `WEB-INF/jsp/fragments/reservas-agenda.jspf` (calendario) e
 * `reservas-agenda-paineis.jspf` (paineis).
 *
 * Contrato, congelado por `scripts/ui-agenda.sh` e `scripts/ui-invariants.sh`:
 *   #calendar        container do FullCalendar + configuracao por `data-*`
 *   #reservas-data   os `.reserva-data` que viram eventos (cada `data-*` e um dado)
 *   #filtro-area     filtro local por area (nao vai ao servidor)
 *   #drawer-reserva  ui:drawer com a lista de detalhes (`data-detalhe`)
 *   [data-drawer-editar="dialog-cancelamento"]  botao Cancelar do rodape do drawer
 *
 * O detalhe deixou de ser um painel no fim da pagina (S30) e o cancelamento deixou de ser
 * um form escondido nele: o detalhe e um `ui:drawer` e o cancelamento e um `ui:dialog`
 * centrado. O protocolo com o `drawer.js` e o mesmo das telas de tabela — o gatilho leva a
 * acao daquela reserva (`data-drawer-acao`) e o painel e reaproveitado por todos os eventos.
 */
(function () {
    var CORES_AREAS = [
        "#0d5c63",
        "#dba24a",
        "#167c5b",
        "#b64134",
        "#5f6c80",
        "#7c3aed",
        "#0ea5e9",
        "#c2410c"
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
            return { backgroundColor: cor, borderColor: cor, textColor: "#ffffff" };
        }
        if (status === "Negado") {
            return { backgroundColor: "#ffffff", borderColor: "#b64134", textColor: "#b64134" };
        }
        if (status === "Cancelado") {
            return { backgroundColor: "#e9edf2", borderColor: "#9aa4b2", textColor: "#5f6c80" };
        }
        return { backgroundColor: "#ffffff", borderColor: cor, textColor: cor };
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
        var painel = document.getElementById("drawer-reserva");
        var gatilhoCancelar = document.querySelector('[data-drawer-editar="dialog-cancelamento"]');

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
                window.AppDrawer.abrir("drawer-reserva");
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
