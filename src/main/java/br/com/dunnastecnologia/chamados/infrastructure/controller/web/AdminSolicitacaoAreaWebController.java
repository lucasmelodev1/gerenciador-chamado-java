package br.com.dunnastecnologia.chamados.infrastructure.controller.web;

import br.com.dunnastecnologia.chamados.application.UserCase.SolicitacaoAreaUseCase;
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
import java.time.LocalDateTime;

@Controller
@RequestMapping("/admin/reservas")
@PreAuthorize("hasRole('ADMINISTRADOR')")
public class AdminSolicitacaoAreaWebController {

    private final SolicitacaoAreaUseCase solicitacaoAreaUseCase;
    private final WebControllerSupport support;

    public AdminSolicitacaoAreaWebController(
            SolicitacaoAreaUseCase solicitacaoAreaUseCase,
            WebControllerSupport support
    ) {
        this.solicitacaoAreaUseCase = solicitacaoAreaUseCase;
        this.support = support;
    }

    @Operation(summary = "Lista as reservas de todos os moradores", tags = "16 - Admin Web - Reservas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pagina de reservas do condominio renderizada com sucesso."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado.")
    })
    @GetMapping
    @Transactional(readOnly = true)
    public String listarReservas(
            Authentication authentication,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "10") Integer size,
            Model model
    ) {
        var currentUser = support.authenticatedUser(authentication);
        var reservas = solicitacaoAreaUseCase.listarReservas(currentUser, support.pageRequest(page, size));

        model.addAttribute("pageTitle", "Reservas");
        model.addAttribute("reservas", support.mapContent(reservas.content(), support::toSolicitacaoAreaMap));
        model.addAttribute("reservasPage", support.pageMetadata(reservas));
        return "admin/reservas/lista";
    }

    @Operation(summary = "Exibe o calendario de reservas por periodo", tags = "16 - Admin Web - Reservas")
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
        var reservas = solicitacaoAreaUseCase.listarReservasNoPeriodo(
                currentUser, periodo.janelaInicio(), periodo.janelaFim());

        model.addAttribute("pageTitle", "Agenda de Reservas");
        model.addAttribute("calendarAssets", true);
        support.adicionarPeriodoAgenda(model, periodo);
        model.addAttribute("reservas", support.mapContent(reservas, support::toSolicitacaoAreaMap));
        model.addAttribute("areasFiltro", support.areasDasReservas(reservas));
        return "admin/reservas/agenda";
    }
}
