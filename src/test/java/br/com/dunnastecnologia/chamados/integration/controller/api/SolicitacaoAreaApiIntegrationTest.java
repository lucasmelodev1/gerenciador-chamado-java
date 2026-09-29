package br.com.dunnastecnologia.chamados.infrastructure.controller.api;

import br.com.dunnastecnologia.chamados.application.Security.AuthenticatedUser;
import br.com.dunnastecnologia.chamados.application.UserCase.SolicitacaoAreaUseCase;
import br.com.dunnastecnologia.chamados.domain.model.Morador;
import br.com.dunnastecnologia.chamados.domain.model.SolicitacaoArea;
import br.com.dunnastecnologia.chamados.domain.model.StatusSolicitacaoArea;
import br.com.dunnastecnologia.chamados.infrastructure.exception.UnauthorizedOperationException;
import br.com.dunnastecnologia.chamados.integration.support.IntegrationTestSupport;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.transaction.annotation.Transactional;

import jakarta.servlet.ServletException;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.flash;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * E2E/integracao da funcionalidade de reservas de areas comuns, exercitando apenas os endpoints
 * HTTP (JSP/form) e lendo o resultado pelo model renderizado, sem consultar o banco diretamente.
 * Os testes estao em TDD: falham enquanto {@code SolicitacaoAreaService} nao implementa as regras.
 */
class SolicitacaoAreaApiIntegrationTest extends IntegrationTestSupport {

    private static final String AREA_STATUS_ATIVO = "Ativo";
    private static final String AREA_STATUS_INATIVO = "Inativo";
    private static final String STATUS_SOLICITADO = StatusSolicitacaoArea.SOLICITADO.getValor();
    private static final String STATUS_APROVADO = StatusSolicitacaoArea.APROVADO.getValor();
    private static final String STATUS_NEGADO = StatusSolicitacaoArea.NEGADO.getValor();
    private static final String STATUS_CANCELADO = StatusSolicitacaoArea.CANCELADO.getValor();

    @Autowired
    private SolicitacaoAreaUseCase solicitacaoAreaUseCase;

    private Authentication admin;

    @BeforeEach
    void setUp() {
        admin = autenticarComoAdministrador();
    }

    @Test
    @Transactional
    void deveSolicitarReservaVisivelSomenteAoProprietarioEAdministrador() throws Exception {
        UUID areaId = criarArea("Salao-" + UUID.randomUUID());
        Authentication moradorA = autenticarComoMorador();
        Authentication moradorB = autenticarComoMorador();
        LocalDateTime inicio = dataFutura().atTime(10, 0);
        LocalDateTime fim = dataFutura().atTime(12, 0);

        solicitarReserva(moradorA, areaId, inicio, fim);

        List<Map<String, Object>> reservasA = listarReservasMorador(moradorA);
        UUID reservaId = buscarReservaId(reservasA, areaId, inicio);
        assertEquals(STATUS_SOLICITADO, statusDe(reservasA, reservaId));

        List<Map<String, Object>> reservasB = listarReservasMorador(moradorB);
        assertTrue(reservasB.stream().noneMatch(reserva -> reservaId.equals(reserva.get("id"))));

        List<Map<String, Object>> reservasAdmin = listarReservasAdmin();
        assertTrue(reservasAdmin.stream().anyMatch(reserva -> reservaId.equals(reserva.get("id"))));
    }

    @Test
    @Transactional
    void deveConsultarDisponibilidadeDistinguindoAprovadaDePendenteEAreasDistintas() throws Exception {
        UUID areaA = criarArea("Piscina-" + UUID.randomUUID());
        UUID areaB = criarArea("Churrasqueira-" + UUID.randomUUID());
        Authentication moradorA = autenticarComoMorador();
        Authentication moradorB = autenticarComoMorador();
        LocalDate data = dataFutura();

        LocalDateTime inicioA = data.atTime(10, 0);
        LocalDateTime fimA = data.atTime(12, 0);
        LocalDateTime inicioB = data.atTime(14, 0);
        LocalDateTime fimB = data.atTime(16, 0);

        solicitarReserva(moradorA, areaA, inicioA, fimA);
        solicitarReserva(moradorB, areaA, inicioB, fimB);
        UUID reservaB = buscarReservaId(listarReservasMorador(moradorB), areaA, inicioB);
        aprovar(reservaB);

        solicitarReserva(moradorA, areaB, inicioB, fimB);
        UUID reservaAreaB = buscarReservaId(listarReservasMorador(moradorA), areaB, inicioB);
        aprovar(reservaAreaB);

        List<Map<String, Object>> disponibilidade = consultarDisponibilidade(moradorA, areaA, data);
        assertEquals(STATUS_SOLICITADO, statusDe(disponibilidade, buscarReservaId(disponibilidade, areaA, inicioA)));
        assertEquals(STATUS_APROVADO, statusDe(disponibilidade, reservaB));

        assertEquals(STATUS_APROVADO, statusDe(listarReservasAdmin(), reservaAreaB));
    }

    @Test
    @Transactional
    void deveIncluirNaDisponibilidadeReservaQueAtravessaAMeiaNoiteEExcluirIntervaloAdjacente() throws Exception {
        UUID areaAtravessa = criarArea("Quiosque-" + UUID.randomUUID());
        UUID areaAdjacente = criarArea("Sauna-" + UUID.randomUUID());
        Authentication morador = autenticarComoMorador();
        Morador moradorEntidade = moradorRepository.findById(authenticatedUser(morador).id()).orElseThrow();
        LocalDate data = dataFutura();

        SolicitacaoArea atravessaMeiaNoite = criarReservaDireta(
                areaAtravessa,
                moradorEntidade,
                data.minusDays(1).atTime(22, 0),
                data.atTime(2, 0),
                StatusSolicitacaoArea.APROVADO
        );
        SolicitacaoArea terminaNaMeiaNoite = criarReservaDireta(
                areaAdjacente,
                moradorEntidade,
                data.minusDays(1).atTime(20, 0),
                data.atStartOfDay(),
                StatusSolicitacaoArea.APROVADO
        );

        List<Map<String, Object>> disponibilidadeAtravessa = consultarDisponibilidade(morador, areaAtravessa, data);
        List<Map<String, Object>> disponibilidadeAdjacente = consultarDisponibilidade(morador, areaAdjacente, data);

        assertEquals(STATUS_APROVADO, statusDe(disponibilidadeAtravessa, atravessaMeiaNoite.getId()));
        assertNull(statusDe(disponibilidadeAdjacente, terminaNaMeiaNoite.getId()));
    }

    @Test
    @Transactional
    void deveAbrirDisponibilidadeSemParametrosParaExibirFormulario() throws Exception {
        Authentication morador = autenticarComoMorador();

        MvcResult result = mockMvc.perform(get("/morador/reservas/disponibilidade")
                        .with(autenticacao(morador)))
                .andExpect(status().isOk())
                .andReturn();

        assertEquals(Boolean.FALSE, result.getModelAndView().getModel().get("consultou"));
    }

    @Test
    @Transactional
    void deveExibirFormularioDeReservaComAreasEUnidadesDoMorador() throws Exception {
        Authentication morador = autenticarComoMorador();
        criarArea("AreaFormulario-" + UUID.randomUUID());

        MvcResult result = mockMvc.perform(get("/morador/reservas/nova")
                        .with(autenticacao(morador)))
                .andExpect(status().isOk())
                .andReturn();

        assertEquals("morador/reservas/nova", result.getModelAndView().getViewName());
        assertFalse(((List<?>) result.getModelAndView().getModel().get("unidades")).isEmpty());
        assertFalse(((List<?>) result.getModelAndView().getModel().get("areas")).isEmpty());
    }

    @Test
    @Transactional
    void deveRecusarSolicitacaoComDadosOuHorarioInvalido() throws Exception {
        UUID areaId = criarArea("Quadra-" + UUID.randomUUID());
        Authentication morador = autenticarComoMorador();
        LocalDate data = dataFutura();

        // Sem `areaId`
        mockMvc.perform(post("/morador/reservas")
                        .with(autenticacao(morador))
                        .param("inicio", data.atTime(10, 0).toString())
                        .param("fim", data.atTime(12, 0).toString()))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/morador"))
                .andExpect(flash().attributeExists("errorMessage"));

        // Inicio depois do fim
        mockMvc.perform(post("/morador/reservas")
                        .with(autenticacao(morador))
                        .param("areaId", areaId.toString())
                        .param("inicio", data.atTime(12, 0).toString())
                        .param("fim", data.atTime(10, 0).toString()))
                .andExpect(status().is3xxRedirection())
                .andExpect(flash().attributeExists("errorMessage"));

        // Inicio anterior ao agora
        mockMvc.perform(post("/morador/reservas")
                        .with(autenticacao(morador))
                        .param("areaId", areaId.toString())
                        .param("inicio", LocalDateTime.now().minusDays(1).toString())
                        .param("fim", LocalDateTime.now().plusDays(1).toString()))
                .andExpect(status().is3xxRedirection())
                .andExpect(flash().attributeExists("errorMessage"));

        assertTrue(listarReservasMorador(morador).isEmpty());
    }

    @Test
    @Transactional
    void deveRecusarSolicitacaoParaUnidadeDeOutroMorador() throws Exception {
        UUID areaId = criarArea("Salao-" + UUID.randomUUID());
        Authentication moradorA = autenticarComoMorador();
        Authentication moradorB = autenticarComoMorador();
        UUID unidadeDeB = unidadeDoMorador(moradorB);
        LocalDateTime inicio = dataFutura().atTime(10, 0);

        mockMvc.perform(post("/morador/reservas")
                        .with(autenticacao(moradorA))
                        .param("areaId", areaId.toString())
                        .param("unidadeId", unidadeDeB.toString())
                        .param("inicio", inicio.toString())
                        .param("fim", inicio.plusHours(2).toString()))
                .andExpect(status().is3xxRedirection())
                .andExpect(flash().attributeExists("errorMessage"));

        assertTrue(listarReservasMorador(moradorA).isEmpty());
    }

    @Test
    @Transactional
    void devePreservarReservasExistentesAoDesativarArea() throws Exception {
        String nome = "Espaco-" + UUID.randomUUID();
        UUID areaId = criarArea(nome);
        Authentication morador = autenticarComoMorador();
        LocalDate data = dataFutura();
        LocalDateTime inicio = data.atTime(10, 0);
        LocalDateTime fim = data.atTime(12, 0);

        solicitarReserva(morador, areaId, inicio, fim);
        UUID reservaId = buscarReservaId(listarReservasMorador(morador), areaId, inicio);

        desativarArea(areaId, nome);

        mockMvc.perform(post("/morador/reservas")
                        .with(autenticacao(morador))
                        .param("areaId", areaId.toString())
                        .param("inicio", data.atTime(14, 0).toString())
                        .param("fim", data.atTime(16, 0).toString()))
                .andExpect(status().is3xxRedirection())
                .andExpect(flash().attributeExists("errorMessage"));

        List<Map<String, Object>> reservas = listarReservasMorador(morador);
        assertTrue(reservas.stream().anyMatch(reserva -> reservaId.equals(reserva.get("id"))));
        assertEquals(STATUS_SOLICITADO, statusDe(reservas, reservaId));
    }

    @Test
    @Transactional
    void deveAprovarSemConflitoENegarComMotivo() throws Exception {
        UUID areaId = criarArea("Auditorio-" + UUID.randomUUID());
        Authentication morador = autenticarComoMorador();
        LocalDate data = dataFutura();

        LocalDateTime inicioX = data.atTime(10, 0);
        LocalDateTime fimX = data.atTime(12, 0);
        LocalDateTime inicioY = data.atTime(14, 0);
        LocalDateTime fimY = data.atTime(16, 0);

        solicitarReserva(morador, areaId, inicioX, fimX);
        UUID reservaNegar = buscarReservaId(listarReservasMorador(morador), areaId, inicioX);

        mockMvc.perform(patch("/admin/reservas/{reservaId}/negacao", reservaNegar)
                        .with(autenticacao(admin))
                        .param("motivo", " "))
                .andExpect(status().is3xxRedirection())
                .andExpect(flash().attributeExists("errorMessage"));
        assertEquals(STATUS_SOLICITADO, statusDe(listarReservasAdmin(), reservaNegar));

        negar(reservaNegar, "Area em manutencao");
        assertEquals(STATUS_NEGADO, statusDe(listarReservasAdmin(), reservaNegar));
        assertEquals("Area em manutencao", motivoDe(listarReservasAdmin(), reservaNegar));

        solicitarReserva(morador, areaId, inicioY, fimY);
        UUID reservaAprovar = buscarReservaId(listarReservasMorador(morador), areaId, inicioY);
        aprovar(reservaAprovar);
        assertEquals(STATUS_APROVADO, statusDe(listarReservasAdmin(), reservaAprovar));

        LocalDateTime inicioConflitante = inicioY.plusMinutes(30);
        solicitarReserva(morador, areaId, inicioConflitante, fimY.plusMinutes(30));
        UUID reservaConflitante = buscarReservaId(listarReservasMorador(morador), areaId, inicioConflitante);
        mockMvc.perform(patch("/admin/reservas/{reservaId}/aprovacao", reservaConflitante)
                        .with(autenticacao(admin)))
                .andExpect(status().is3xxRedirection())
                .andExpect(flash().attributeExists("errorMessage"));
        assertEquals(STATUS_SOLICITADO, statusDe(listarReservasAdmin(), reservaConflitante));
    }

    @Test
    @Transactional
    void deveCancelarPorProprietarioEAdministradorEPreservarEstadosTerminais() throws Exception {
        UUID areaId = criarArea("SalaoFesta-" + UUID.randomUUID());
        Authentication moradorA = autenticarComoMorador();
        Authentication moradorB = autenticarComoMorador();
        Morador moradorAEntidade = moradorRepository.findById(authenticatedUser(moradorA).id()).orElseThrow();
        LocalDate data = dataFutura();

        LocalDateTime inicio1 = data.atTime(10, 0);
        LocalDateTime fim1 = data.atTime(12, 0);
        solicitarReserva(moradorA, areaId, inicio1, fim1);
        UUID reserva1 = buscarReservaId(listarReservasMorador(moradorA), areaId, inicio1);
        aprovar(reserva1);
        cancelarMorador(moradorA, reserva1);
        assertEquals(STATUS_CANCELADO, statusDe(listarReservasMorador(moradorA), reserva1));

        solicitarReserva(moradorB, areaId, inicio1, fim1);
        UUID reservaB = buscarReservaId(listarReservasMorador(moradorB), areaId, inicio1);
        aprovar(reservaB);
        assertEquals(STATUS_APROVADO, statusDe(listarReservasAdmin(), reservaB));

        LocalDateTime inicio2 = data.atTime(14, 0);
        LocalDateTime fim2 = data.atTime(16, 0);
        solicitarReserva(moradorA, areaId, inicio2, fim2);
        UUID reserva2 = buscarReservaId(listarReservasMorador(moradorA), areaId, inicio2);
        cancelarAdmin(reserva2);
        assertEquals(STATUS_CANCELADO, statusDe(listarReservasAdmin(), reserva2));

        LocalDateTime inicio3 = data.atTime(18, 0);
        LocalDateTime fim3 = data.atTime(20, 0);
        solicitarReserva(moradorA, areaId, inicio3, fim3);
        UUID reserva3 = buscarReservaId(listarReservasMorador(moradorA), areaId, inicio3);
        mockMvc.perform(delete("/morador/reservas/{reservaId}", reserva3)
                        .with(autenticacao(moradorB)))
                .andExpect(status().is3xxRedirection())
                .andExpect(flash().attributeExists("errorMessage"));
        assertEquals(STATUS_SOLICITADO, statusDe(listarReservasMorador(moradorA), reserva3));

        mockMvc.perform(delete("/morador/reservas/{reservaId}", reserva1)
                        .with(autenticacao(moradorA)))
                .andExpect(status().is3xxRedirection())
                .andExpect(flash().attributeExists("errorMessage"));
        mockMvc.perform(patch("/admin/reservas/{reservaId}/aprovacao", reserva2)
                        .with(autenticacao(admin)))
                .andExpect(status().is3xxRedirection())
                .andExpect(flash().attributeExists("errorMessage"));

        UUID areaPassada = criarArea("AreaPassada-" + UUID.randomUUID());
        SolicitacaoArea reservaPassada = criarReservaDireta(
                areaPassada,
                moradorAEntidade,
                LocalDateTime.now().minusHours(2),
                LocalDateTime.now().minusHours(1),
                StatusSolicitacaoArea.SOLICITADO
        );
        mockMvc.perform(delete("/admin/reservas/{reservaId}", reservaPassada.getId())
                        .with(autenticacao(admin)))
                .andExpect(status().is3xxRedirection())
                .andExpect(flash().attributeExists("errorMessage"));
        mockMvc.perform(patch("/admin/reservas/{reservaId}/aprovacao", reservaPassada.getId())
                        .with(autenticacao(admin)))
                .andExpect(status().is3xxRedirection())
                .andExpect(flash().attributeExists("errorMessage"));
        assertEquals(STATUS_SOLICITADO, statusDe(listarReservasAdmin(), reservaPassada.getId()));
    }

    @Test
    @Transactional
    void deveNegarAcessoHttpParaPerfilSemPermissao() throws Exception {
        Authentication colaboradorAuth = autenticarComoColaborador();
        Authentication moradorAuth = autenticarComoMorador();

        assertAcessoNegado(get("/morador/reservas").with(autenticacao(colaboradorAuth)));
        assertAcessoNegado(get("/admin/reservas").with(autenticacao(colaboradorAuth)));
        assertAcessoNegado(get("/admin/reservas").with(autenticacao(moradorAuth)));
        assertAcessoNegado(get("/admin/reservas/agenda").with(autenticacao(colaboradorAuth)));
        assertAcessoNegado(get("/admin/reservas/agenda").with(autenticacao(moradorAuth)));
        assertAcessoNegado(get("/morador/reservas/agenda").with(autenticacao(colaboradorAuth)));
        assertAcessoNegado(get("/morador/reservas/agenda").with(autenticacao(admin)));
    }

    @Test
    @Transactional
    void deveNegarOperacoesNoServiceParaPerfilSemPermissao() {
        AuthenticatedUser colaborador = authenticatedUser(autenticarComoColaborador());
        AuthenticatedUser morador = authenticatedUser(autenticarComoMorador());

        assertThrows(
                UnauthorizedOperationException.class,
                () -> solicitacaoAreaUseCase.listarReservas(colaborador, PageRequest.of(0, 10))
        );
        assertThrows(
                UnauthorizedOperationException.class,
                () -> solicitacaoAreaUseCase.listarMinhasReservas(colaborador, PageRequest.of(0, 10))
        );
        assertThrows(
                UnauthorizedOperationException.class,
                () -> solicitacaoAreaUseCase.aprovarReserva(morador, UUID.randomUUID())
        );
        assertThrows(
                UnauthorizedOperationException.class,
                () -> solicitacaoAreaUseCase.listarReservas(morador, PageRequest.of(0, 10))
        );
        assertThrows(
                UnauthorizedOperationException.class,
                () -> solicitacaoAreaUseCase.listarReservasNoPeriodo(
                        morador,
                        LocalDateTime.now().plusDays(1),
                        LocalDateTime.now().plusDays(10)
                )
        );
        assertThrows(
                UnauthorizedOperationException.class,
                () -> solicitacaoAreaUseCase.listarMinhasReservasNoPeriodo(
                        colaborador,
                        LocalDateTime.now().plusDays(1),
                        LocalDateTime.now().plusDays(10)
                )
        );
    }

    @Test
    void naoDeveProduzirDuasAprovacoesConflitantesEmDecisoesSimultaneas() throws Exception {
        UUID areaId = criarArea("Concorrencia-" + UUID.randomUUID());
        Authentication moradorA = autenticarComoMorador();
        Authentication moradorB = autenticarComoMorador();
        Authentication admin1 = admin;
        Authentication admin2 = autenticarComoAdministrador();
        LocalDate data = dataFutura();

        LocalDateTime inicio = data.atTime(10, 0);
        LocalDateTime fim = data.atTime(12, 0);
        solicitarReserva(moradorA, areaId, inicio, fim);
        solicitarReserva(moradorB, areaId, inicio.plusMinutes(15), fim.plusMinutes(15));

        UUID reserva1 = buscarReservaId(listarReservasMorador(moradorA), areaId, inicio);
        UUID reserva2 = buscarReservaId(listarReservasMorador(moradorB), areaId, inicio.plusMinutes(15));

        CyclicBarrier barrier = new CyclicBarrier(2);
        ExecutorService executor = Executors.newFixedThreadPool(2);
        List<Future<?>> futures = new ArrayList<>();
        futures.add(executor.submit(() -> aprovarConcorrente(barrier, admin1, reserva1)));
        futures.add(executor.submit(() -> aprovarConcorrente(barrier, admin2, reserva2)));
        for (Future<?> future : futures) {
            future.get();
        }
        executor.shutdown();

        long aprovadas = listarReservasAdmin().stream()
                .filter(reserva -> reserva1.equals(reserva.get("id")) || reserva2.equals(reserva.get("id")))
                .filter(reserva -> STATUS_APROVADO.equals(reserva.get("status")))
                .count();
        assertEquals(1, aprovadas);
    }

    @Test
    @Transactional
    void deveListarNaAgendaSomenteReservasSolicitadasOuAprovadasDaJanela() throws Exception {
        UUID areaId = criarArea("Agenda-" + UUID.randomUUID());
        Authentication morador = autenticarComoMorador();
        Morador moradorEntidade = moradorEntidade(morador);
        LocalDate mes = LocalDate.now().plusMonths(2).withDayOfMonth(1);

        LocalDateTime inicioSolicitado = mes.withDayOfMonth(10).atTime(9, 0);
        SolicitacaoArea solicitada = criarReservaDireta(
                areaId, moradorEntidade, inicioSolicitado, inicioSolicitado.plusHours(2), StatusSolicitacaoArea.SOLICITADO);

        LocalDateTime inicioAprovado = mes.withDayOfMonth(12).atTime(9, 0);
        SolicitacaoArea aprovada = criarReservaDireta(
                areaId, moradorEntidade, inicioAprovado, inicioAprovado.plusHours(2), StatusSolicitacaoArea.APROVADO);

        LocalDateTime inicioNegado = mes.withDayOfMonth(14).atTime(9, 0);
        SolicitacaoArea negada = criarReservaDireta(
                areaId, moradorEntidade, inicioNegado, inicioNegado.plusHours(2), StatusSolicitacaoArea.NEGADO);

        LocalDateTime inicioForaDaJanela = LocalDate.now().plusMonths(8).withDayOfMonth(10).atTime(9, 0);
        SolicitacaoArea foraDaJanela = criarReservaDireta(
                areaId, moradorEntidade, inicioForaDaJanela, inicioForaDaJanela.plusHours(2), StatusSolicitacaoArea.SOLICITADO);

        List<Map<String, Object>> agenda = listarAgenda(mes);
        assertTrue(agenda.stream().anyMatch(reserva -> solicitada.getId().equals(reserva.get("id"))));
        assertTrue(agenda.stream().anyMatch(reserva -> aprovada.getId().equals(reserva.get("id"))));
        assertTrue(agenda.stream().noneMatch(reserva -> negada.getId().equals(reserva.get("id"))));
        assertTrue(agenda.stream().noneMatch(reserva -> foraDaJanela.getId().equals(reserva.get("id"))));
    }

    @Test
    @Transactional
    void deveIncluirNaAgendaReservaQueIntersectaABordaDaJanela() throws Exception {
        UUID areaId = criarArea("Borda-" + UUID.randomUUID());
        Authentication morador = autenticarComoMorador();
        Morador moradorEntidade = moradorEntidade(morador);
        LocalDate referencia = LocalDate.now().plusMonths(2).withDayOfMonth(1);

        LocalDateTime inicioAntesDaJanela = referencia.minusDays(8).atTime(22, 0);
        LocalDateTime fimDentroDaJanela = referencia.minusDays(6).atTime(2, 0);
        SolicitacaoArea reserva = criarReservaDireta(
                areaId, moradorEntidade, inicioAntesDaJanela, fimDentroDaJanela, StatusSolicitacaoArea.SOLICITADO);

        List<Map<String, Object>> agenda = listarAgenda(referencia);
        assertTrue(agenda.stream().anyMatch(item -> reserva.getId().equals(item.get("id"))));
    }

    @Test
    @Transactional
    void deveListarNaAgendaDaSemanaApenasReservasDaSemana() throws Exception {
        UUID areaId = criarArea("Semana-" + UUID.randomUUID());
        Authentication morador = autenticarComoMorador();
        Morador moradorEntidade = moradorEntidade(morador);
        LocalDate referencia = LocalDate.now().plusDays(14).with(DayOfWeek.SUNDAY);

        LocalDateTime dentroDaSemana = referencia.plusDays(2).atTime(10, 0);
        SolicitacaoArea dentro = criarReservaDireta(
                areaId, moradorEntidade, dentroDaSemana, dentroDaSemana.plusHours(2), StatusSolicitacaoArea.SOLICITADO);

        LocalDateTime foraDaSemana = referencia.plusWeeks(1).plusDays(2).atTime(10, 0);
        SolicitacaoArea fora = criarReservaDireta(
                areaId, moradorEntidade, foraDaSemana, foraDaSemana.plusHours(2), StatusSolicitacaoArea.SOLICITADO);

        List<Map<String, Object>> agenda = listarAgendaDaSemana(referencia);
        assertTrue(agenda.stream().anyMatch(item -> dentro.getId().equals(item.get("id"))));
        assertTrue(agenda.stream().noneMatch(item -> fora.getId().equals(item.get("id"))));
    }

    private Morador moradorEntidade(Authentication morador) {
        return moradorRepository.findById(authenticatedUser(morador).id()).orElseThrow();
    }

    @Test
    @Transactional
    void deveListarNaAgendaDoMoradorSomenteAsPropriasReservasComHistorico() throws Exception {
        UUID areaId = criarArea("MinhaAgenda-" + UUID.randomUUID());
        Authentication moradorA = autenticarComoMorador();
        Authentication moradorB = autenticarComoMorador();
        Morador entidadeA = moradorEntidade(moradorA);
        Morador entidadeB = moradorEntidade(moradorB);
        LocalDate mes = LocalDate.now().plusMonths(1).withDayOfMonth(1);

        LocalDateTime inicioA = mes.withDayOfMonth(10).atTime(9, 0);
        SolicitacaoArea deA = criarReservaDireta(
                areaId, entidadeA, inicioA, inicioA.plusHours(2), StatusSolicitacaoArea.SOLICITADO);

        LocalDateTime inicioB = mes.withDayOfMonth(12).atTime(9, 0);
        SolicitacaoArea deB = criarReservaDireta(
                areaId, entidadeB, inicioB, inicioB.plusHours(2), StatusSolicitacaoArea.SOLICITADO);

        LocalDateTime inicioNegado = mes.withDayOfMonth(14).atTime(9, 0);
        SolicitacaoArea negadaA = criarReservaDireta(
                areaId, entidadeA, inicioNegado, inicioNegado.plusHours(2), StatusSolicitacaoArea.NEGADO);

        List<Map<String, Object>> agenda = listarMinhaAgenda(moradorA, mes);
        assertTrue(agenda.stream().anyMatch(reserva -> deA.getId().equals(reserva.get("id"))));
        assertTrue(agenda.stream().noneMatch(reserva -> deB.getId().equals(reserva.get("id"))));
        assertTrue(agenda.stream().anyMatch(reserva -> negadaA.getId().equals(reserva.get("id"))));
    }

    private void assertAcessoNegado(MockHttpServletRequestBuilder request) {
        ServletException exception = assertThrows(ServletException.class, () -> mockMvc.perform(request));
        assertInstanceOf(AccessDeniedException.class, exception.getCause());
    }

    private void aprovarConcorrente(CyclicBarrier barrier, Authentication authentication, UUID reservaId) {
        try {
            barrier.await();
            mockMvc.perform(patch("/admin/reservas/{reservaId}/aprovacao", reservaId)
                            .with(autenticacao(authentication)))
                    .andExpect(status().is3xxRedirection());
        } catch (Exception exception) {
            throw new IllegalStateException(exception);
        }
    }

    private UUID criarArea(String nome) throws Exception {
        mockMvc.perform(post("/admin/areas")
                        .with(autenticacao(admin))
                        .param("nome", nome)
                        .param("status", AREA_STATUS_ATIVO))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/areas"));
        return buscarAreaIdPorNome(nome);
    }

    @SuppressWarnings("unchecked")
    private UUID buscarAreaIdPorNome(String nome) throws Exception {
        MvcResult result = mockMvc.perform(get("/admin/areas")
                        .with(autenticacao(admin))
                        .param("size", "100"))
                .andExpect(status().isOk())
                .andReturn();
        List<Map<String, Object>> areas =
                (List<Map<String, Object>>) result.getModelAndView().getModel().get("areas");
        return areas.stream()
                .filter(area -> nome.equals(area.get("nome")))
                .map(area -> (UUID) area.get("id"))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Area nao encontrada: " + nome));
    }

    private void desativarArea(UUID areaId, String nome) throws Exception {
        mockMvc.perform(patch("/admin/areas/{areaId}", areaId)
                        .with(autenticacao(admin))
                        .param("nome", nome)
                        .param("status", AREA_STATUS_INATIVO))
                .andExpect(status().is3xxRedirection());
    }

    private void solicitarReserva(
            Authentication authentication,
            UUID areaId,
            LocalDateTime inicio,
            LocalDateTime fim
    ) throws Exception {
        mockMvc.perform(post("/morador/reservas")
                        .with(autenticacao(authentication))
                        .param("areaId", areaId.toString())
                        .param("unidadeId", unidadeDoMorador(authentication).toString())
                        .param("inicio", inicio.toString())
                        .param("fim", fim.toString()))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/morador/reservas"));
    }

    private UUID unidadeDoMorador(Authentication authentication) {
        UUID moradorId = authenticatedUser(authentication).id();
        return unidadeRepository.findByMoradorId(moradorId, PageRequest.of(0, 1))
                .getContent()
                .get(0)
                .getId();
    }

    private void aprovar(UUID reservaId) throws Exception {
        mockMvc.perform(patch("/admin/reservas/{reservaId}/aprovacao", reservaId)
                        .with(autenticacao(admin)))
                .andExpect(status().is3xxRedirection());
    }

    private void negar(UUID reservaId, String motivo) throws Exception {
        mockMvc.perform(patch("/admin/reservas/{reservaId}/negacao", reservaId)
                        .with(autenticacao(admin))
                        .param("motivo", motivo))
                .andExpect(status().is3xxRedirection());
    }

    private void cancelarAdmin(UUID reservaId) throws Exception {
        mockMvc.perform(delete("/admin/reservas/{reservaId}", reservaId)
                        .with(autenticacao(admin)))
                .andExpect(status().is3xxRedirection());
    }

    private void cancelarMorador(Authentication authentication, UUID reservaId) throws Exception {
        mockMvc.perform(delete("/morador/reservas/{reservaId}", reservaId)
                        .with(autenticacao(authentication)))
                .andExpect(status().is3xxRedirection());
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> listarReservasMorador(Authentication authentication) throws Exception {
        MvcResult result = mockMvc.perform(get("/morador/reservas")
                        .with(autenticacao(authentication))
                        .param("size", "100"))
                .andExpect(status().isOk())
                .andReturn();
        return (List<Map<String, Object>>) result.getModelAndView().getModel().get("reservas");
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> listarReservasAdmin() throws Exception {
        MvcResult result = mockMvc.perform(get("/admin/reservas")
                        .with(autenticacao(admin))
                        .param("size", "100"))
                .andExpect(status().isOk())
                .andReturn();
        return (List<Map<String, Object>>) result.getModelAndView().getModel().get("reservas");
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> consultarDisponibilidade(
            Authentication authentication,
            UUID areaId,
            LocalDate data
    ) throws Exception {
        MvcResult result = mockMvc.perform(get("/morador/reservas/disponibilidade")
                        .with(autenticacao(authentication))
                        .param("areaId", areaId.toString())
                        .param("data", data.toString()))
                .andExpect(status().isOk())
                .andReturn();
        return (List<Map<String, Object>>) result.getModelAndView().getModel().get("disponibilidade");
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> listarAgenda(LocalDate inicio) throws Exception {
        MvcResult result = mockMvc.perform(get("/admin/reservas/agenda")
                        .with(autenticacao(admin))
                        .param("inicio", inicio.toString()))
                .andExpect(status().isOk())
                .andReturn();
        return (List<Map<String, Object>>) result.getModelAndView().getModel().get("reservas");
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> listarAgendaDaSemana(LocalDate inicio) throws Exception {
        MvcResult result = mockMvc.perform(get("/admin/reservas/agenda")
                        .with(autenticacao(admin))
                        .param("inicio", inicio.toString())
                        .param("view", "semana"))
                .andExpect(status().isOk())
                .andReturn();
        return (List<Map<String, Object>>) result.getModelAndView().getModel().get("reservas");
    }

    @SuppressWarnings("unchecked")
    private List<Map<String, Object>> listarMinhaAgenda(Authentication morador, LocalDate inicio) throws Exception {
        MvcResult result = mockMvc.perform(get("/morador/reservas/agenda")
                        .with(autenticacao(morador))
                        .param("inicio", inicio.toString()))
                .andExpect(status().isOk())
                .andReturn();
        return (List<Map<String, Object>>) result.getModelAndView().getModel().get("reservas");
    }

    private UUID buscarReservaId(List<Map<String, Object>> reservas, UUID areaId, LocalDateTime inicio) {
        return reservas.stream()
                .filter(reserva -> areaId.equals(reserva.get("areaId")) && inicio.equals(reserva.get("inicio")))
                .map(reserva -> (UUID) reserva.get("id"))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Reserva nao encontrada para area " + areaId + " em " + inicio));
    }

    private String statusDe(List<Map<String, Object>> reservas, UUID reservaId) {
        return reservas.stream()
                .filter(reserva -> reservaId.equals(reserva.get("id")))
                .map(reserva -> (String) reserva.get("status"))
                .findFirst()
                .orElse(null);
    }

    private String motivoDe(List<Map<String, Object>> reservas, UUID reservaId) {
        return reservas.stream()
                .filter(reserva -> reservaId.equals(reserva.get("id")))
                .map(reserva -> (String) reserva.get("motivoNegacao"))
                .findFirst()
                .orElse(null);
    }

    private LocalDate dataFutura() {
        return LocalDate.now().plusDays(10);
    }
}
