(function () {
    function initConfirmations() {
        window.AppDom.bySelector("form[data-confirm]").forEach(function (form) {
            form.addEventListener("submit", function (event) {
                if (!window.confirm(form.getAttribute("data-confirm"))) {
                    event.preventDefault();
                }
            });
        });
    }

    function initPasswordToggle() {
        window.AppDom.bySelector("[data-password-toggle]").forEach(function (button) {
            button.addEventListener("click", function () {
                var campo = button.closest("[data-password-campo]");
                if (!campo) {
                    return;
                }

                var input = campo.querySelector("[data-password-input]");
                if (!input) {
                    return;
                }

                var oculta = input.type === "password";
                input.type = oculta ? "text" : "password";

                // O glifo (olho / olho cortado) e escolhido pelo CSS a partir de `aria-pressed`;
                // aqui so o estado e o rotulo acessivel mudam.
                var rotulo = oculta ? "Ocultar senha" : "Mostrar senha";
                button.setAttribute("aria-pressed", oculta ? "true" : "false");
                button.setAttribute("aria-label", rotulo);
                button.setAttribute("data-tip", rotulo);
            });
        });
    }

    function initCharacterCount() {
        window.AppDom.bySelector("[data-character-count]").forEach(function (field) {
            var output = field.parentElement.querySelector("[data-character-output]");
            if (!output) {
                return;
            }

            var sync = function () {
                var total = field.value.length;
                var max = field.getAttribute("maxlength");
                if (max) {
                    output.textContent = total + "/" + max + " caracteres";
                    return;
                }

                output.textContent = total + (total === 1 ? " caractere" : " caracteres");
            };

            field.addEventListener("input", sync);
            sync();
        });
    }

    function initAutoSubmit() {
        window.AppDom.bySelector("[data-auto-submit]").forEach(function (field) {
            field.addEventListener("change", function () {
                var form = field.form;
                if (form) {
                    form.submit();
                }
            });
        });
    }

    window.AppDom.onReady(function () {
        initConfirmations();
        initPasswordToggle();
        initCharacterCount();
        initAutoSubmit();
    });
})();
