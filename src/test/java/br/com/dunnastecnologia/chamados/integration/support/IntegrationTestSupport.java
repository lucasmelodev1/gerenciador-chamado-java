package br.com.dunnastecnologia.chamados.integration.support;

import br.com.dunnastecnologia.chamados.domain.model.Administrador;
import br.com.dunnastecnologia.chamados.domain.model.Bloco;
import br.com.dunnastecnologia.chamados.domain.model.Colaborador;
import br.com.dunnastecnologia.chamados.domain.model.Morador;
import br.com.dunnastecnologia.chamados.domain.model.SolicitacaoArea;
import br.com.dunnastecnologia.chamados.domain.model.StatusSolicitacaoArea;
import br.com.dunnastecnologia.chamados.domain.model.Unidade;
import br.com.dunnastecnologia.chamados.domain.model.Usuario;
import br.com.dunnastecnologia.chamados.application.Security.AuthenticatedUser;
import br.com.dunnastecnologia.chamados.infrastructure.repository.AreaRepository;
import br.com.dunnastecnologia.chamados.infrastructure.repository.BlocoRepository;
import br.com.dunnastecnologia.chamados.infrastructure.repository.ColaboradorRepository;
import br.com.dunnastecnologia.chamados.infrastructure.repository.MoradorRepository;
import br.com.dunnastecnologia.chamados.infrastructure.repository.SolicitacaoAreaRepository;
import br.com.dunnastecnologia.chamados.infrastructure.repository.UnidadeRepository;
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

import java.time.LocalDateTime;
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

    @Autowired
    protected MoradorRepository moradorRepository;

    @Autowired
    protected ColaboradorRepository colaboradorRepository;

    @Autowired
    protected BlocoRepository blocoRepository;

    @Autowired
    protected UnidadeRepository unidadeRepository;

    @Autowired
    protected AreaRepository areaRepository;

    @Autowired
    protected SolicitacaoAreaRepository solicitacaoAreaRepository;

    protected Authentication autenticarComoAdministrador() {
        Administrador administrador = new Administrador();
        administrador.setNome("Administrador de Teste");
        administrador.setEmail("admin.teste." + UUID.randomUUID() + "@condominio.local");
        administrador.setSenha("senha");
        usuarioRepository.save(administrador);
        return autenticacaoDe(administrador);
    }

    protected Authentication autenticarComoMorador() {
        return autenticacaoDe(criarMoradorComUnidade());
    }

    protected Authentication autenticarComoColaborador() {
        Colaborador colaborador = new Colaborador();
        colaborador.setNome("Colaborador de Teste");
        colaborador.setEmail("colaborador.teste." + UUID.randomUUID() + "@condominio.local");
        colaborador.setSenha("senha");
        colaboradorRepository.save(colaborador);
        return autenticacaoDe(colaborador);
    }

    /**
     * Cria um morador com uma unidade vinculada. Os testes derivam essa unidade para informar
     * `unidadeId` na solicitacao, que agora e escolhida explicitamente pelo morador.
     */
    protected Morador criarMoradorComUnidade() {
        Bloco bloco = new Bloco();
        bloco.setIdentificacao("Bloco-" + UUID.randomUUID());
        blocoRepository.save(bloco);

        Unidade unidade = new Unidade();
        unidade.setIdentificacao("Unidade-" + UUID.randomUUID());
        unidade.setAndar(1);
        unidade.setBloco(bloco);
        unidadeRepository.save(unidade);

        Morador morador = new Morador();
        morador.setNome("Morador de Teste");
        morador.setEmail("morador.teste." + UUID.randomUUID() + "@condominio.local");
        morador.setSenha("senha");
        morador.getUnidades().add(unidade);
        return moradorRepository.save(morador);
    }

    /**
     * Insere uma reserva diretamente pelo repositorio. Usado apenas para preparar estados que a API
     * recusa criar (por exemplo, inicio no passado) e testar o ciclo de vida a partir deles.
     */
    protected SolicitacaoArea criarReservaDireta(
            UUID areaId,
            Morador morador,
            LocalDateTime inicio,
            LocalDateTime fim,
            StatusSolicitacaoArea status
    ) {
        SolicitacaoArea solicitacao = new SolicitacaoArea();
        solicitacao.setArea(areaRepository.getReferenceById(areaId));
        solicitacao.setMorador(morador);
        solicitacao.setUnidade(morador.getUnidades().iterator().next());
        solicitacao.setInicio(inicio);
        solicitacao.setFim(fim);
        solicitacao.setStatus(status);
        return solicitacaoAreaRepository.saveAndFlush(solicitacao);
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

    protected Authentication autenticacaoDe(Usuario usuario) {
        UserDetailsImpl principal = new UserDetailsImpl(usuario);
        return UsernamePasswordAuthenticationToken.authenticated(
                principal,
                usuario.getSenha(),
                principal.getAuthorities()
        );
    }
}
