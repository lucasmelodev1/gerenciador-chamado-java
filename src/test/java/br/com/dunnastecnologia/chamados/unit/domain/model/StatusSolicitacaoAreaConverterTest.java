package br.com.dunnastecnologia.chamados.domain.model;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

class StatusSolicitacaoAreaConverterTest {

    private final StatusSolicitacaoAreaConverter converter = new StatusSolicitacaoAreaConverter();

    @Test
    void deveConverterStatusParaValorDoBanco() {
        assertEquals("Solicitado", converter.convertToDatabaseColumn(StatusSolicitacaoArea.SOLICITADO));
        assertEquals("Aprovado", converter.convertToDatabaseColumn(StatusSolicitacaoArea.APROVADO));
        assertEquals("Negado", converter.convertToDatabaseColumn(StatusSolicitacaoArea.NEGADO));
        assertEquals("Cancelado", converter.convertToDatabaseColumn(StatusSolicitacaoArea.CANCELADO));
    }

    @Test
    void deveConverterValorDoBancoParaStatusIgnorandoCaixa() {
        assertEquals(StatusSolicitacaoArea.APROVADO, converter.convertToEntityAttribute("aprovado"));
        assertEquals(StatusSolicitacaoArea.CANCELADO, converter.convertToEntityAttribute("CANCELADO"));
    }

    @Test
    void devePreservarNulos() {
        assertNull(converter.convertToDatabaseColumn(null));
        assertNull(converter.convertToEntityAttribute(null));
    }

    @Test
    void deveRecusarValorInvalido() {
        assertThrows(IllegalArgumentException.class, () -> converter.convertToEntityAttribute("Em analise"));
    }
}
