package br.com.dunnastecnologia.chamados.infrastructure.service;

import br.com.dunnastecnologia.chamados.application.Security.AuthenticatedUser;
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
import br.com.dunnastecnologia.chamados.infrastructure.exception.UnauthorizedOperationException;
import br.com.dunnastecnologia.chamados.infrastructure.repository.AreaRepository;
import br.com.dunnastecnologia.chamados.infrastructure.repository.MoradorRepository;
import br.com.dunnastecnologia.chamados.infrastructure.repository.SolicitacaoAreaRepository;
import br.com.dunnastecnologia.chamados.infrastructure.repository.UnidadeRepository;
import br.com.dunnastecnologia.chamados.infrastructure.service.support.AuthenticatedUserValidator;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SolicitacaoAreaServiceTest {

    @Mock
    private SolicitacaoAreaRepository solicitacaoAreaRepository;
    @Mock
    private AreaRepository areaRepository;
    @Mock
    private MoradorRepository moradorRepository;
    @Mock
    private UnidadeRepository unidadeRepository;
    @Mock
    private AuthenticatedUserValidator authenticatedUserValidator;

    @InjectMocks
    private SolicitacaoAreaService solicitacaoAreaService;

    @Test
    void solicitarReservaDeveCriarSolicitadoQuandoAreaAtivaEPeriodoValido() {
        AuthenticatedUser moradorAutenticado = moradorAutenticado();
        Area area = area(StatusArea.ATIVO);
        Morador morador = moradorComUnidade(moradorAutenticado.id());
        Unidade unidade = morador.getUnidades().iterator().next();
        LocalDateTime inicio = LocalDateTime.now().plusDays(1);
        LocalDateTime fim = inicio.plusHours(2);

        when(areaRepository.findById(area.getId())).thenReturn(Optional.of(area));
        when(moradorRepository.existsByIdAndUnidadeId(moradorAutenticado.id(), unidade.getId())).thenReturn(true);
        when(unidadeRepository.findById(unidade.getId())).thenReturn(Optional.of(unidade));
        when(moradorRepository.findById(moradorAutenticado.id())).thenReturn(Optional.of(morador));
        when(solicitacaoAreaRepository.save(any(SolicitacaoArea.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        SolicitacaoArea solicitacao = solicitacaoAreaService.solicitarReserva(
                moradorAutenticado, area.getId(), unidade.getId(), inicio, fim);

        assertEquals(StatusSolicitacaoArea.SOLICITADO, solicitacao.getStatus());
        assertEquals(area, solicitacao.getArea());
        assertEquals(morador, solicitacao.getMorador());
        assertEquals(unidade, solicitacao.getUnidade());
        assertEquals(inicio, solicitacao.getInicio());
        assertEquals(fim, solicitacao.getFim());
    }

    @Test
    void solicitarReservaDeveRecusarAreaInativa() {
        AuthenticatedUser moradorAutenticado = moradorAutenticado();
        Area area = area(StatusArea.INATIVO);
        when(areaRepository.findById(area.getId())).thenReturn(Optional.of(area));

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.solicitarReserva(
                        moradorAutenticado, area.getId(), UUID.randomUUID(),
                        LocalDateTime.now().plusDays(1), LocalDateTime.now().plusDays(1).plusHours(1))
        );
    }

    @Test
    void solicitarReservaDeveRecusarFimNaoPosteriorAoInicio() {
        AuthenticatedUser moradorAutenticado = moradorAutenticado();
        Area area = area(StatusArea.ATIVO);
        when(areaRepository.findById(area.getId())).thenReturn(Optional.of(area));
        LocalDateTime inicio = LocalDateTime.now().plusDays(1);

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.solicitarReserva(
                        moradorAutenticado, area.getId(), UUID.randomUUID(), inicio, inicio.minusMinutes(1))
        );
    }

    @Test
    void solicitarReservaDeveRecusarInicioNoPassado() {
        AuthenticatedUser moradorAutenticado = moradorAutenticado();
        Area area = area(StatusArea.ATIVO);
        when(areaRepository.findById(area.getId())).thenReturn(Optional.of(area));

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.solicitarReserva(
                        moradorAutenticado, area.getId(), UUID.randomUUID(),
                        LocalDateTime.now().minusDays(1), LocalDateTime.now().plusDays(1))
        );
    }

    @Test
    void aprovarReservaDeveAprovarQuandoSemConflito() {
        AuthenticatedUser admin = administradorAutenticado();
        SolicitacaoArea solicitacao = solicitacao(StatusSolicitacaoArea.SOLICITADO, futuro());
        when(solicitacaoAreaRepository.findById(solicitacao.getId())).thenReturn(Optional.of(solicitacao));
        when(solicitacaoAreaRepository.saveAndFlush(solicitacao)).thenReturn(solicitacao);

        SolicitacaoArea aprovada = solicitacaoAreaService.aprovarReserva(admin, solicitacao.getId());

        assertEquals(StatusSolicitacaoArea.APROVADO, aprovada.getStatus());
    }

    @Test
    void aprovarReservaDeveRecusarConflitoComAprovado() {
        AuthenticatedUser admin = administradorAutenticado();
        SolicitacaoArea solicitacao = solicitacao(StatusSolicitacaoArea.SOLICITADO, futuro());
        when(solicitacaoAreaRepository.findById(solicitacao.getId())).thenReturn(Optional.of(solicitacao));
        when(solicitacaoAreaRepository.existsByAreaIdAndStatusAndInicioLessThanAndFimGreaterThanAndIdNot(
                any(), any(), any(), any(), any())).thenReturn(true);

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.aprovarReserva(admin, solicitacao.getId())
        );
    }

    @Test
    void aprovarReservaDeveRecusarEstadoTerminal() {
        AuthenticatedUser admin = administradorAutenticado();
        SolicitacaoArea solicitacao = solicitacao(StatusSolicitacaoArea.CANCELADO, futuro());
        when(solicitacaoAreaRepository.findById(solicitacao.getId())).thenReturn(Optional.of(solicitacao));

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.aprovarReserva(admin, solicitacao.getId())
        );
    }

    @Test
    void aprovarReservaDeveRecusarInicioJaAlcancado() {
        AuthenticatedUser admin = administradorAutenticado();
        SolicitacaoArea solicitacao = solicitacao(StatusSolicitacaoArea.SOLICITADO, LocalDateTime.now().minusHours(1));
        when(solicitacaoAreaRepository.findById(solicitacao.getId())).thenReturn(Optional.of(solicitacao));

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.aprovarReserva(admin, solicitacao.getId())
        );
    }

    @Test
    void aprovarReservaDeveNegarPerfilSemPermissao() {
        AuthenticatedUser morador = moradorAutenticado();
        doThrow(new UnauthorizedOperationException("sem permissao"))
                .when(authenticatedUserValidator).assertAdministrador(morador);

        assertThrows(
                UnauthorizedOperationException.class,
                () -> solicitacaoAreaService.aprovarReserva(morador, UUID.randomUUID())
        );
    }

    @Test
    void negarReservaDeveExigirMotivo() {
        AuthenticatedUser admin = administradorAutenticado();
        SolicitacaoArea solicitacao = solicitacao(StatusSolicitacaoArea.SOLICITADO, futuro());
        when(solicitacaoAreaRepository.findById(solicitacao.getId())).thenReturn(Optional.of(solicitacao));

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.negarReserva(admin, solicitacao.getId(), "   ")
        );
    }

    @Test
    void negarReservaDeveRegistrarMotivoEStatusNegado() {
        AuthenticatedUser admin = administradorAutenticado();
        SolicitacaoArea solicitacao = solicitacao(StatusSolicitacaoArea.SOLICITADO, futuro());
        when(solicitacaoAreaRepository.findById(solicitacao.getId())).thenReturn(Optional.of(solicitacao));
        when(solicitacaoAreaRepository.save(solicitacao)).thenReturn(solicitacao);

        SolicitacaoArea negada = solicitacaoAreaService.negarReserva(admin, solicitacao.getId(), " Area em manutencao ");

        assertEquals(StatusSolicitacaoArea.NEGADO, negada.getStatus());
        assertEquals("Area em manutencao", negada.getMotivoNegacao());
    }

    @Test
    void cancelarDeveRecusarReservaAposInicio() {
        AuthenticatedUser admin = administradorAutenticado();
        SolicitacaoArea solicitacao = solicitacao(StatusSolicitacaoArea.APROVADO, LocalDateTime.now().minusHours(1));
        when(solicitacaoAreaRepository.findById(solicitacao.getId())).thenReturn(Optional.of(solicitacao));

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.cancelarReserva(admin, solicitacao.getId())
        );
    }

    @Test
    void cancelarDeveRecusarEstadoTerminal() {
        AuthenticatedUser admin = administradorAutenticado();
        SolicitacaoArea solicitacao = solicitacao(StatusSolicitacaoArea.CANCELADO, futuro());
        when(solicitacaoAreaRepository.findById(solicitacao.getId())).thenReturn(Optional.of(solicitacao));

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.cancelarReserva(admin, solicitacao.getId())
        );
    }

    @Test
    void cancelarMinhaReservaDeveExigirPosse() {
        AuthenticatedUser morador = moradorAutenticado();
        UUID reservaId = UUID.randomUUID();
        when(solicitacaoAreaRepository.findByIdAndMoradorId(reservaId, morador.id())).thenReturn(Optional.empty());

        assertThrows(
                ResourceNotFoundException.class,
                () -> solicitacaoAreaService.cancelarMinhaReserva(morador, reservaId)
        );
    }

    @Test
    void cancelarMinhaReservaDeveCancelarQuandoProprietario() {
        AuthenticatedUser morador = moradorAutenticado();
        SolicitacaoArea solicitacao = solicitacao(StatusSolicitacaoArea.SOLICITADO, futuro());
        when(solicitacaoAreaRepository.findByIdAndMoradorId(solicitacao.getId(), morador.id()))
                .thenReturn(Optional.of(solicitacao));
        when(solicitacaoAreaRepository.save(solicitacao)).thenReturn(solicitacao);

        solicitacaoAreaService.cancelarMinhaReserva(morador, solicitacao.getId());

        assertEquals(StatusSolicitacaoArea.CANCELADO, solicitacao.getStatus());
    }

    @Test
    void listarReservasNoPeriodoDeveRetornarReservasDaJanela() {
        AuthenticatedUser admin = administradorAutenticado();
        LocalDateTime inicio = futuro();
        LocalDateTime fim = inicio.plusDays(30);
        SolicitacaoArea solicitacao = solicitacao(StatusSolicitacaoArea.SOLICITADO, inicio.plusDays(1));
        when(solicitacaoAreaRepository.buscarNoPeriodo(eq(inicio), eq(fim), anyCollection()))
                .thenReturn(List.of(solicitacao));

        List<SolicitacaoArea> reservas = solicitacaoAreaService.listarReservasNoPeriodo(admin, inicio, fim);

        assertEquals(1, reservas.size());
        assertEquals(solicitacao, reservas.get(0));
    }

    @Test
    void listarReservasNoPeriodoDeveRecusarJanelaInvertida() {
        AuthenticatedUser admin = administradorAutenticado();
        LocalDateTime inicio = futuro().plusDays(10);

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.listarReservasNoPeriodo(admin, inicio, inicio.minusDays(1))
        );
    }

    @Test
    void listarReservasNoPeriodoDeveRecusarJanelaAcimaDoLimite() {
        AuthenticatedUser admin = administradorAutenticado();
        LocalDateTime inicio = futuro();

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.listarReservasNoPeriodo(admin, inicio, inicio.plusDays(90))
        );
    }

    @Test
    void listarReservasNoPeriodoDeveNegarPerfilSemPermissao() {
        AuthenticatedUser morador = moradorAutenticado();
        doThrow(new UnauthorizedOperationException("sem permissao"))
                .when(authenticatedUserValidator).assertAdministrador(morador);

        assertThrows(
                UnauthorizedOperationException.class,
                () -> solicitacaoAreaService.listarReservasNoPeriodo(
                        morador, futuro(), futuro().plusDays(10))
        );
    }

    @Test
    void listarMinhasReservasNoPeriodoDeveRetornarReservasDoMorador() {
        AuthenticatedUser morador = moradorAutenticado();
        LocalDateTime inicio = futuro();
        LocalDateTime fim = inicio.plusDays(30);
        SolicitacaoArea solicitacao = solicitacao(StatusSolicitacaoArea.APROVADO, inicio.plusDays(1));
        when(solicitacaoAreaRepository.buscarDoMoradorNoPeriodo(eq(morador.id()), eq(inicio), eq(fim)))
                .thenReturn(List.of(solicitacao));

        List<SolicitacaoArea> reservas = solicitacaoAreaService.listarMinhasReservasNoPeriodo(morador, inicio, fim);

        assertEquals(1, reservas.size());
        assertEquals(solicitacao, reservas.get(0));
    }

    @Test
    void listarMinhasReservasNoPeriodoDeveRecusarJanelaAcimaDoLimite() {
        AuthenticatedUser morador = moradorAutenticado();
        LocalDateTime inicio = futuro();

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.listarMinhasReservasNoPeriodo(morador, inicio, inicio.plusDays(90))
        );
    }

    @Test
    void listarMinhasReservasNoPeriodoDeveNegarPerfilSemPermissao() {
        AuthenticatedUser admin = administradorAutenticado();
        doThrow(new UnauthorizedOperationException("sem permissao"))
                .when(authenticatedUserValidator).assertMorador(admin);

        assertThrows(
                UnauthorizedOperationException.class,
                () -> solicitacaoAreaService.listarMinhasReservasNoPeriodo(
                        admin, futuro(), futuro().plusDays(10))
        );
    }

    @Test
    void solicitarReservaDeveRecusarAreaInexistente() {
        AuthenticatedUser morador = moradorAutenticado();
        UUID areaId = UUID.randomUUID();
        when(areaRepository.findById(areaId)).thenReturn(Optional.empty());

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.solicitarReserva(
                        morador, areaId, UUID.randomUUID(), futuro(), futuro().plusHours(1))
        );
    }

    @Test
    void solicitarReservaDeveRecusarAreaNaoInformada() {
        AuthenticatedUser morador = moradorAutenticado();

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.solicitarReserva(
                        morador, null, UUID.randomUUID(), futuro(), futuro().plusHours(1))
        );
    }

    @Test
    void solicitarReservaDeveRecusarHorariosAusentes() {
        AuthenticatedUser morador = moradorAutenticado();
        Area area = area(StatusArea.ATIVO);
        when(areaRepository.findById(area.getId())).thenReturn(Optional.of(area));

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.solicitarReserva(
                        morador, area.getId(), UUID.randomUUID(), null, null)
        );
    }

    @Test
    void solicitarReservaDeveRecusarUnidadeNaoVinculadaAoMorador() {
        AuthenticatedUser morador = moradorAutenticado();
        Area area = area(StatusArea.ATIVO);
        UUID unidadeId = UUID.randomUUID();
        when(areaRepository.findById(area.getId())).thenReturn(Optional.of(area));
        when(moradorRepository.existsByIdAndUnidadeId(morador.id(), unidadeId)).thenReturn(false);

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.solicitarReserva(
                        morador, area.getId(), unidadeId, futuro(), futuro().plusHours(1))
        );
    }

    @Test
    void solicitarReservaDeveRecusarUnidadeNaoInformada() {
        AuthenticatedUser morador = moradorAutenticado();
        Area area = area(StatusArea.ATIVO);
        when(areaRepository.findById(area.getId())).thenReturn(Optional.of(area));

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.solicitarReserva(
                        morador, area.getId(), null, futuro(), futuro().plusHours(1))
        );
    }

    @Test
    void solicitarReservaDeveRecusarUnidadeVinculadaInexistente() {
        AuthenticatedUser morador = moradorAutenticado();
        Area area = area(StatusArea.ATIVO);
        UUID unidadeId = UUID.randomUUID();
        when(areaRepository.findById(area.getId())).thenReturn(Optional.of(area));
        when(moradorRepository.existsByIdAndUnidadeId(morador.id(), unidadeId)).thenReturn(true);
        when(unidadeRepository.findById(unidadeId)).thenReturn(Optional.empty());

        assertThrows(
                ResourceNotFoundException.class,
                () -> solicitacaoAreaService.solicitarReserva(
                        morador, area.getId(), unidadeId, futuro(), futuro().plusHours(1))
        );
    }

    @Test
    void solicitarReservaDeveNegarPerfilSemPermissao() {
        AuthenticatedUser admin = administradorAutenticado();
        doThrow(new UnauthorizedOperationException("sem permissao"))
                .when(authenticatedUserValidator).assertMorador(admin);

        assertThrows(
                UnauthorizedOperationException.class,
                () -> solicitacaoAreaService.solicitarReserva(
                        admin, UUID.randomUUID(), UUID.randomUUID(), futuro(), futuro().plusHours(1))
        );
    }

    @Test
    void listarMinhasReservasDeveRetornarPaginaDoMorador() {
        AuthenticatedUser morador = moradorAutenticado();
        PageRequest pageRequest = PageRequest.of(0, 10);
        SolicitacaoArea solicitacao = solicitacao(StatusSolicitacaoArea.SOLICITADO, futuro());
        when(solicitacaoAreaRepository.findByMoradorId(morador.id(), pageRequest))
                .thenReturn(new PageImpl<>(List.of(solicitacao), pageRequest, 1));

        PageResult<SolicitacaoArea> resultado = solicitacaoAreaService.listarMinhasReservas(morador, pageRequest);

        assertEquals(1, resultado.totalElements());
        assertEquals(List.of(solicitacao), resultado.content());
    }

    @Test
    void listarMinhasReservasDeveNegarPerfilSemPermissao() {
        AuthenticatedUser admin = administradorAutenticado();
        PageRequest pageRequest = PageRequest.of(0, 10);
        doThrow(new UnauthorizedOperationException("sem permissao"))
                .when(authenticatedUserValidator).assertMorador(admin);

        assertThrows(
                UnauthorizedOperationException.class,
                () -> solicitacaoAreaService.listarMinhasReservas(admin, pageRequest)
        );
    }

    @Test
    void listarReservasDeveRetornarPaginaParaAdmin() {
        AuthenticatedUser admin = administradorAutenticado();
        PageRequest pageRequest = PageRequest.of(0, 10);
        SolicitacaoArea solicitacao = solicitacao(StatusSolicitacaoArea.APROVADO, futuro());
        when(solicitacaoAreaRepository.findAll(pageRequest))
                .thenReturn(new PageImpl<>(List.of(solicitacao), pageRequest, 1));

        PageResult<SolicitacaoArea> resultado = solicitacaoAreaService.listarReservas(admin, pageRequest);

        assertEquals(1, resultado.totalElements());
    }

    @Test
    void listarReservasDeveNegarPerfilSemPermissao() {
        AuthenticatedUser morador = moradorAutenticado();
        PageRequest pageRequest = PageRequest.of(0, 10);
        doThrow(new UnauthorizedOperationException("sem permissao"))
                .when(authenticatedUserValidator).assertAdministrador(morador);

        assertThrows(
                UnauthorizedOperationException.class,
                () -> solicitacaoAreaService.listarReservas(morador, pageRequest)
        );
    }

    @Test
    void consultarDisponibilidadeDeveRetornarAprovadasEPendentes() {
        AuthenticatedUser morador = moradorAutenticado();
        UUID areaId = UUID.randomUUID();
        LocalDate data = LocalDate.now().plusDays(1);
        SolicitacaoArea aprovada = solicitacao(StatusSolicitacaoArea.APROVADO, data.atTime(10, 0));
        SolicitacaoArea pendente = solicitacao(StatusSolicitacaoArea.SOLICITADO, data.atTime(14, 0));
        when(solicitacaoAreaRepository.buscarDisponibilidade(
                eq(areaId),
                eq(data.atStartOfDay()),
                eq(data.plusDays(1).atStartOfDay()),
                argThat(statuses -> statuses.containsAll(
                        List.of(StatusSolicitacaoArea.SOLICITADO, StatusSolicitacaoArea.APROVADO)))))
                .thenReturn(List.of(aprovada, pendente));

        List<SolicitacaoArea> ocupacoes = solicitacaoAreaService.consultarDisponibilidade(morador, areaId, data);

        assertEquals(List.of(aprovada, pendente), ocupacoes);
    }

    @Test
    void consultarDisponibilidadeDeveRecusarDadosAusentes() {
        AuthenticatedUser morador = moradorAutenticado();

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.consultarDisponibilidade(morador, null, LocalDate.now().plusDays(1))
        );
        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.consultarDisponibilidade(morador, UUID.randomUUID(), null)
        );
    }

    @Test
    void consultarDisponibilidadeDeveNegarPerfilSemPermissao() {
        AuthenticatedUser admin = administradorAutenticado();
        doThrow(new UnauthorizedOperationException("sem permissao"))
                .when(authenticatedUserValidator).assertMorador(admin);

        assertThrows(
                UnauthorizedOperationException.class,
                () -> solicitacaoAreaService.consultarDisponibilidade(
                        admin, UUID.randomUUID(), LocalDate.now().plusDays(1))
        );
    }

    @Test
    void listarAreasDisponiveisDeveRetornarSomenteAtivas() {
        AuthenticatedUser morador = moradorAutenticado();
        Area ativa = area(StatusArea.ATIVO);
        when(areaRepository.findByStatus(StatusArea.ATIVO)).thenReturn(List.of(ativa));

        List<Area> areas = solicitacaoAreaService.listarAreasDisponiveis(morador);

        assertEquals(List.of(ativa), areas);
    }

    @Test
    void aprovarReservaDeveConverterCorridaDoBancoEmRegraDeNegocio() {
        AuthenticatedUser admin = administradorAutenticado();
        SolicitacaoArea solicitacao = solicitacao(StatusSolicitacaoArea.SOLICITADO, futuro());
        when(solicitacaoAreaRepository.findById(solicitacao.getId())).thenReturn(Optional.of(solicitacao));
        when(solicitacaoAreaRepository.saveAndFlush(solicitacao))
                .thenThrow(new DataIntegrityViolationException("excl_solicitacoes_area_overlap"));

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.aprovarReserva(admin, solicitacao.getId())
        );
    }

    @Test
    void aprovarReservaDeveRecusarReservaNaoInformada() {
        AuthenticatedUser admin = administradorAutenticado();

        assertThrows(
                ResourceNotFoundException.class,
                () -> solicitacaoAreaService.aprovarReserva(admin, null)
        );
    }

    @Test
    void negarReservaDeveRecusarMotivoAcimaDoLimite() {
        AuthenticatedUser admin = administradorAutenticado();
        SolicitacaoArea solicitacao = solicitacao(StatusSolicitacaoArea.SOLICITADO, futuro());
        when(solicitacaoAreaRepository.findById(solicitacao.getId())).thenReturn(Optional.of(solicitacao));

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.negarReserva(
                        admin,
                        solicitacao.getId(),
                        "x".repeat(ValidationLimits.SOLICITACAO_AREA_MOTIVO_NEGACAO_MAX_LENGTH + 1))
        );
    }

    @Test
    void negarReservaDeveRecusarEstadoTerminal() {
        AuthenticatedUser admin = administradorAutenticado();
        SolicitacaoArea solicitacao = solicitacao(StatusSolicitacaoArea.NEGADO, futuro());
        when(solicitacaoAreaRepository.findById(solicitacao.getId())).thenReturn(Optional.of(solicitacao));

        assertThrows(
                BusinessRuleException.class,
                () -> solicitacaoAreaService.negarReserva(admin, solicitacao.getId(), "motivo")
        );
    }

    @Test
    void cancelarReservaDeveCancelarQuandoAdmin() {
        AuthenticatedUser admin = administradorAutenticado();
        SolicitacaoArea solicitacao = solicitacao(StatusSolicitacaoArea.APROVADO, futuro());
        when(solicitacaoAreaRepository.findById(solicitacao.getId())).thenReturn(Optional.of(solicitacao));
        when(solicitacaoAreaRepository.save(solicitacao)).thenReturn(solicitacao);

        solicitacaoAreaService.cancelarReserva(admin, solicitacao.getId());

        assertEquals(StatusSolicitacaoArea.CANCELADO, solicitacao.getStatus());
    }

    @Test
    void cancelarReservaDeveNegarPerfilSemPermissao() {
        AuthenticatedUser morador = moradorAutenticado();
        doThrow(new UnauthorizedOperationException("sem permissao"))
                .when(authenticatedUserValidator).assertAdministrador(morador);

        assertThrows(
                UnauthorizedOperationException.class,
                () -> solicitacaoAreaService.cancelarReserva(morador, UUID.randomUUID())
        );
    }

    @Test
    void cancelarMinhaReservaDeveNegarPerfilSemPermissao() {
        AuthenticatedUser admin = administradorAutenticado();
        doThrow(new UnauthorizedOperationException("sem permissao"))
                .when(authenticatedUserValidator).assertMorador(admin);

        assertThrows(
                UnauthorizedOperationException.class,
                () -> solicitacaoAreaService.cancelarMinhaReserva(admin, UUID.randomUUID())
        );
    }

    private AuthenticatedUser moradorAutenticado() {
        return new AuthenticatedUser(UUID.randomUUID(), "morador@condominio.local", "ROLE_MORADOR");
    }

    private AuthenticatedUser administradorAutenticado() {
        return new AuthenticatedUser(UUID.randomUUID(), "admin@condominio.local", "ROLE_ADMINISTRADOR");
    }

    private Area area(StatusArea status) {
        Area area = new Area();
        area.setId(UUID.randomUUID());
        area.setNome("Salao");
        area.setStatus(status);
        return area;
    }

    private Morador moradorComUnidade(UUID moradorId) {
        Morador morador = new Morador();
        morador.setId(moradorId);
        Unidade unidade = new Unidade();
        unidade.setId(UUID.randomUUID());
        unidade.setIdentificacao("A-101");
        morador.getUnidades().add(unidade);
        return morador;
    }

    private SolicitacaoArea solicitacao(StatusSolicitacaoArea status, LocalDateTime inicio) {
        SolicitacaoArea solicitacao = new SolicitacaoArea();
        solicitacao.setId(UUID.randomUUID());
        solicitacao.setArea(area(StatusArea.ATIVO));
        solicitacao.setInicio(inicio);
        solicitacao.setFim(inicio.plusHours(2));
        solicitacao.setStatus(status);
        return solicitacao;
    }

    private LocalDateTime futuro() {
        return LocalDateTime.now().plusDays(1);
    }
}
