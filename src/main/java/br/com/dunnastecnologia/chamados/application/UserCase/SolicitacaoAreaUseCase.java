package br.com.dunnastecnologia.chamados.application.UserCase;

import br.com.dunnastecnologia.chamados.application.Security.AuthenticatedUser;
import br.com.dunnastecnologia.chamados.application.pagination.PageResult;
import br.com.dunnastecnologia.chamados.domain.model.Area;
import br.com.dunnastecnologia.chamados.domain.model.SolicitacaoArea;
import org.springframework.data.domain.PageRequest;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface SolicitacaoAreaUseCase {

    /**
     * Cria uma solicitacao de reserva para uma area comum em nome do morador autenticado,
     * sempre no estado inicial SOLICITADO. A unidade informada precisa estar vinculada ao morador.
     */
    SolicitacaoArea solicitarReserva(
            AuthenticatedUser morador,
            UUID areaId,
            UUID unidadeId,
            LocalDateTime inicio,
            LocalDateTime fim
    );

    /**
     * Lista apenas as reservas do morador autenticado, sem expor reservas de terceiros.
     */
    PageResult<SolicitacaoArea> listarMinhasReservas(
            AuthenticatedUser morador,
            PageRequest pageRequest
    );

    /**
     * Lista as reservas do morador autenticado que intersectam a janela [inicio, fim), em qualquer
     * status, para o acompanhamento do ciclo de vida na agenda/calendario.
     */
    List<SolicitacaoArea> listarMinhasReservasNoPeriodo(
            AuthenticatedUser morador,
            LocalDateTime inicio,
            LocalDateTime fim
    );

    /**
     * Retorna as reservas que ocupam (APROVADO) ou disputam (SOLICITADO) a area na data informada,
     * para o morador planejar a solicitacao antes de envia-la.
     */
    List<SolicitacaoArea> consultarDisponibilidade(
            AuthenticatedUser morador,
            UUID areaId,
            LocalDate data
    );

    /**
     * Lista as areas ativas para o morador escolher ao solicitar uma reserva.
     */
    List<Area> listarAreasDisponiveis(
            AuthenticatedUser morador
    );

    /**
     * Cancela uma reserva do proprio morador quando ela ainda esta SOLICITADO ou APROVADO e o inicio nao ocorreu.
     */
    void cancelarMinhaReserva(
            AuthenticatedUser morador,
            UUID reservaId
    );

    /**
     * Lista as reservas de todos os moradores para o administrador acompanhar a agenda unica.
     */
    PageResult<SolicitacaoArea> listarReservas(
            AuthenticatedUser admin,
            PageRequest pageRequest
    );

    /**
     * Lista as reservas Solicitadas e Aprovadas que intersectam a janela [inicio, fim) para o
     * calendario do administrador. A janela e limitada para evitar consultas de periodo ilimitado.
     */
    List<SolicitacaoArea> listarReservasNoPeriodo(
            AuthenticatedUser admin,
            LocalDateTime inicio,
            LocalDateTime fim
    );

    /**
     * Aprova uma solicitacao sem conflito com outra reserva aprovada da mesma area no instante da decisao.
     */
    SolicitacaoArea aprovarReserva(
            AuthenticatedUser admin,
            UUID reservaId
    );

    /**
     * Nega uma solicitacao registrando um motivo nao vazio, preservando a decisao no historico.
     */
    SolicitacaoArea negarReserva(
            AuthenticatedUser admin,
            UUID reservaId,
            String motivo
    );

    /**
     * Cancela uma reserva SOLICITADO ou APROVADO cujo inicio ainda nao ocorreu.
     */
    void cancelarReserva(
            AuthenticatedUser admin,
            UUID reservaId
    );
}
