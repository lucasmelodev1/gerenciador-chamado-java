package br.com.dunnastecnologia.chamados.infrastructure.controller.api;

import br.com.dunnastecnologia.chamados.application.Security.AuthenticatedUser;
import br.com.dunnastecnologia.chamados.application.UserCase.AreaUseCase;
import br.com.dunnastecnologia.chamados.application.pagination.PageResult;
import br.com.dunnastecnologia.chamados.domain.model.Area;
import br.com.dunnastecnologia.chamados.domain.model.StatusArea;
import br.com.dunnastecnologia.chamados.infrastructure.exception.ResourceNotFoundException;
import br.com.dunnastecnologia.chamados.infrastructure.exception.UnauthorizedOperationException;
import br.com.dunnastecnologia.chamados.integration.support.IntegrationTestSupport;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.flash;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@Transactional
class AreaApiIntegrationTest extends IntegrationTestSupport {

    private static final String AREA_STATUS_ATIVO = "Ativo";
    private static final String AREA_STATUS_INATIVO = "Inativo";

    @Autowired
    private AreaUseCase areaUseCase;

    @PersistenceContext
    private EntityManager entityManager;

    private Authentication adminAuthentication;
    private AuthenticatedUser admin;
    private String areaNome;

    @BeforeEach
    void setUp() {
        adminAuthentication = autenticarComoAdministrador();
        admin = authenticatedUser(adminAuthentication);
        areaNome = "Manutencao-" + UUID.randomUUID();
    }

    @Test
    void deveCadastrarAreaViaApiEConsultarPorId() throws Exception {
        cadastrarAreaViaApi(areaNome, AREA_STATUS_ATIVO);

        Area area = areaUseCase.buscarAreaPorId(admin, buscarIdPorNome(areaNome));

        assertEquals(areaNome, area.getNome());
        assertEquals(StatusArea.ATIVO, area.getStatus());
    }

    @Test
    void deveCadastrarAreaComStatusPadraoAtivoQuandoNaoInformado() throws Exception {
        mockMvc.perform(post("/admin/areas")
                        .with(autenticacao(adminAuthentication))
                        .param("nome", areaNome))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/areas"));

        Area area = areaUseCase.buscarAreaPorId(admin, buscarIdPorNome(areaNome));

        assertEquals(StatusArea.ATIVO, area.getStatus());
    }

    @Test
    void deveListarAreasCadastradasViaApi() {
        String segundaAreaNome = "Zeladoria-" + UUID.randomUUID();
        cadastrarAreaViaApi(areaNome, AREA_STATUS_ATIVO);
        cadastrarAreaViaApi(segundaAreaNome, AREA_STATUS_INATIVO);

        // A suite compartilha um banco persistente e testes nao transacionais (concorrencia) deixam
        // areas acumuladas; por isso a busca percorre as paginas em vez de assumir uma unica pagina.
        boolean encontrouArea = false;
        boolean encontrouSegunda = false;
        for (int page = 0; !(encontrouArea && encontrouSegunda); page++) {
            PageResult<Area> pageResult = areaUseCase.listarAreas(admin, PageRequest.of(page, 50));
            encontrouArea = encontrouArea || pageResult.content().stream()
                    .anyMatch(area -> areaNome.equals(area.getNome()));
            encontrouSegunda = encontrouSegunda || pageResult.content().stream()
                    .anyMatch(area -> segundaAreaNome.equals(area.getNome()));
            if (page + 1 >= pageResult.totalPages()) {
                break;
            }
        }

        assertTrue(encontrouArea);
        assertTrue(encontrouSegunda);
    }

    @Test
    void deveAtualizarAreaViaApiEConsultarPorId() throws Exception {
        cadastrarAreaViaApi(areaNome, AREA_STATUS_ATIVO);
        UUID areaId = buscarIdPorNome(areaNome);
        String nomeAtualizado = areaNome + "-Predial";

        mockMvc.perform(patch("/admin/areas/{areaId}", areaId)
                        .with(autenticacao(adminAuthentication))
                        .param("nome", nomeAtualizado)
                        .param("status", AREA_STATUS_INATIVO))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/areas?areaId=" + areaId));

        Area area = areaUseCase.buscarAreaPorId(admin, areaId);

        assertEquals(nomeAtualizado, area.getNome());
        assertEquals(StatusArea.INATIVO, area.getStatus());
    }

    @Test
    void devePreservarStatusAoAtualizarAreaSemInformarStatus() throws Exception {
        cadastrarAreaViaApi(areaNome, AREA_STATUS_INATIVO);
        UUID areaId = buscarIdPorNome(areaNome);
        String nomeAtualizado = areaNome + "-Predial";

        mockMvc.perform(patch("/admin/areas/{areaId}", areaId)
                        .with(autenticacao(adminAuthentication))
                        .param("nome", nomeAtualizado))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/areas?areaId=" + areaId));

        Area area = areaUseCase.buscarAreaPorId(admin, areaId);

        assertEquals(nomeAtualizado, area.getNome());
        assertEquals(StatusArea.INATIVO, area.getStatus());
    }

    @Test
    void deveRemoverAreaViaApiEConfirmarAusenciaPorId() throws Exception {
        cadastrarAreaViaApi(areaNome, AREA_STATUS_ATIVO);
        UUID areaId = buscarIdPorNome(areaNome);

        mockMvc.perform(delete("/admin/areas/{areaId}", areaId)
                        .with(autenticacao(adminAuthentication)))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin/areas"));

        entityManager.flush();
        entityManager.clear();

        assertThrows(ResourceNotFoundException.class, () -> areaUseCase.buscarAreaPorId(admin, areaId));
    }

    @Test
    void deveRemoverAreaDaListagemAposSoftDelete() throws Exception {
        cadastrarAreaViaApi(areaNome, AREA_STATUS_ATIVO);
        UUID areaId = buscarIdPorNome(areaNome);

        mockMvc.perform(delete("/admin/areas/{areaId}", areaId)
                        .with(autenticacao(adminAuthentication)))
                .andExpect(status().is3xxRedirection());

        assertFalse(
                areaUseCase.listarAreas(admin, PageRequest.of(0, 100)).content().stream()
                        .anyMatch(area -> areaId.equals(area.getId()))
        );
    }

    @Test
    void deveFalharAoCadastrarAreaComNomeVazio() throws Exception {
        mockMvc.perform(post("/admin/areas")
                        .with(autenticacao(adminAuthentication))
                        .param("nome", " ")
                        .param("status", AREA_STATUS_ATIVO))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin"))
                .andExpect(flash().attribute("errorMessage", "Nome da area e obrigatorio"));
    }

    @Test
    void deveFalharAoCadastrarAreaComNomeAcimaDoLimite() throws Exception {
        mockMvc.perform(post("/admin/areas")
                        .with(autenticacao(adminAuthentication))
                        .param("nome", "A".repeat(256))
                        .param("status", AREA_STATUS_ATIVO))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin"))
                .andExpect(flash().attribute("errorMessage", "Nome da area deve ter no maximo 255 caracteres"));
    }

    @Test
    void deveFalharAoCadastrarAreaComStatusInvalido() throws Exception {
        mockMvc.perform(post("/admin/areas")
                        .with(autenticacao(adminAuthentication))
                        .param("nome", areaNome)
                        .param("status", "Inexistente"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/admin"))
                .andExpect(flash().attributeExists("errorMessage"));
    }

    @Test
    void deveFalharAoBuscarAreaInexistente() {
        UUID areaId = UUID.randomUUID();

        assertThrows(ResourceNotFoundException.class, () -> areaUseCase.buscarAreaPorId(admin, areaId));
    }

    @Test
    void deveNegarOperacaoParaUsuarioSemPerfilAdministrador() {
        AuthenticatedUser morador = new AuthenticatedUser(
                UUID.randomUUID(),
                "morador@condominio.local",
                "ROLE_MORADOR"
        );

        assertThrows(
                UnauthorizedOperationException.class,
                () -> areaUseCase.cadastrarArea(morador, "Piscina", StatusArea.ATIVO)
        );
        assertThrows(
                UnauthorizedOperationException.class,
                () -> areaUseCase.listarAreas(morador, PageRequest.of(0, 10))
        );
        assertThrows(
                UnauthorizedOperationException.class,
                () -> areaUseCase.buscarAreaPorId(morador, UUID.randomUUID())
        );
    }

    private void cadastrarAreaViaApi(String nome, String status) {
        try {
            mockMvc.perform(post("/admin/areas")
                            .with(autenticacao(adminAuthentication))
                            .param("nome", nome)
                            .param("status", status))
                    .andExpect(status().is3xxRedirection())
                    .andExpect(redirectedUrl("/admin/areas"));
        } catch (Exception exception) {
            throw new IllegalStateException(exception);
        }
    }

    private UUID buscarIdPorNome(String nome) {
        return areaUseCase.listarAreas(admin, PageRequest.of(0, 100)).content().stream()
                .filter(area -> nome.equals(area.getNome()))
                .map(Area::getId)
                .findFirst()
                .orElseThrow(() -> new AssertionError("Area nao encontrada: " + nome));
    }
}
