package br.com.dunnastecnologia.chamados.integration.support;

import br.com.dunnastecnologia.chamados.domain.model.Administrador;
import br.com.dunnastecnologia.chamados.domain.model.Usuario;
import br.com.dunnastecnologia.chamados.application.Security.AuthenticatedUser;
import br.com.dunnastecnologia.chamados.infrastructure.repository.UsuarioRepository;
import br.com.dunnastecnologia.chamados.infrastructure.security.adapter.UserDetailsImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import java.util.UUID;

/**
 * Base para os testes de integracao. Sobe o contexto completo (banco PostgreSQL dedicado da suite)
 * com Hibernate validando o schema criado pelas migrations do Flyway.
 */
@SpringBootTest
@AutoConfigureMockMvc(addFilters = false)
public abstract class IntegrationTestSupport {

    @Autowired
    protected MockMvc mockMvc;

    @Autowired
    protected UsuarioRepository usuarioRepository;

    protected Authentication autenticarComoAdministrador() {
        Administrador administrador = new Administrador();
        administrador.setNome("Administrador de Teste");
        administrador.setEmail("admin.teste." + UUID.randomUUID() + "@condominio.local");
        administrador.setSenha("senha");
        usuarioRepository.save(administrador);
        return autenticacaoDe(administrador);
    }

    protected AuthenticatedUser authenticatedUser(Authentication authentication) {
        UserDetailsImpl principal = (UserDetailsImpl) authentication.getPrincipal();
        Usuario usuario = principal.getUsuario();
        return new AuthenticatedUser(usuario.getId(), usuario.getEmail(), usuario.getRole());
    }

    /**
     * Injeta a autenticacao no {@link SecurityContextHolder} e no principal da request, ja que os
     * filtros de seguranca estao desabilitados ({@code addFilters = false}) no MockMvc dos testes.
     */
    protected RequestPostProcessor autenticacao(Authentication authentication) {
        return request -> {
            SecurityContextHolder.getContext().setAuthentication(authentication);
            request.setUserPrincipal(authentication);
            return request;
        };
    }

    private Authentication autenticacaoDe(Usuario usuario) {
        UserDetailsImpl principal = new UserDetailsImpl(usuario);
        return UsernamePasswordAuthenticationToken.authenticated(
                principal,
                usuario.getSenha(),
                principal.getAuthorities()
        );
    }
}
