package br.com.dunnastecnologia.chamados.domain.model;

public enum StatusArea {

    ATIVO("Ativo"),
    INATIVO("Inativo");

    private final String valor;

    StatusArea(String valor) {
        this.valor = valor;
    }

    public String getValor() {
        return valor;
    }

    public static StatusArea fromValor(String valor) {
        for (StatusArea status : values()) {
            if (status.valor.equalsIgnoreCase(valor)) {
                return status;
            }
        }
        throw new IllegalArgumentException("Status de area invalido: " + valor);
    }
}
