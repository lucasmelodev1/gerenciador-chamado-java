package br.com.dunnastecnologia.chamados.domain.model;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter
public class StatusAreaConverter implements AttributeConverter<StatusArea, String> {

    @Override
    public String convertToDatabaseColumn(StatusArea status) {
        return status == null ? null : status.getValor();
    }

    @Override
    public StatusArea convertToEntityAttribute(String valor) {
        return valor == null ? null : StatusArea.fromValor(valor);
    }
}
