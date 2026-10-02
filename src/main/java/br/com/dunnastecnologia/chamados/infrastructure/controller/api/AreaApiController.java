package br.com.dunnastecnologia.chamados.infrastructure.controller.api;

import br.com.dunnastecnologia.chamados.application.UserCase.AreaUseCase;
import br.com.dunnastecnologia.chamados.domain.model.StatusArea;
import br.com.dunnastecnologia.chamados.infrastructure.controller.web.WebControllerSupport;
import br.com.dunnastecnologia.chamados.infrastructure.controller.web.form.AreaForm;
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
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.UUID;

@Controller
@RequestMapping("/admin/areas")
@PreAuthorize("hasRole('ADMINISTRADOR')")
public class AreaApiController {

    private final AreaUseCase areaUseCase;
    private final WebControllerSupport support;

    public AreaApiController(AreaUseCase areaUseCase, WebControllerSupport support) {
        this.areaUseCase = areaUseCase;
        this.support = support;
    }

    @Operation(summary = "Cadastra uma nova area", tags = "14 - Admin Web - Areas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "302", description = "Area cadastrada com sucesso e redirecionamento para a listagem."),
            @ApiResponse(responseCode = "400", description = "Dados informados sao invalidos ou violam regra de negocio."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado.")
    })
    @PostMapping
    public String cadastrarArea(
            Authentication authentication,
            @ModelAttribute AreaForm areaForm,
            RedirectAttributes redirectAttributes
    ) {
        areaUseCase.cadastrarArea(
                support.authenticatedUser(authentication),
                areaForm.getNome(),
                parseStatus(areaForm.getStatus())
        );
        redirectAttributes.addFlashAttribute("successMessage", "Area cadastrada com sucesso.");
        return "redirect:/admin/areas";
    }

    @Operation(summary = "Atualiza uma area", tags = "14 - Admin Web - Areas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "302", description = "Area atualizada com sucesso e redirecionamento para o detalhe."),
            @ApiResponse(responseCode = "400", description = "Dados informados sao invalidos ou violam regra de negocio."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado."),
            @ApiResponse(responseCode = "404", description = "Area nao encontrada.")
    })
    @PatchMapping("/{areaId}")
    public String atualizarArea(
            Authentication authentication,
            @PathVariable UUID areaId,
            @ModelAttribute AreaForm areaForm,
            RedirectAttributes redirectAttributes
    ) {
        areaUseCase.atualizarArea(
                support.authenticatedUser(authentication),
                areaId,
                areaForm.getNome(),
                parseStatus(areaForm.getStatus())
        );
        redirectAttributes.addFlashAttribute("successMessage", "Area atualizada com sucesso.");
        return "redirect:/admin/areas?areaId=" + areaId;
    }

    @Operation(summary = "Remove uma area", tags = "14 - Admin Web - Areas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "302", description = "Area removida com sucesso e redirecionamento para a listagem."),
            @ApiResponse(responseCode = "400", description = "Dados informados sao invalidos ou violam regra de negocio."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado."),
            @ApiResponse(responseCode = "404", description = "Area nao encontrada.")
    })
    @DeleteMapping("/{areaId}")
    public String removerArea(
            Authentication authentication,
            @PathVariable UUID areaId,
            RedirectAttributes redirectAttributes
    ) {
        areaUseCase.removerArea(support.authenticatedUser(authentication), areaId);
        redirectAttributes.addFlashAttribute("successMessage", "Area removida com sucesso.");
        return "redirect:/admin/areas";
    }

    private StatusArea parseStatus(String status) {
        if (status == null || status.isBlank()) {
            return null;
        }
        return StatusArea.fromValor(status);
    }
}
