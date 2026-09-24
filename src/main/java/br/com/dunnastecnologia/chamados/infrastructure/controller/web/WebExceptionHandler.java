package br.com.dunnastecnologia.chamados.infrastructure.controller.web;

import br.com.dunnastecnologia.chamados.infrastructure.controller.api.AreaApiController;
import br.com.dunnastecnologia.chamados.infrastructure.exception.BusinessRuleException;
import br.com.dunnastecnologia.chamados.infrastructure.exception.ResourceNotFoundException;
import br.com.dunnastecnologia.chamados.infrastructure.exception.UnauthorizedOperationException;
import io.swagger.v3.oas.annotations.Hidden;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@ControllerAdvice(basePackageClasses = {
        AuthWebController.class,
        HomeWebController.class,
        AdminWebController.class,
        MoradorWebController.class,
        ColaboradorWebController.class,
        AreaApiController.class
})
@Hidden
public class WebExceptionHandler {

    private final WebControllerSupport support;

    public WebExceptionHandler(WebControllerSupport support) {
        this.support = support;
    }

    @ExceptionHandler({
            BusinessRuleException.class,
            ResourceNotFoundException.class,
            UnauthorizedOperationException.class,
            IllegalArgumentException.class,
            MaxUploadSizeExceededException.class
    })
    public String handleKnownExceptions(
            RuntimeException exception,
            HttpServletRequest request,
            RedirectAttributes redirectAttributes,
            Authentication authentication
    ) {
        String errorMessage = exception instanceof MaxUploadSizeExceededException
                ? "O arquivo enviado excede o limite de 5 MB."
                : exception.getMessage();
        redirectAttributes.addFlashAttribute("errorMessage", errorMessage);

        String referer = request.getHeader("Referer");
        if (referer != null && !referer.isBlank()) {
            return "redirect:" + referer;
        }

        if (support.isAuthenticated(authentication)) {
            return "redirect:" + support.homePathForRole(support.authenticatedUser(authentication).role());
        }

        return "redirect:/login";
    }
}
