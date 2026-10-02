package br.com.dunnastecnologia.chamados.infrastructure.audit;

import br.com.dunnastecnologia.chamados.domain.model.Usuario;
import br.com.dunnastecnologia.chamados.infrastructure.security.adapter.UserDetailsImpl;
import org.hibernate.envers.RevisionListener;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

/**
 * Preenche o snapshot do ator em cada revisao. O Envers instancia o listener por reflexao, entao o
 * usuario e lido do {@link SecurityContextHolder}. Sem autenticacao (bootstrap, login, scheduler) os
 * campos ficam nulos, identificando uma acao do sistema.
 */
public class RevisaoListener implements RevisionListener {

    @Override
    public void newRevision(Object revisionEntity) {
        Revisao revisao = (Revisao) revisionEntity;
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof UserDetailsImpl userDetails)) {
            return;
        }

        Usuario usuario = userDetails.getUsuario();
        revisao.setUsuarioId(usuario.getId());
        revisao.setUsuarioEmail(usuario.getEmail());
        revisao.setUsuarioRole(usuario.getRole());
    }
}
