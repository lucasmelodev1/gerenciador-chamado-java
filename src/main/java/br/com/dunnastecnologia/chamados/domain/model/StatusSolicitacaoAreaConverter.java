package br.com.dunnastecnologia.chamados.domain.model;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter
public class StatusSolicitacaoAreaConverter implements AttributeConverter<StatusSolicitacaoArea, String> {

    @Override
    public String convertToDatabaseColumn(StatusSolicitacaoArea status) {
        return status == null ? null : status.getValor();
    }

    @Override
    public StatusSolicitacaoArea convertToEntityAttribute(String valor) {
        return valor == null ? null : StatusSolicitacaoArea.fromValor(valor);
    }
}
