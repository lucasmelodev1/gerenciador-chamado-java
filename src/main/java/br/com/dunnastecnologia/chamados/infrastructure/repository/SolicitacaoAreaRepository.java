package br.com.dunnastecnologia.chamados.infrastructure.repository;

import br.com.dunnastecnologia.chamados.domain.model.SolicitacaoArea;
import br.com.dunnastecnologia.chamados.domain.model.StatusSolicitacaoArea;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SolicitacaoAreaRepository extends JpaRepository<SolicitacaoArea, UUID> {

    /**
     * Lista apenas as reservas do morador autenticado (soft-deleted sao filtradas pelo Hibernate).
     */
    Page<SolicitacaoArea> findByMoradorId(UUID moradorId, Pageable pageable);

    /**
     * Busca uma reserva garantindo a posse do morador, sem revelar reservas de terceiros.
     */
    Optional<SolicitacaoArea> findByIdAndMoradorId(UUID id, UUID moradorId);

    /**
     * Reservas que ocupam ou disputam a area na janela [inicio, fim): apenas Solicitado e Aprovado
     * interessam. Usa intersecao de intervalos, para nao ignorar reservas que comecam antes da janela
     * e terminam dentro dela (reservas que atravessam a meia-noite).
     */
    @Query("""
            select s from SolicitacaoArea s
            where s.area.id = :areaId
              and s.status in :statuses
              and s.inicio < :fim
              and s.fim > :inicio
            order by s.inicio
            """)
    List<SolicitacaoArea> buscarDisponibilidade(
            @Param("areaId") UUID areaId,
            @Param("inicio") LocalDateTime inicio,
            @Param("fim") LocalDateTime fim,
            @Param("statuses") Collection<StatusSolicitacaoArea> statuses
    );

    /**
     * Reservas que disputam (Solicitado) ou ocupam (Aprovado) qualquer horario dentro da janela
     * [inicio, fim), inclusive as que comecam antes e terminam dentro (intersecao de intervalos).
     */
    @Query("""
            select s from SolicitacaoArea s
            where s.status in :statuses
              and s.inicio < :fim
              and s.fim > :inicio
            order by s.inicio
            """)
    List<SolicitacaoArea> buscarNoPeriodo(
            @Param("inicio") LocalDateTime inicio,
            @Param("fim") LocalDateTime fim,
            @Param("statuses") Collection<StatusSolicitacaoArea> statuses
    );

    /**
     * Reservas do morador que intersectam a janela [inicio, fim), em qualquer status, para o
     * acompanhamento do ciclo de vida na agenda. Soft-deleted sao filtradas pelo Hibernate.
     */
    @Query("""
            select s from SolicitacaoArea s
            where s.morador.id = :moradorId
              and s.inicio < :fim
              and s.fim > :inicio
            order by s.inicio
            """)
    List<SolicitacaoArea> buscarDoMoradorNoPeriodo(
            @Param("moradorId") UUID moradorId,
            @Param("inicio") LocalDateTime inicio,
            @Param("fim") LocalDateTime fim
    );

    /**
     * Existe outra reserva APROVADA da mesma area cujo intervalo sobrepoe [inicio, fim)?
     * Evita abortar a transacao no caso comum; o EXCLUDE da migration V20 e a garantia final contra corrida.
     */
    boolean existsByAreaIdAndStatusAndInicioLessThanAndFimGreaterThanAndIdNot(
            UUID areaId,
            StatusSolicitacaoArea status,
            LocalDateTime fim,
            LocalDateTime inicio,
            UUID id
    );
}
