package br.com.dunnastecnologia.chamados.infrastructure.controller.web;

import br.com.dunnastecnologia.chamados.application.UserCase.MoradorUseCases;
import br.com.dunnastecnologia.chamados.application.UserCase.SolicitacaoAreaUseCase;
import br.com.dunnastecnologia.chamados.domain.model.SolicitacaoArea;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Controller
@RequestMapping("/morador/reservas")
@PreAuthorize("hasRole('MORADOR')")
public class MoradorSolicitacaoAreaWebController {

    private final SolicitacaoAreaUseCase solicitacaoAreaUseCase;
    private final MoradorUseCases moradorUseCases;
    private final WebControllerSupport support;

    public MoradorSolicitacaoAreaWebController(
            SolicitacaoAreaUseCase solicitacaoAreaUseCase,
            MoradorUseCases moradorUseCases,
            WebControllerSupport support
    ) {
        this.solicitacaoAreaUseCase = solicitacaoAreaUseCase;
        this.moradorUseCases = moradorUseCases;
        this.support = support;
    }

    @Operation(summary = "Lista as reservas do morador autenticado", tags = "15 - Morador Web - Reservas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pagina de reservas do morador renderizada com sucesso."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado.")
    })
    @GetMapping
    @Transactional(readOnly = true)
    public String listarMinhasReservas(
            Authentication authentication,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "10") Integer size,
            Model model
    ) {
        var currentUser = support.authenticatedUser(authentication);
        var reservas = solicitacaoAreaUseCase.listarMinhasReservas(currentUser, support.pageRequest(page, size));

        model.addAttribute("pageTitle", "Minhas Reservas");
        model.addAttribute("reservas", support.mapContent(reservas.content(), support::toSolicitacaoAreaMap));
        model.addAttribute("reservasPage", support.pageMetadata(reservas));
        return "morador/reservas/lista";
    }

    @Operation(summary = "Exibe a agenda das reservas do morador autenticado", tags = "15 - Morador Web - Reservas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pagina de agenda renderizada com sucesso."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado.")
    })
    @GetMapping("/agenda")
    @Transactional(readOnly = true)
    public String agenda(
            Authentication authentication,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam(defaultValue = "mes") String view,
            Model model
    ) {
        var currentUser = support.authenticatedUser(authentication);
        var periodo = support.periodoAgenda(inicio, "semana".equalsIgnoreCase(view));
        var reservas = solicitacaoAreaUseCase.listarMinhasReservasNoPeriodo(
                currentUser, periodo.janelaInicio(), periodo.janelaFim());

        model.addAttribute("pageTitle", "Minha Agenda");
        model.addAttribute("calendarAssets", true);
        support.adicionarPeriodoAgenda(model, periodo);
        model.addAttribute("reservas", support.mapContent(reservas, support::toSolicitacaoAreaMap));
        model.addAttribute("areasFiltro", support.areasDasReservas(reservas));
        return "morador/reservas/agenda";
    }

    @Operation(summary = "Exibe o formulario de solicitacao de reserva", tags = "15 - Morador Web - Reservas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Formulario de reserva renderizado com sucesso."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado.")
    })
    @GetMapping("/nova")
    @Transactional(readOnly = true)
    public String novaReserva(
            Authentication authentication,
            Model model
    ) {
        var currentUser = support.authenticatedUser(authentication);
        var areas = solicitacaoAreaUseCase.listarAreasDisponiveis(currentUser);
        var unidades = moradorUseCases.listarMinhasUnidades(currentUser, support.pageRequest(0, 100));

        model.addAttribute("pageTitle", "Nova Reserva");
        model.addAttribute("areas", support.mapContent(areas, support::toAreaMap));
        model.addAttribute("unidades", support.mapContent(unidades.content(), support::toUnidadeMap));
        return "morador/reservas/nova";
    }

    @Operation(summary = "Consulta a disponibilidade de uma area em uma data", tags = "15 - Morador Web - Reservas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pagina de disponibilidade da area renderizada com sucesso."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado.")
    })
    @GetMapping("/disponibilidade")
    @Transactional(readOnly = true)
    public String consultarDisponibilidade(
            Authentication authentication,
            @RequestParam(required = false) UUID areaId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate data,
            Model model
    ) {
        var currentUser = support.authenticatedUser(authentication);
        boolean consultou = areaId != null && data != null;
        List<SolicitacaoArea> disponibilidade = consultou
                ? solicitacaoAreaUseCase.consultarDisponibilidade(currentUser, areaId, data)
                : List.of();
        var areas = solicitacaoAreaUseCase.listarAreasDisponiveis(currentUser);

        model.addAttribute("pageTitle", "Disponibilidade da Area");
        model.addAttribute("areas", support.mapContent(areas, support::toAreaMap));
        model.addAttribute("areaId", areaId);
        model.addAttribute("data", data);
        model.addAttribute("consultou", consultou);
        model.addAttribute("disponibilidade", support.mapContent(disponibilidade, support::toSolicitacaoAreaMap));
        return "morador/reservas/disponibilidade";
    }
}
