package br.com.dunnastecnologia.chamados.domain.model;

public enum StatusSolicitacaoArea {

    SOLICITADO("Solicitado"),
    APROVADO("Aprovado"),
    NEGADO("Negado"),
    CANCELADO("Cancelado");

    private final String valor;

    StatusSolicitacaoArea(String valor) {
        this.valor = valor;
    }

    public String getValor() {
        return valor;
    }

    public static StatusSolicitacaoArea fromValor(String valor) {
        for (StatusSolicitacaoArea status : values()) {
            if (status.valor.equalsIgnoreCase(valor)) {
                return status;
            }
        }
        throw new IllegalArgumentException("Status de solicitacao de area invalido: " + valor);
    }
}
