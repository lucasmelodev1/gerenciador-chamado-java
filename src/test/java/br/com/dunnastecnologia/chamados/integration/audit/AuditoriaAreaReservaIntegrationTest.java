package br.com.dunnastecnologia.chamados.integration.audit;

import br.com.dunnastecnologia.chamados.application.Security.AuthenticatedUser;
import br.com.dunnastecnologia.chamados.application.UserCase.AreaUseCase;
import br.com.dunnastecnologia.chamados.application.UserCase.SolicitacaoAreaUseCase;
import br.com.dunnastecnologia.chamados.domain.model.Area;
import br.com.dunnastecnologia.chamados.domain.model.SolicitacaoArea;
import br.com.dunnastecnologia.chamados.domain.model.StatusArea;
import br.com.dunnastecnologia.chamados.domain.model.StatusSolicitacaoArea;
import br.com.dunnastecnologia.chamados.domain.model.Unidade;
import br.com.dunnastecnologia.chamados.infrastructure.audit.Revisao;
import br.com.dunnastecnologia.chamados.integration.support.IntegrationTestSupport;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.hibernate.envers.AuditReader;
import org.hibernate.envers.AuditReaderFactory;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Verifica que a auditoria (Envers) registra revisoes, snapshot do ator e a remocao logica das areas
 * e reservas. Os testes nao sao {@code @Transactional}: o Envers grava as revisoes ao final da
 * transacao, entao cada chamada de servico commita e o historico e lido em uma transacao de leitura.
 */
class AuditoriaAreaReservaIntegrationTest extends IntegrationTestSupport {

    @Autowired
    private AreaUseCase areaUseCase;

    @Autowired
    private SolicitacaoAreaUseCase solicitacaoAreaUseCase;

    @Autowired
    private PlatformTransactionManager transactionManager;

    @PersistenceContext
    private EntityManager entityManager;

    @AfterEach
    void limpar() {
        SecurityContextHolder.clearContext();
        new TransactionTemplate(transactionManager).execute(status -> {
            entityManager.createNativeQuery("delete from solicitacoes_area_aud").executeUpdate();
            entityManager.createNativeQuery("delete from areas_aud").executeUpdate();
            entityManager.createNativeQuery("delete from revinfo").executeUpdate();
            entityManager.createNativeQuery("delete from solicitacoes_area").executeUpdate();
            entityManager.createNativeQuery("delete from areas").executeUpdate();
            return null;
        });
    }

    @Test
    void deveRegistrarRevisaoComSnapshotDoAtorAoCadastrarArea() {
        Authentication adminAuth = autenticarComoAdministrador();
        AuthenticatedUser admin = authenticatedUser(adminAuth);
        SecurityContextHolder.getContext().setAuthentication(adminAuth);

        Area area = areaUseCase.cadastrarArea(admin, "Salao-" + UUID.randomUUID(), StatusArea.ATIVO);

        new TransactionTemplate(transactionManager).execute(status -> {
            AuditReader auditReader = AuditReaderFactory.get(entityManager);
            List<Number> revisoes = auditReader.getRevisions(Area.class, area.getId());

            assertEquals(1, revisoes.size());
            Revisao revisao = auditReader.findRevision(Revisao.class, revisoes.get(0));
            assertEquals(admin.id(), revisao.getUsuarioId());
            assertEquals(admin.username(), revisao.getUsuarioEmail());
            assertEquals("ROLE_ADMINISTRADOR", revisao.getUsuarioRole());
            assertTrue(revisao.getTimestamp() > 0);
            assertEquals(StatusArea.ATIVO, auditReader.find(Area.class, area.getId(), revisoes.get(0)).getStatus());
            return null;
        });
    }

    @Test
    void deveAuditarTransicoesDaReservaComAtorPorRevisao() {
        Authentication adminAuth = autenticarComoAdministrador();
        AuthenticatedUser admin = authenticatedUser(adminAuth);
        Authentication moradorAuth = autenticarComoMorador();
        AuthenticatedUser morador = authenticatedUser(moradorAuth);

        SecurityContextHolder.getContext().setAuthentication(adminAuth);
        Area area = areaUseCase.cadastrarArea(admin, "Quadra-" + UUID.randomUUID(), StatusArea.ATIVO);

        Unidade unidade = unidadeRepository.findByMoradorId(morador.id(), PageRequest.of(0, 1))
                .getContent()
                .get(0);

        SecurityContextHolder.getContext().setAuthentication(moradorAuth);
        LocalDateTime inicio = LocalDateTime.now().plusDays(2);
        SolicitacaoArea reserva = solicitacaoAreaUseCase.solicitarReserva(
                morador, area.getId(), unidade.getId(), inicio, inicio.plusHours(2));

        SecurityContextHolder.getContext().setAuthentication(adminAuth);
        solicitacaoAreaUseCase.aprovarReserva(admin, reserva.getId());

        new TransactionTemplate(transactionManager).execute(status -> {
            AuditReader auditReader = AuditReaderFactory.get(entityManager);
            List<Number> revisoes = auditReader.getRevisions(SolicitacaoArea.class, reserva.getId());

            assertEquals(2, revisoes.size());
            assertEquals(
                    StatusSolicitacaoArea.SOLICITADO,
                    auditReader.find(SolicitacaoArea.class, reserva.getId(), revisoes.get(0)).getStatus()
            );
            assertEquals(
                    StatusSolicitacaoArea.APROVADO,
                    auditReader.find(SolicitacaoArea.class, reserva.getId(), revisoes.get(1)).getStatus()
            );
            assertEquals(morador.username(), auditReader.findRevision(Revisao.class, revisoes.get(0)).getUsuarioEmail());
            assertEquals(admin.username(), auditReader.findRevision(Revisao.class, revisoes.get(1)).getUsuarioEmail());
            return null;
        });
    }

    @Test
    void deveAuditarRemocaoLogicaDaAreaComDeletedAt() {
        Authentication adminAuth = autenticarComoAdministrador();
        AuthenticatedUser admin = authenticatedUser(adminAuth);
        SecurityContextHolder.getContext().setAuthentication(adminAuth);

        Area area = areaUseCase.cadastrarArea(admin, "Churrasqueira-" + UUID.randomUUID(), StatusArea.ATIVO);
        areaUseCase.removerArea(admin, area.getId());

        new TransactionTemplate(transactionManager).execute(status -> {
            AuditReader auditReader = AuditReaderFactory.get(entityManager);
            List<Number> revisoes = auditReader.getRevisions(Area.class, area.getId());
            assertTrue(revisoes.size() >= 2);

            Area naRemocao = auditReader.find(Area.class, area.getId(), revisoes.get(revisoes.size() - 1));
            assertNotNull(naRemocao);
            assertNotNull(naRemocao.getDeletedAt());
            return null;
        });
    }
}
