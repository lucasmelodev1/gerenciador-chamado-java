package br.com.dunnastecnologia.chamados.infrastructure.service;

import br.com.dunnastecnologia.chamados.application.Security.AuthenticatedUser;
import br.com.dunnastecnologia.chamados.application.pagination.PageResult;
import br.com.dunnastecnologia.chamados.domain.model.Area;
import br.com.dunnastecnologia.chamados.domain.model.StatusArea;
import br.com.dunnastecnologia.chamados.domain.validation.ValidationLimits;
import br.com.dunnastecnologia.chamados.infrastructure.exception.BusinessRuleException;
import br.com.dunnastecnologia.chamados.infrastructure.exception.ResourceNotFoundException;
import br.com.dunnastecnologia.chamados.infrastructure.exception.UnauthorizedOperationException;
import br.com.dunnastecnologia.chamados.infrastructure.repository.AreaRepository;
import br.com.dunnastecnologia.chamados.infrastructure.service.support.AuthenticatedUserValidator;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AreaServiceTest {

    @Mock
    private AreaRepository areaRepository;
    @Mock
    private AuthenticatedUserValidator authenticatedUserValidator;

    @InjectMocks
    private AreaService areaService;

    @Test
    void cadastrarAreaDeveCriarAtivaPorPadraoQuandoStatusAusente() {
        when(areaRepository.save(any(Area.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Area area = areaService.cadastrarArea(administradorAutenticado(), "  Salao de festas  ", null);

        assertEquals("Salao de festas", area.getNome());
        assertEquals(StatusArea.ATIVO, area.getStatus());
    }

    @Test
    void cadastrarAreaDevePreservarStatusInformado() {
        when(areaRepository.save(any(Area.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Area area = areaService.cadastrarArea(administradorAutenticado(), "Churrasqueira", StatusArea.INATIVO);

        assertEquals(StatusArea.INATIVO, area.getStatus());
    }

    @Test
    void cadastrarAreaDeveExigirNome() {
        AuthenticatedUser admin = administradorAutenticado();

        assertThrows(
                BusinessRuleException.class,
                () -> areaService.cadastrarArea(admin, "   ", StatusArea.ATIVO)
        );
    }

    @Test
    void cadastrarAreaDeveRecusarNomeAcimaDoLimite() {
        AuthenticatedUser admin = administradorAutenticado();
        String nomeLongo = "x".repeat(ValidationLimits.AREA_NOME_MAX_LENGTH + 1);

        assertThrows(
                BusinessRuleException.class,
                () -> areaService.cadastrarArea(admin, nomeLongo, StatusArea.ATIVO)
        );
    }

    @Test
    void cadastrarAreaDeveNegarPerfilSemPermissao() {
        AuthenticatedUser morador = moradorAutenticado();
        doThrow(new UnauthorizedOperationException("sem permissao"))
                .when(authenticatedUserValidator).assertAdministrador(morador);

        assertThrows(
                UnauthorizedOperationException.class,
                () -> areaService.cadastrarArea(morador, "Piscina", StatusArea.ATIVO)
        );
    }

    @Test
    void listarAreasDeveRetornarPaginaParaAdmin() {
        PageRequest pageRequest = PageRequest.of(0, 10);
        Area area = area("Piscina", StatusArea.ATIVO);
        when(areaRepository.findAll(pageRequest))
                .thenReturn(new PageImpl<>(List.of(area), pageRequest, 1));

        PageResult<Area> resultado = areaService.listarAreas(administradorAutenticado(), pageRequest);

        assertEquals(1, resultado.totalElements());
        assertEquals(List.of(area), resultado.content());
    }

    @Test
    void listarAreasDeveNegarPerfilSemPermissao() {
        AuthenticatedUser morador = moradorAutenticado();
        PageRequest pageRequest = PageRequest.of(0, 10);
        doThrow(new UnauthorizedOperationException("sem permissao"))
                .when(authenticatedUserValidator).assertAdministrador(morador);

        assertThrows(
                UnauthorizedOperationException.class,
                () -> areaService.listarAreas(morador, pageRequest)
        );
    }

    @Test
    void buscarAreaPorIdDeveRetornarAreaExistente() {
        Area area = area("Piscina", StatusArea.ATIVO);
        when(areaRepository.findById(area.getId())).thenReturn(Optional.of(area));

        assertEquals(area, areaService.buscarAreaPorId(administradorAutenticado(), area.getId()));
    }

    @Test
    void buscarAreaPorIdDeveRecusarAreaInexistente() {
        UUID areaId = UUID.randomUUID();
        AuthenticatedUser admin = administradorAutenticado();
        when(areaRepository.findById(areaId)).thenReturn(Optional.empty());

        assertThrows(
                ResourceNotFoundException.class,
                () -> areaService.buscarAreaPorId(admin, areaId)
        );
    }

    @Test
    void atualizarAreaDeveAlterarNomeEPreservarStatusQuandoAusente() {
        Area area = area("Piscina", StatusArea.ATIVO);
        when(areaRepository.findById(area.getId())).thenReturn(Optional.of(area));
        when(areaRepository.save(area)).thenReturn(area);

        Area atualizada = areaService.atualizarArea(administradorAutenticado(), area.getId(), " Piscina adulto ", null);

        assertEquals("Piscina adulto", atualizada.getNome());
        assertEquals(StatusArea.ATIVO, atualizada.getStatus());
    }

    @Test
    void atualizarAreaDeveAlterarStatusInformado() {
        Area area = area("Piscina", StatusArea.ATIVO);
        when(areaRepository.findById(area.getId())).thenReturn(Optional.of(area));
        when(areaRepository.save(area)).thenReturn(area);

        Area atualizada = areaService.atualizarArea(administradorAutenticado(), area.getId(), "Piscina", StatusArea.INATIVO);

        assertEquals(StatusArea.INATIVO, atualizada.getStatus());
    }

    @Test
    void atualizarAreaDeveRecusarAreaInexistente() {
        UUID areaId = UUID.randomUUID();
        AuthenticatedUser admin = administradorAutenticado();
        when(areaRepository.findById(areaId)).thenReturn(Optional.empty());

        assertThrows(
                ResourceNotFoundException.class,
                () -> areaService.atualizarArea(admin, areaId, "Piscina", StatusArea.ATIVO)
        );
    }

    @Test
    void removerAreaDeveMarcarDeletedAtEPersistir() {
        Area area = area("Piscina", StatusArea.ATIVO);
        when(areaRepository.findById(area.getId())).thenReturn(Optional.of(area));
        when(areaRepository.save(area)).thenReturn(area);

        areaService.removerArea(administradorAutenticado(), area.getId());

        assertNotNull(area.getDeletedAt());
        verify(areaRepository).save(area);
    }

    @Test
    void removerAreaDeveRecusarAreaInexistente() {
        UUID areaId = UUID.randomUUID();
        AuthenticatedUser admin = administradorAutenticado();
        when(areaRepository.findById(areaId)).thenReturn(Optional.empty());

        assertThrows(
                ResourceNotFoundException.class,
                () -> areaService.removerArea(admin, areaId)
        );
    }

    @Test
    void removerAreaDeveNegarPerfilSemPermissao() {
        AuthenticatedUser morador = moradorAutenticado();
        doThrow(new UnauthorizedOperationException("sem permissao"))
                .when(authenticatedUserValidator).assertAdministrador(morador);

        assertThrows(
                UnauthorizedOperationException.class,
                () -> areaService.removerArea(morador, UUID.randomUUID())
        );
    }

    private AuthenticatedUser administradorAutenticado() {
        return new AuthenticatedUser(UUID.randomUUID(), "admin@condominio.local", "ROLE_ADMINISTRADOR");
    }

    private AuthenticatedUser moradorAutenticado() {
        return new AuthenticatedUser(UUID.randomUUID(), "morador@condominio.local", "ROLE_MORADOR");
    }

    private Area area(String nome, StatusArea status) {
        Area area = new Area();
        area.setId(UUID.randomUUID());
        area.setNome(nome);
        area.setStatus(status);
        return area;
    }
}
