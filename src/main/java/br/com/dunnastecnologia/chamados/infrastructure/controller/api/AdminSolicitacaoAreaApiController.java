package br.com.dunnastecnologia.chamados.infrastructure.controller.api;

import br.com.dunnastecnologia.chamados.application.UserCase.SolicitacaoAreaUseCase;
import br.com.dunnastecnologia.chamados.infrastructure.controller.web.WebControllerSupport;
import br.com.dunnastecnologia.chamados.infrastructure.controller.web.form.NegarReservaForm;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.UUID;

@Controller
@RequestMapping("/admin/reservas")
@PreAuthorize("hasRole('ADMINISTRADOR')")
public class AdminSolicitacaoAreaApiController {

    private final SolicitacaoAreaUseCase solicitacaoAreaUseCase;
    private final WebControllerSupport support;

    public AdminSolicitacaoAreaApiController(
            SolicitacaoAreaUseCase solicitacaoAreaUseCase,
            WebControllerSupport support
    ) {
        this.solicitacaoAreaUseCase = solicitacaoAreaUseCase;
        this.support = support;
    }

    @Operation(summary = "Aprova uma solicitacao de reserva", tags = "16 - Admin Web - Reservas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "302", description = "Reserva aprovada com sucesso e redirecionamento para a listagem."),
            @ApiResponse(responseCode = "400", description = "Dados informados sao invalidos ou violam regra de negocio."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado."),
            @ApiResponse(responseCode = "404", description = "Reserva nao encontrada.")
    })
    @PatchMapping("/{reservaId}/aprovacao")
    public String aprovarReserva(
            Authentication authentication,
            @PathVariable UUID reservaId,
            RedirectAttributes redirectAttributes
    ) {
        solicitacaoAreaUseCase.aprovarReserva(support.authenticatedUser(authentication), reservaId);
        redirectAttributes.addFlashAttribute("successMessage", "Reserva aprovada com sucesso.");
        return "redirect:/admin/reservas";
    }

    @Operation(summary = "Nega uma solicitacao de reserva com motivo", tags = "16 - Admin Web - Reservas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "302", description = "Reserva negada com sucesso e redirecionamento para a listagem."),
            @ApiResponse(responseCode = "400", description = "Motivo ausente ou dados invalidos."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado."),
            @ApiResponse(responseCode = "404", description = "Reserva nao encontrada.")
    })
    @PatchMapping("/{reservaId}/negacao")
    public String negarReserva(
            Authentication authentication,
            @PathVariable UUID reservaId,
            @ModelAttribute NegarReservaForm negarReservaForm,
            RedirectAttributes redirectAttributes
    ) {
        solicitacaoAreaUseCase.negarReserva(
                support.authenticatedUser(authentication),
                reservaId,
                negarReservaForm.getMotivo()
        );
        redirectAttributes.addFlashAttribute("successMessage", "Reserva negada com sucesso.");
        return "redirect:/admin/reservas";
    }

    @Operation(summary = "Cancela uma reserva", tags = "16 - Admin Web - Reservas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "302", description = "Reserva cancelada com sucesso e redirecionamento para a listagem."),
            @ApiResponse(responseCode = "400", description = "Dados informados sao invalidos ou violam regra de negocio."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado."),
            @ApiResponse(responseCode = "404", description = "Reserva nao encontrada.")
    })
    @DeleteMapping("/{reservaId}")
    public String cancelarReserva(
            Authentication authentication,
            @PathVariable UUID reservaId,
            RedirectAttributes redirectAttributes
    ) {
        solicitacaoAreaUseCase.cancelarReserva(support.authenticatedUser(authentication), reservaId);
        redirectAttributes.addFlashAttribute("successMessage", "Reserva cancelada com sucesso.");
        return "redirect:/admin/reservas";
    }
}
