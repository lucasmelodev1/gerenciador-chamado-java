package br.com.dunnastecnologia.chamados.infrastructure.controller.api;

import br.com.dunnastecnologia.chamados.application.UserCase.SolicitacaoAreaUseCase;
import br.com.dunnastecnologia.chamados.infrastructure.controller.web.WebControllerSupport;
import br.com.dunnastecnologia.chamados.infrastructure.controller.web.form.SolicitacaoAreaForm;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.UUID;

@Controller
@RequestMapping("/morador/reservas")
@PreAuthorize("hasRole('MORADOR')")
public class SolicitacaoAreaApiController {

    private final SolicitacaoAreaUseCase solicitacaoAreaUseCase;
    private final WebControllerSupport support;

    public SolicitacaoAreaApiController(
            SolicitacaoAreaUseCase solicitacaoAreaUseCase,
            WebControllerSupport support
    ) {
        this.solicitacaoAreaUseCase = solicitacaoAreaUseCase;
        this.support = support;
    }

    @Operation(summary = "Solicita a reserva de uma area comum", tags = "15 - Morador Web - Reservas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "302", description = "Reserva solicitada com sucesso e redirecionamento para a listagem."),
            @ApiResponse(responseCode = "400", description = "Dados informados sao invalidos ou violam regra de negocio."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado.")
    })
    @PostMapping
    public String solicitarReserva(
            Authentication authentication,
            @ModelAttribute SolicitacaoAreaForm solicitacaoAreaForm,
            RedirectAttributes redirectAttributes
    ) {
        solicitacaoAreaUseCase.solicitarReserva(
                support.authenticatedUser(authentication),
                solicitacaoAreaForm.getAreaId(),
                solicitacaoAreaForm.getUnidadeId(),
                solicitacaoAreaForm.getInicio(),
                solicitacaoAreaForm.getFim()
        );
        redirectAttributes.addFlashAttribute("successMessage", "Reserva solicitada com sucesso.");
        return "redirect:/morador/reservas";
    }

    @Operation(summary = "Cancela uma reserva do morador autenticado", tags = "15 - Morador Web - Reservas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "302", description = "Reserva cancelada com sucesso e redirecionamento para a listagem."),
            @ApiResponse(responseCode = "400", description = "Dados informados sao invalidos ou violam regra de negocio."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado."),
            @ApiResponse(responseCode = "404", description = "Reserva nao encontrada para o morador.")
    })
    @DeleteMapping("/{reservaId}")
    public String cancelarMinhaReserva(
            Authentication authentication,
            @PathVariable UUID reservaId,
            RedirectAttributes redirectAttributes
    ) {
        solicitacaoAreaUseCase.cancelarMinhaReserva(support.authenticatedUser(authentication), reservaId);
        redirectAttributes.addFlashAttribute("successMessage", "Reserva cancelada com sucesso.");
        return "redirect:/morador/reservas";
    }
}
