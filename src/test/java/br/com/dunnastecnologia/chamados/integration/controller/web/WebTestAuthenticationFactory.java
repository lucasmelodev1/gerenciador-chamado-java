package br.com.dunnastecnologia.chamados.infrastructure.controller.web;

import br.com.dunnastecnologia.chamados.domain.model.Administrador;
import br.com.dunnastecnologia.chamados.domain.model.Colaborador;
import br.com.dunnastecnologia.chamados.domain.model.Morador;
import br.com.dunnastecnologia.chamados.domain.model.Usuario;
import br.com.dunnastecnologia.chamados.infrastructure.security.adapter.UserDetailsImpl;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

import java.util.UUID;

final class WebTestAuthenticationFactory {

    private WebTestAuthenticationFactory() {
    }

    static UsernamePasswordAuthenticationToken administrador() {
        return authenticationFor(usuarioAdministrador());
    }

    static UsernamePasswordAuthenticationToken colaborador() {
        return authenticationFor(usuarioColaborador());
    }

    static UsernamePasswordAuthenticationToken morador() {
        return authenticationFor(usuarioMorador());
    }

    static RequestPostProcessor autenticacao(Authentication authentication) {
        return request -> {
            SecurityContextHolder.getContext().setAuthentication(authentication);
            request.setUserPrincipal(authentication);
            return request;
        };
    }

    private static UsernamePasswordAuthenticationToken authenticationFor(Usuario usuario) {
        UserDetailsImpl principal = new UserDetailsImpl(usuario);
        return UsernamePasswordAuthenticationToken.authenticated(
                principal,
                usuario.getSenha(),
                principal.getAuthorities()
        );
    }

    private static Administrador usuarioAdministrador() {
        Administrador administrador = new Administrador();
        administrador.setId(UUID.fromString("00000000-0000-0000-0000-000000000001"));
        administrador.setNome("Administrador");
        administrador.setEmail("admin@condominio.local");
        administrador.setSenha("senha");
        return administrador;
    }

    private static Colaborador usuarioColaborador() {
        Colaborador colaborador = new Colaborador();
        colaborador.setId(UUID.fromString("00000000-0000-0000-0000-000000000002"));
        colaborador.setNome("Colaborador");
        colaborador.setEmail("colaborador@condominio.local");
        colaborador.setSenha("senha");
        return colaborador;
    }

    private static Morador usuarioMorador() {
        Morador morador = new Morador();
        morador.setId(UUID.fromString("00000000-0000-0000-0000-000000000003"));
        morador.setNome("Morador");
        morador.setEmail("morador@condominio.local");
        morador.setSenha("senha");
        return morador;
    }
}
