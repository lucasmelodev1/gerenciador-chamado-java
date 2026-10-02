package br.com.dunnastecnologia.chamados.infrastructure.service;

import br.com.dunnastecnologia.chamados.application.Security.AuthenticatedUser;
import br.com.dunnastecnologia.chamados.application.UserCase.AreaUseCase;
import br.com.dunnastecnologia.chamados.application.pagination.PageResult;
import br.com.dunnastecnologia.chamados.domain.model.Area;
import br.com.dunnastecnologia.chamados.domain.model.StatusArea;
import br.com.dunnastecnologia.chamados.domain.validation.ValidationLimits;
import br.com.dunnastecnologia.chamados.infrastructure.exception.ResourceNotFoundException;
import br.com.dunnastecnologia.chamados.infrastructure.repository.AreaRepository;
import br.com.dunnastecnologia.chamados.infrastructure.service.support.AuthenticatedUserValidator;
import br.com.dunnastecnologia.chamados.infrastructure.service.support.InputValidationSupport;
import br.com.dunnastecnologia.chamados.infrastructure.service.support.PageResultMapper;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@Transactional(readOnly = true)
public class AreaService implements AreaUseCase {

    private final AreaRepository areaRepository;
    private final AuthenticatedUserValidator authenticatedUserValidator;

    public AreaService(
            AreaRepository areaRepository,
            AuthenticatedUserValidator authenticatedUserValidator
    ) {
        this.areaRepository = areaRepository;
        this.authenticatedUserValidator = authenticatedUserValidator;
    }

    @Override
    @Transactional
    public Area cadastrarArea(AuthenticatedUser admin, String nome, StatusArea status) {
        authenticatedUserValidator.assertAdministrador(admin);

        Area area = new Area();
        area.setNome(normalizarNome(nome));
        area.setStatus(status == null ? StatusArea.ATIVO : status);
        return areaRepository.save(area);
    }

    @Override
    public PageResult<Area> listarAreas(AuthenticatedUser admin, PageRequest pageRequest) {
        authenticatedUserValidator.assertAdministrador(admin);
        return PageResultMapper.fromPage(areaRepository.findAll(pageRequest));
    }

    @Override
    public Area buscarAreaPorId(AuthenticatedUser admin, UUID areaId) {
        authenticatedUserValidator.assertAdministrador(admin);
        return buscarArea(areaId);
    }

    @Override
    @Transactional
    public Area atualizarArea(AuthenticatedUser admin, UUID areaId, String nome, StatusArea status) {
        authenticatedUserValidator.assertAdministrador(admin);

        Area area = buscarArea(areaId);
        area.setNome(normalizarNome(nome));
        if (status != null) {
            area.setStatus(status);
        }
        return areaRepository.save(area);
    }

    @Override
    @Transactional
    public void removerArea(AuthenticatedUser admin, UUID areaId) {
        authenticatedUserValidator.assertAdministrador(admin);
        Area area = buscarArea(areaId);
        area.setDeletedAt(LocalDateTime.now());
        areaRepository.save(area);
    }

    private Area buscarArea(UUID areaId) {
        return areaRepository.findById(areaId)
                .orElseThrow(() -> new ResourceNotFoundException("Area nao encontrada"));
    }

    private String normalizarNome(String nome) {
        return InputValidationSupport.normalizeRequiredText(
                nome,
                "Nome da area e obrigatorio",
                "Nome da area deve ter no maximo " + ValidationLimits.AREA_NOME_MAX_LENGTH + " caracteres",
                ValidationLimits.AREA_NOME_MAX_LENGTH
        );
    }
}
