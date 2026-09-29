package br.com.dunnastecnologia.chamados.domain.model;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

class StatusAreaConverterTest {

    private final StatusAreaConverter converter = new StatusAreaConverter();

    @Test
    void deveConverterStatusParaValorDoBanco() {
        assertEquals("Ativo", converter.convertToDatabaseColumn(StatusArea.ATIVO));
        assertEquals("Inativo", converter.convertToDatabaseColumn(StatusArea.INATIVO));
    }

    @Test
    void deveConverterValorDoBancoParaStatusIgnorandoCaixa() {
        assertEquals(StatusArea.ATIVO, converter.convertToEntityAttribute("ativo"));
        assertEquals(StatusArea.INATIVO, converter.convertToEntityAttribute("INATIVO"));
    }

    @Test
    void devePreservarNulos() {
        assertNull(converter.convertToDatabaseColumn(null));
        assertNull(converter.convertToEntityAttribute(null));
    }

    @Test
    void deveRecusarValorInvalido() {
        assertThrows(IllegalArgumentException.class, () -> converter.convertToEntityAttribute("Pendente"));
    }
}
