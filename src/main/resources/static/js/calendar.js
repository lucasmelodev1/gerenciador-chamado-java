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

    function mostrarDetalhe(painel, formularios, evento) {
        var dados = evento.extendedProps;
        var solicitado = dados.status === "Solicitado";
        var podeCancelar = solicitado || dados.status === "Aprovado";

        painel.querySelector(".reserva-titulo").textContent = dados.area;
        painel.querySelector(".reserva-meta").textContent =
            dados.morador + " - " + dados.unidade + " - " +
            dados.inicioFormatado + " a " + dados.fimFormatado + " - " + dados.status;
        painel.querySelector(".reserva-motivo").textContent =
            dados.motivo ? "Motivo da negacao: " + dados.motivo : "";

        if (formularios.aprovar) {
            formularios.aprovar.hidden = !solicitado;
            formularios.aprovar.action = formularios.base + "/" + dados.id + "/aprovacao";
        }
        if (formularios.negar) {
            formularios.negar.hidden = !solicitado;
            formularios.negar.action = formularios.base + "/" + dados.id + "/negacao";
        }
        formularios.cancelar.hidden = !podeCancelar;
        formularios.cancelar.action = formularios.base + "/" + dados.id;
        painel.hidden = false;
    }

    function initCalendario() {
        var container = document.getElementById("calendar");
        if (!container || typeof FullCalendar === "undefined") {
            return;
        }

        var base = container.getAttribute("data-base-url");
        var initialView = container.getAttribute("data-view") === "semana" ? "timeGridWeek" : "dayGridMonth";
        var eventos = window.AppDom.bySelector("#reservas-data .reserva-data").map(montarEvento);
        var painel = document.getElementById("reserva-detalhe");
        var formularios = {
            base: base,
            aprovar: document.getElementById("form-aprovar"),
            negar: document.getElementById("form-negar"),
            cancelar: document.getElementById("form-cancelar")
        };

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
                mostrarDetalhe(painel, formularios, info.event);
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

        var fechar = document.getElementById("reserva-fechar");
        if (fechar) {
            fechar.addEventListener("click", function () {
                painel.hidden = true;
            });
        }
    }

    window.AppDom.onReady(initCalendario);
})();
