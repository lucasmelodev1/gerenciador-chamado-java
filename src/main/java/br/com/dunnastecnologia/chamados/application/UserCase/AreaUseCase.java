package br.com.dunnastecnologia.chamados.application.UserCase;

import br.com.dunnastecnologia.chamados.application.Security.AuthenticatedUser;
import br.com.dunnastecnologia.chamados.application.pagination.PageResult;
import br.com.dunnastecnologia.chamados.domain.model.Area;
import br.com.dunnastecnologia.chamados.domain.model.StatusArea;
import org.springframework.data.domain.PageRequest;

import java.util.UUID;

public interface AreaUseCase {

    Area cadastrarArea(
            AuthenticatedUser admin,
            String nome,
            StatusArea status
    );

    PageResult<Area> listarAreas(
            AuthenticatedUser admin,
            PageRequest pageRequest
    );

    Area buscarAreaPorId(
            AuthenticatedUser admin,
            UUID areaId
    );

    Area atualizarArea(
            AuthenticatedUser admin,
            UUID areaId,
            String nome,
            StatusArea status
    );

    void removerArea(
            AuthenticatedUser admin,
            UUID areaId
    );
}
