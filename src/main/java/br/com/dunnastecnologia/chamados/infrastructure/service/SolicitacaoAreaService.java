package br.com.dunnastecnologia.chamados.infrastructure.service;

import br.com.dunnastecnologia.chamados.application.Security.AuthenticatedUser;
import br.com.dunnastecnologia.chamados.application.UserCase.SolicitacaoAreaUseCase;
import br.com.dunnastecnologia.chamados.application.pagination.PageResult;
import br.com.dunnastecnologia.chamados.domain.model.Area;
import br.com.dunnastecnologia.chamados.domain.model.Morador;
import br.com.dunnastecnologia.chamados.domain.model.SolicitacaoArea;
import br.com.dunnastecnologia.chamados.domain.model.StatusArea;
import br.com.dunnastecnologia.chamados.domain.model.StatusSolicitacaoArea;
import br.com.dunnastecnologia.chamados.domain.model.Unidade;
import br.com.dunnastecnologia.chamados.domain.validation.ValidationLimits;
import br.com.dunnastecnologia.chamados.infrastructure.exception.BusinessRuleException;
import br.com.dunnastecnologia.chamados.infrastructure.exception.ResourceNotFoundException;
import br.com.dunnastecnologia.chamados.infrastructure.repository.AreaRepository;
import br.com.dunnastecnologia.chamados.infrastructure.repository.MoradorRepository;
import br.com.dunnastecnologia.chamados.infrastructure.repository.SolicitacaoAreaRepository;
import br.com.dunnastecnologia.chamados.infrastructure.repository.UnidadeRepository;
import br.com.dunnastecnologia.chamados.infrastructure.service.support.AuthenticatedUserValidator;
import br.com.dunnastecnologia.chamados.infrastructure.service.support.InputValidationSupport;
import br.com.dunnastecnologia.chamados.infrastructure.service.support.PageResultMapper;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@Transactional(readOnly = true)
public class SolicitacaoAreaService implements SolicitacaoAreaUseCase {

    private static final List<StatusSolicitacaoArea> STATUS_DISPONIBILIDADE =
            List.of(StatusSolicitacaoArea.SOLICITADO, StatusSolicitacaoArea.APROVADO);

    private static final long JANELA_MAXIMA_DIAS = 62;

    private final SolicitacaoAreaRepository solicitacaoAreaRepository;
    private final AreaRepository areaRepository;
    private final MoradorRepository moradorRepository;
    private final UnidadeRepository unidadeRepository;
    private final AuthenticatedUserValidator authenticatedUserValidator;

    public SolicitacaoAreaService(
            SolicitacaoAreaRepository solicitacaoAreaRepository,
            AreaRepository areaRepository,
            MoradorRepository moradorRepository,
            UnidadeRepository unidadeRepository,
            AuthenticatedUserValidator authenticatedUserValidator
    ) {
        this.solicitacaoAreaRepository = solicitacaoAreaRepository;
        this.areaRepository = areaRepository;
        this.moradorRepository = moradorRepository;
        this.unidadeRepository = unidadeRepository;
        this.authenticatedUserValidator = authenticatedUserValidator;
    }

    @Override
    @Transactional
    public SolicitacaoArea solicitarReserva(
            AuthenticatedUser morador,
            UUID areaId,
            UUID unidadeId,
            LocalDateTime inicio,
            LocalDateTime fim
    ) {
        authenticatedUserValidator.assertMorador(morador);
        Area area = buscarAreaDisponivel(areaId);
        validarPeriodo(inicio, fim);
        Unidade unidade = buscarUnidadeDoMorador(morador.id(), unidadeId);
        Morador moradorEntidade = buscarMorador(morador.id());

        SolicitacaoArea solicitacao = new SolicitacaoArea();
        solicitacao.setArea(area);
        solicitacao.setMorador(moradorEntidade);
        solicitacao.setUnidade(unidade);
        solicitacao.setInicio(inicio);
        solicitacao.setFim(fim);
        solicitacao.setStatus(StatusSolicitacaoArea.SOLICITADO);
        return solicitacaoAreaRepository.save(solicitacao);
    }

    @Override
    public PageResult<SolicitacaoArea> listarMinhasReservas(
            AuthenticatedUser morador,
            PageRequest pageRequest
    ) {
        authenticatedUserValidator.assertMorador(morador);
        return PageResultMapper.fromPage(
                solicitacaoAreaRepository.findByMoradorId(morador.id(), pageRequest)
        );
    }

    @Override
    public List<SolicitacaoArea> listarMinhasReservasNoPeriodo(
            AuthenticatedUser morador,
            LocalDateTime inicio,
            LocalDateTime fim
    ) {
        authenticatedUserValidator.assertMorador(morador);
        validarJanela(inicio, fim);
        return solicitacaoAreaRepository.buscarDoMoradorNoPeriodo(morador.id(), inicio, fim);
    }

    @Override
    public List<SolicitacaoArea> consultarDisponibilidade(
            AuthenticatedUser morador,
            UUID areaId,
            LocalDate data
    ) {
        authenticatedUserValidator.assertMorador(morador);
        if (areaId == null || data == null) {
            throw new BusinessRuleException("Area e data sao obrigatorias");
        }
        return solicitacaoAreaRepository.buscarDisponibilidade(
                areaId,
                data.atStartOfDay(),
                data.plusDays(1).atStartOfDay(),
                STATUS_DISPONIBILIDADE
        );
    }

    @Override
    public List<Area> listarAreasDisponiveis(AuthenticatedUser morador) {
        authenticatedUserValidator.assertMorador(morador);
        return areaRepository.findByStatus(StatusArea.ATIVO);
    }

    @Override
    @Transactional
    public void cancelarMinhaReserva(
            AuthenticatedUser morador,
            UUID reservaId
    ) {
        authenticatedUserValidator.assertMorador(morador);
        SolicitacaoArea solicitacao = solicitacaoAreaRepository
                .findByIdAndMoradorId(reservaId, morador.id())
                .orElseThrow(() -> new ResourceNotFoundException("Reserva nao encontrada"));
        cancelar(solicitacao);
    }

    @Override
    public PageResult<SolicitacaoArea> listarReservas(
            AuthenticatedUser admin,
            PageRequest pageRequest
    ) {
        authenticatedUserValidator.assertAdministrador(admin);
        return PageResultMapper.fromPage(solicitacaoAreaRepository.findAll(pageRequest));
    }

    @Override
    public List<SolicitacaoArea> listarReservasNoPeriodo(
            AuthenticatedUser admin,
            LocalDateTime inicio,
            LocalDateTime fim
    ) {
        authenticatedUserValidator.assertAdministrador(admin);
        validarJanela(inicio, fim);
        return solicitacaoAreaRepository.buscarNoPeriodo(inicio, fim, STATUS_DISPONIBILIDADE);
    }

    @Override
    @Transactional
    public SolicitacaoArea aprovarReserva(
            AuthenticatedUser admin,
            UUID reservaId
    ) {
        authenticatedUserValidator.assertAdministrador(admin);
        SolicitacaoArea solicitacao = buscarReserva(reservaId);

        if (solicitacao.getStatus() != StatusSolicitacaoArea.SOLICITADO) {
            throw new BusinessRuleException("Somente reservas solicitadas podem ser aprovadas");
        }
        if (!solicitacao.getInicio().isAfter(LocalDateTime.now())) {
            throw new BusinessRuleException("Reserva com inicio ja alcancado nao pode ser aprovada");
        }
        if (existeConflitoAprovado(solicitacao)) {
            throw new BusinessRuleException("Ja existe reserva aprovada conflitante para esta area");
        }

        solicitacao.setStatus(StatusSolicitacaoArea.APROVADO);
        try {
            return solicitacaoAreaRepository.saveAndFlush(solicitacao);
        } catch (DataIntegrityViolationException exception) {
            // O EXCLUDE da migration V20 e a garantia final contra aprovacoes sobrepostas concorrentes.
            throw new BusinessRuleException("Ja existe reserva aprovada conflitante para esta area");
        }
    }

    @Override
    @Transactional
    public SolicitacaoArea negarReserva(
            AuthenticatedUser admin,
            UUID reservaId,
            String motivo
    ) {
        authenticatedUserValidator.assertAdministrador(admin);
        SolicitacaoArea solicitacao = buscarReserva(reservaId);

        if (solicitacao.getStatus() != StatusSolicitacaoArea.SOLICITADO) {
            throw new BusinessRuleException("Somente reservas solicitadas podem ser negadas");
        }

        String motivoNormalizado = InputValidationSupport.normalizeRequiredText(
                motivo,
                "Motivo da negacao e obrigatorio",
                "Motivo da negacao deve ter no maximo "
                        + ValidationLimits.SOLICITACAO_AREA_MOTIVO_NEGACAO_MAX_LENGTH + " caracteres",
                ValidationLimits.SOLICITACAO_AREA_MOTIVO_NEGACAO_MAX_LENGTH
        );

        solicitacao.setMotivoNegacao(motivoNormalizado);
        solicitacao.setStatus(StatusSolicitacaoArea.NEGADO);
        return solicitacaoAreaRepository.save(solicitacao);
    }

    @Override
    @Transactional
    public void cancelarReserva(
            AuthenticatedUser admin,
            UUID reservaId
    ) {
        authenticatedUserValidator.assertAdministrador(admin);
        cancelar(buscarReserva(reservaId));
    }

    private void cancelar(SolicitacaoArea solicitacao) {
        StatusSolicitacaoArea status = solicitacao.getStatus();
        if (status != StatusSolicitacaoArea.SOLICITADO && status != StatusSolicitacaoArea.APROVADO) {
            throw new BusinessRuleException("Somente reservas solicitadas ou aprovadas podem ser canceladas");
        }
        if (!solicitacao.getInicio().isAfter(LocalDateTime.now())) {
            throw new BusinessRuleException("Reserva com inicio ja alcancado nao pode ser cancelada");
        }
        solicitacao.setStatus(StatusSolicitacaoArea.CANCELADO);
        solicitacaoAreaRepository.save(solicitacao);
    }

    private boolean existeConflitoAprovado(SolicitacaoArea solicitacao) {
        return solicitacaoAreaRepository.existsByAreaIdAndStatusAndInicioLessThanAndFimGreaterThanAndIdNot(
                solicitacao.getArea().getId(),
                StatusSolicitacaoArea.APROVADO,
                solicitacao.getFim(),
                solicitacao.getInicio(),
                solicitacao.getId()
        );
    }

    private Area buscarAreaDisponivel(UUID areaId) {
        if (areaId == null) {
            throw new BusinessRuleException("Area e obrigatoria");
        }
        Area area = areaRepository.findById(areaId)
                .orElseThrow(() -> new BusinessRuleException("Area nao encontrada"));
        if (area.getStatus() != StatusArea.ATIVO) {
            throw new BusinessRuleException("Area indisponivel para novas reservas");
        }
        return area;
    }

    private Morador buscarMorador(UUID moradorId) {
        return moradorRepository.findById(moradorId)
                .orElseThrow(() -> new BusinessRuleException("Morador nao encontrado"));
    }

    private Unidade buscarUnidadeDoMorador(UUID moradorId, UUID unidadeId) {
        if (unidadeId == null) {
            throw new BusinessRuleException("Unidade e obrigatoria");
        }
        if (!moradorRepository.existsByIdAndUnidadeId(moradorId, unidadeId)) {
            throw new BusinessRuleException("Morador nao pode reservar para esta unidade");
        }
        return unidadeRepository.findById(unidadeId)
                .orElseThrow(() -> new ResourceNotFoundException("Unidade nao encontrada"));
    }

    private SolicitacaoArea buscarReserva(UUID reservaId) {
        if (reservaId == null) {
            throw new ResourceNotFoundException("Reserva nao encontrada");
        }
        return solicitacaoAreaRepository.findById(reservaId)
                .orElseThrow(() -> new ResourceNotFoundException("Reserva nao encontrada"));
    }

    private void validarPeriodo(LocalDateTime inicio, LocalDateTime fim) {
        if (inicio == null || fim == null) {
            throw new BusinessRuleException("Data e horarios de inicio e fim sao obrigatorios");
        }
        if (!inicio.isBefore(fim)) {
            throw new BusinessRuleException("Horario de fim deve ser posterior ao de inicio");
        }
        if (!inicio.isAfter(LocalDateTime.now())) {
            throw new BusinessRuleException("Horario inicial deve ser futuro");
        }
    }

    private void validarJanela(LocalDateTime inicio, LocalDateTime fim) {
        if (inicio == null || fim == null) {
            throw new BusinessRuleException("Inicio e fim do periodo sao obrigatorios");
        }
        if (!inicio.isBefore(fim)) {
            throw new BusinessRuleException("Fim do periodo deve ser posterior ao inicio");
        }
        if (fim.isAfter(inicio.plusDays(JANELA_MAXIMA_DIAS))) {
            throw new BusinessRuleException(
                    "Periodo consultado excede o limite de " + JANELA_MAXIMA_DIAS + " dias"
            );
        }
    }
}
