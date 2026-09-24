package br.com.dunnastecnologia.chamados.infrastructure.controller.web;

import br.com.dunnastecnologia.chamados.application.UserCase.AdminUseCases;
import br.com.dunnastecnologia.chamados.application.UserCase.AnexoChamadoUseCases;
import br.com.dunnastecnologia.chamados.application.UserCase.AreaUseCase;
import br.com.dunnastecnologia.chamados.application.UserCase.ComentarioUseCase;
import br.com.dunnastecnologia.chamados.application.pagination.PageResult;
import br.com.dunnastecnologia.chamados.domain.model.Colaborador;
import br.com.dunnastecnologia.chamados.domain.model.Morador;
import br.com.dunnastecnologia.chamados.domain.model.StatusArea;
import br.com.dunnastecnologia.chamados.domain.model.Unidade;
import br.com.dunnastecnologia.chamados.domain.model.Usuario;
import br.com.dunnastecnologia.chamados.infrastructure.controller.web.form.AtualizarStatusForm;
import br.com.dunnastecnologia.chamados.infrastructure.controller.web.form.AreaForm;
import br.com.dunnastecnologia.chamados.infrastructure.controller.web.form.BlocoForm;
import br.com.dunnastecnologia.chamados.infrastructure.controller.web.form.ComentarioForm;
import br.com.dunnastecnologia.chamados.infrastructure.controller.web.form.StatusChamadoForm;
import br.com.dunnastecnologia.chamados.infrastructure.controller.web.form.TipoChamadoForm;
import br.com.dunnastecnologia.chamados.infrastructure.controller.web.form.UsuarioForm;
import br.com.dunnastecnologia.chamados.infrastructure.controller.web.form.VincularColaboradorTipoChamadoForm;
import br.com.dunnastecnologia.chamados.infrastructure.controller.web.form.VincularMoradorUnidadeForm;
import br.com.dunnastecnologia.chamados.infrastructure.exception.BusinessRuleException;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Controller
@RequestMapping("/admin")
@PreAuthorize("hasRole('ADMINISTRADOR')")
public class AdminWebController {

    private static final Set<String> STATUS_RESERVADOS = Set.of("Finalizado", "Atrasado", "Solicitado");

    private final AdminUseCases adminUseCases;
    private final AnexoChamadoUseCases anexoChamadoUseCases;
    private final ComentarioUseCase comentarioUseCase;
    private final AreaUseCase areaUseCase;
    private final WebControllerSupport support;

    public AdminWebController(
            AdminUseCases adminUseCases,
            AnexoChamadoUseCases anexoChamadoUseCases,
            ComentarioUseCase comentarioUseCase,
            AreaUseCase areaUseCase,
            WebControllerSupport support
    ) {
        this.adminUseCases = adminUseCases;
        this.anexoChamadoUseCases = anexoChamadoUseCases;
        this.comentarioUseCase = comentarioUseCase;
        this.areaUseCase = areaUseCase;
        this.support = support;
    }

    @ModelAttribute("areaForm")
    public AreaForm areaForm() {
        return new AreaForm();
    }

    @ModelAttribute("blocoForm")
    public BlocoForm blocoForm() {
        return new BlocoForm();
    }

    @ModelAttribute("usuarioForm")
    public UsuarioForm usuarioForm() {
        return new UsuarioForm();
    }

    @ModelAttribute("tipoChamadoForm")
    public TipoChamadoForm tipoChamadoForm() {
        return new TipoChamadoForm();
    }

    @ModelAttribute("statusChamadoForm")
    public StatusChamadoForm statusChamadoForm() {
        return new StatusChamadoForm();
    }

    @ModelAttribute("atualizarStatusForm")
    public AtualizarStatusForm atualizarStatusForm() {
        return new AtualizarStatusForm();
    }

    @ModelAttribute("comentarioForm")
    public ComentarioForm comentarioForm() {
        return new ComentarioForm();
    }

    @ModelAttribute("vincularMoradorUnidadeForm")
    public VincularMoradorUnidadeForm vincularMoradorUnidadeForm() {
        return new VincularMoradorUnidadeForm();
    }

    @ModelAttribute("vincularColaboradorTipoChamadoForm")
    public VincularColaboradorTipoChamadoForm vincularColaboradorTipoChamadoForm() {
        return new VincularColaboradorTipoChamadoForm();
    }

    @ModelAttribute("tiposUsuario")
    public Map<String, String> tiposUsuario() {
        return Map.of(
                "ADMINISTRADOR", "Administrador",
                "COLABORADOR", "Colaborador",
                "MORADOR", "Morador"
        );
    }

    @Operation(summary = "Exibe o dashboard do administrador", tags = "02 - Admin Web - Paginas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pagina inicial do administrador renderizada com sucesso."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado.")
    })
    @GetMapping({"", "/"})
    @Transactional(readOnly = true)
    public String dashboard(
            Authentication authentication,
            Model model
    ) {
        var currentUser = support.authenticatedUser(authentication);
        PageResult<?> blocos = adminUseCases.listarBlocos(support.pageRequest(0, 1));
        PageResult<?> usuarios = adminUseCases.listarUsuarios(support.pageRequest(0, 1));
        PageResult<?> tipos = adminUseCases.listarTiposChamado(support.pageRequest(0, 1));
        PageResult<?> status = adminUseCases.listarStatus(support.pageRequest(0, 1));
        var statusDisponiveis = adminUseCases.listarStatus(lookupPageRequest());
        var chamados = adminUseCases.buscarChamados(currentUser, null, null, null, support.pageRequest(0, 5));
        UUID statusAtrasadoId = statusDisponiveis.content().stream()
                .filter(statusChamado -> "Atrasado".equalsIgnoreCase(statusChamado.getNome()))
                .map(br.com.dunnastecnologia.chamados.domain.model.StatusChamado::getId)
                .findFirst()
                .orElse(null);

        long totalChamadosAtrasados = statusAtrasadoId == null
                ? 0
                : adminUseCases.buscarChamados(currentUser, statusAtrasadoId, null, null, support.pageRequest(0, 1)).totalElements();

        model.addAttribute("pageTitle", "Painel do Administrador");
        model.addAttribute("totalBlocos", blocos.totalElements());
        model.addAttribute("totalUsuarios", usuarios.totalElements());
        model.addAttribute("totalTiposChamado", tipos.totalElements());
        model.addAttribute("totalStatus", status.totalElements());
        model.addAttribute("totalChamados", chamados.totalElements());
        model.addAttribute("totalChamadosAtrasados", totalChamadosAtrasados);
        model.addAttribute("chamadosRecentes", support.mapContent(chamados.content(), support::toChamadoMap));
        return "admin/dashboard";
    }

    @Operation(summary = "Exibe a tela de vinculo entre moradores e unidades", tags = "02 - Admin Web - Paginas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pagina de vinculo entre moradores e unidades renderizada com sucesso."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado."),
            @ApiResponse(responseCode = "404", description = "Morador ou bloco informado nao encontrado.")
    })
    @GetMapping({"/vinculos-morador", "/vinculos-morador/"})
    @Transactional(readOnly = true)
    public String gerenciarVinculosMorador(
            @RequestParam(required = false) UUID moradorId,
            @RequestParam(required = false) UUID blocoId,
            @RequestParam(required = false) String moradorEmail,
            @RequestParam(required = false) String cadastradosEmail,
            @RequestParam(defaultValue = "0") Integer cadastradosPage,
            @RequestParam(defaultValue = "10") Integer cadastradosSize,
            @RequestParam(required = false) String semUnidadeEmail,
            @RequestParam(defaultValue = "0") Integer semUnidadePage,
            @RequestParam(defaultValue = "10") Integer semUnidadeSize,
            Model model
    ) {
        var moradores = adminUseCases.listarMoradoresPorPrefixoEmail(moradorEmail, lookupPageRequest());
        var moradoresCadastrados = adminUseCases.listarMoradoresPorPrefixoEmail(
                cadastradosEmail,
                support.pageRequest(cadastradosPage, cadastradosSize)
        );
        var moradoresSemUnidade = adminUseCases.listarMoradoresSemUnidadePorPrefixoEmail(
                semUnidadeEmail,
                support.pageRequest(semUnidadePage, semUnidadeSize)
        );

        model.addAttribute("pageTitle", "Vincular Morador");
        model.addAttribute("moradoresDisponiveis", support.mapContent(moradores.content(), support::toUsuarioMap));
        model.addAttribute("moradoresCadastrados", support.mapContent(moradoresCadastrados.content(), support::toUsuarioMap));
        model.addAttribute("moradoresCadastradosPage", support.pageMetadata(moradoresCadastrados));
        carregarBlocosDisponiveis(model);
        model.addAttribute("moradoresSemUnidade", support.mapContent(moradoresSemUnidade.content(), support::toUsuarioMap));
        model.addAttribute("moradoresSemUnidadePage", support.pageMetadata(moradoresSemUnidade));
        model.addAttribute("moradorSelecionadoId", moradorId);
        model.addAttribute("blocoSelecionadoId", blocoId);
        model.addAttribute("filtroMoradorEmail", moradorEmail);
        model.addAttribute("filtroCadastradosEmail", cadastradosEmail);
        model.addAttribute("filtroSemUnidadeEmail", semUnidadeEmail);

        if (moradorId != null) {
            carregarVinculosMorador(model, moradorId, blocoId);
        }

        return "admin/vinculos-morador/lista";
    }

    @Operation(summary = "Exibe a tela de definicao de escopo do colaborador", tags = "02 - Admin Web - Paginas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pagina de escopo do colaborador renderizada com sucesso."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado."),
            @ApiResponse(responseCode = "404", description = "Colaborador informado nao encontrado.")
    })
    @GetMapping({"/escopo-colaborador", "/escopo-colaborador/"})
    @Transactional(readOnly = true)
    public String gerenciarEscopoColaborador(
            @RequestParam(required = false) UUID colaboradorId,
            @RequestParam(required = false) String colaboradorEmail,
            Model model
    ) {
        var colaboradores = adminUseCases.listarColaboradoresPorPrefixoEmail(
                colaboradorEmail,
                lookupPageRequest()
        );

        model.addAttribute("pageTitle", "Designar Colaborador");
        model.addAttribute("colaboradoresDisponiveis", support.mapContent(colaboradores.content(), support::toUsuarioMap));
        carregarTiposChamadoDisponiveis(model);
        model.addAttribute("colaboradorSelecionadoId", colaboradorId);
        model.addAttribute("filtroColaboradorEmail", colaboradorEmail);

        if (colaboradorId != null) {
            carregarEscopoColaborador(model, colaboradorId);
        }

        return "admin/escopo-colaborador/lista";
    }

    @Operation(summary = "Lista os blocos cadastrados", tags = "02 - Admin Web - Paginas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pagina de listagem de blocos renderizada com sucesso."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado.")
    })
    @GetMapping({"/blocos", "/blocos/"})
    @Transactional(readOnly = true)
    public String listarBlocos(
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "10") Integer size,
            Model model
    ) {
        var blocos = adminUseCases.listarBlocos(support.pageRequest(page, size));
        model.addAttribute("pageTitle", "Blocos");
        model.addAttribute("blocos", support.mapContent(blocos.content(), support::toBlocoMap));
        model.addAttribute("blocosPage", support.pageMetadata(blocos));
        return "admin/blocos/lista";
    }

    @Operation(summary = "Exibe o detalhe de um bloco", tags = "02 - Admin Web - Paginas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pagina de detalhe do bloco renderizada com sucesso."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado."),
            @ApiResponse(responseCode = "404", description = "Bloco nao encontrado.")
    })
    @GetMapping("/blocos/{blocoId}")
    @Transactional(readOnly = true)
    public String detalharBloco(
            @PathVariable UUID blocoId,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "20") Integer size,
            Model model
    ) {
        var bloco = adminUseCases.buscarBlocoPorId(blocoId);
        var unidades = adminUseCases.listarUnidadesDoBloco(blocoId, support.pageRequest(page, size));
        var moradoresPorUnidade = adminUseCases.listarMoradoresPorUnidadeIds(
                unidades.content().stream().map(Unidade::getId).toList()
        );

        model.addAttribute("pageTitle", "Detalhes do Bloco");
        model.addAttribute("bloco", support.toBlocoMap(bloco));
        model.addAttribute(
                "unidades",
                unidades.content().stream()
                        .map(unidade -> {
                            var values = support.toUnidadeMap(unidade);
                            var moradores = moradoresPorUnidade.getOrDefault(unidade.getId(), java.util.List.of());
                            values.put(
                                    "moradores",
                                    moradores.stream().map(support::toUsuarioMap).toList()
                            );
                            return values;
                        })
                        .toList()
        );
        model.addAttribute("unidadesPage", support.pageMetadata(unidades));
        return "admin/blocos/detalhe";
    }

    @Operation(summary = "Lista os usuarios do sistema", tags = "02 - Admin Web - Paginas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pagina de listagem de usuarios renderizada com sucesso."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado.")
    })
    @GetMapping({"/usuarios", "/usuarios/"})
    @Transactional(readOnly = true)
    public String listarUsuarios(
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "10") Integer size,
            Model model
    ) {
        var usuarios = adminUseCases.listarUsuarios(support.pageRequest(page, size));

        model.addAttribute("pageTitle", "Usuarios");
        model.addAttribute("usuarios", support.mapContent(usuarios.content(), support::toUsuarioMap));
        model.addAttribute("usuariosPage", support.pageMetadata(usuarios));
        return "admin/usuarios/lista";
    }

    @Operation(summary = "Exibe o detalhe de um usuario", tags = "02 - Admin Web - Paginas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pagina de detalhe do usuario renderizada com sucesso."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado."),
            @ApiResponse(responseCode = "404", description = "Usuario nao encontrado.")
    })
    @GetMapping("/usuarios/{usuarioId}")
    @Transactional(readOnly = true)
    public String detalharUsuario(
            @PathVariable UUID usuarioId,
            @RequestParam(required = false) UUID blocoId,
            Model model
    ) {
        Usuario usuario = adminUseCases.buscarUsuarioPorId(usuarioId);

        model.addAttribute("pageTitle", "Detalhes do Usuario");
        model.addAttribute("usuario", support.toUsuarioMap(usuario));
        model.addAttribute("usuarioForm", toUsuarioForm(usuario));

        if (usuario instanceof Morador) {
            carregarDadosMorador(model, usuarioId, blocoId, true);
        }

        if (usuario instanceof Colaborador) {
            carregarTiposChamadoDisponiveis(model);
            carregarDadosColaborador(model, usuarioId);
        }

        return "admin/usuarios/detalhe";
    }

    @Operation(summary = "Lista as areas do condominio", tags = "02 - Admin Web - Paginas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pagina de listagem de areas renderizada com sucesso."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado."),
            @ApiResponse(responseCode = "404", description = "Area informada nao encontrada.")
    })
    @GetMapping({"/areas", "/areas/"})
    @Transactional(readOnly = true)
    public String listarAreas(
            Authentication authentication,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "10") Integer size,
            @RequestParam(required = false) UUID areaId,
            Model model
    ) {
        var currentUser = support.authenticatedUser(authentication);
        var areas = areaUseCase.listarAreas(currentUser, support.pageRequest(page, size));

        model.addAttribute("pageTitle", "Areas");
        model.addAttribute("areas", support.mapContent(areas.content(), support::toAreaMap));
        model.addAttribute("areasPage", support.pageMetadata(areas));
        model.addAttribute("statusAreaDisponiveis", StatusArea.values());

        if (areaId != null) {
            var area = areaUseCase.buscarAreaPorId(currentUser, areaId);
            var form = new AreaForm();
            form.setNome(area.getNome());
            form.setStatus(area.getStatus() == null ? null : area.getStatus().getValor());
            model.addAttribute("areaEdicao", support.toAreaMap(area));
            model.addAttribute("areaForm", form);
        }

        return "admin/areas/lista";
    }

    @Operation(summary = "Lista os tipos de chamado cadastrados", tags = "02 - Admin Web - Paginas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pagina de tipos de chamado renderizada com sucesso."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado.")
    })
    @GetMapping({"/tipos-chamado", "/tipos-chamado/"})
    @Transactional(readOnly = true)
    public String listarTiposChamado(
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "10") Integer size,
            @RequestParam(required = false) UUID tipoId,
            Model model
    ) {
        var tipos = adminUseCases.listarTiposChamado(support.pageRequest(page, size));
        model.addAttribute("pageTitle", "Tipos de Chamado");
        model.addAttribute("tiposChamado", support.mapContent(tipos.content(), support::toTipoChamadoMap));
        model.addAttribute("tiposChamadoPage", support.pageMetadata(tipos));

        if (tipoId != null) {
            var tipo = adminUseCases.buscarPorId(tipoId);
            var form = new TipoChamadoForm();
            form.setTitulo(tipo.getTitulo());
            form.setPrazoHoras(tipo.getPrazoHoras());
            model.addAttribute("tipoChamadoEdicao", support.toTipoChamadoMap(tipo));
            model.addAttribute("tipoChamadoForm", form);
        }

        return "admin/tipos-chamado/lista";
    }

    @Operation(summary = "Lista os status de chamado configurados", tags = "02 - Admin Web - Paginas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pagina de status de chamado renderizada com sucesso."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado.")
    })
    @GetMapping({"/status-chamado", "/status-chamado/"})
    @Transactional(readOnly = true)
    public String listarStatusChamado(
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "10") Integer size,
            @RequestParam(required = false) UUID statusId,
            Model model
    ) {
        var status = adminUseCases.listarStatus(support.pageRequest(page, size));
        model.addAttribute("pageTitle", "Status de Chamado");
        model.addAttribute(
                "statusChamado",
                status.content().stream()
                        .map(statusChamado -> {
                            Map<String, Object> values = new LinkedHashMap<>(support.toStatusChamadoMap(statusChamado));
                            values.put("editavel", !isStatusReservado(statusChamado.getNome()));
                            return values;
                        })
                        .toList()
        );
        model.addAttribute("statusChamadoPage", support.pageMetadata(status));

        if (statusId != null) {
            var statusSelecionado = adminUseCases.buscarStatusPorId(statusId);
            var form = new StatusChamadoForm();
            form.setNome(statusSelecionado.getNome());
            model.addAttribute("statusEdicao", support.toStatusChamadoMap(statusSelecionado));
            model.addAttribute("statusEdicaoBloqueada", isStatusReservado(statusSelecionado.getNome()));
            model.addAttribute("statusChamadoForm", form);
        }

        return "admin/status-chamado/lista";
    }

    @Operation(summary = "Lista os chamados visiveis ao administrador", tags = "02 - Admin Web - Paginas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pagina de chamados do administrador renderizada com sucesso."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado.")
    })
    @GetMapping({"/chamados", "/chamados/"})
    @Transactional(readOnly = true)
    public String listarChamados(
            Authentication authentication,
            @RequestParam(required = false) UUID statusId,
            @RequestParam(required = false) String moradorNome,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dataAbertura,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "10") Integer size,
            Model model
    ) {
        var currentUser = support.authenticatedUser(authentication);
        var chamados = adminUseCases.buscarChamados(
                currentUser,
                statusId,
                moradorNome,
                dataAbertura,
                support.pageRequest(page, size)
        );
        var status = adminUseCases.listarStatus(lookupPageRequest());

        model.addAttribute("pageTitle", "Chamados");
        model.addAttribute("chamados", support.mapContent(chamados.content(), support::toChamadoMap));
        model.addAttribute("chamadosPage", support.pageMetadata(chamados));
        model.addAttribute("statusDisponiveis", support.mapContent(status.content(), support::toStatusChamadoMap));
        model.addAttribute("filtroStatusId", statusId);
        model.addAttribute("filtroMoradorNome", moradorNome);
        model.addAttribute("filtroDataAbertura", dataAbertura);
        return "admin/chamados/lista";
    }

    @Operation(summary = "Exibe o detalhe de um chamado do administrador", tags = "02 - Admin Web - Paginas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pagina de detalhe do chamado renderizada com sucesso."),
            @ApiResponse(responseCode = "403", description = "Acesso negado para o perfil autenticado."),
            @ApiResponse(responseCode = "404", description = "Chamado nao encontrado.")
    })
    @GetMapping("/chamados/{chamadoId}")
    @Transactional(readOnly = true)
    public String detalharChamado(
            Authentication authentication,
            @PathVariable UUID chamadoId,
            Model model
    ) {
        var currentUser = support.authenticatedUser(authentication);
        var chamado = adminUseCases.buscarChamadoPorId(currentUser, chamadoId);
        var status = adminUseCases.listarStatus(lookupPageRequest());
        var comentarios = comentarioUseCase.listarComentariosDoChamado(currentUser, chamadoId, lookupPageRequest());
        var anexos = anexoChamadoUseCases.listarAnexosDoChamado(currentUser, chamadoId, lookupPageRequest());

        model.addAttribute("pageTitle", "Detalhes do Chamado");
        model.addAttribute("chamado", support.toChamadoMap(chamado));
        model.addAttribute("statusDisponiveis", support.mapContent(status.content(), support::toStatusChamadoMap));
        model.addAttribute("comentarios", support.mapContent(comentarios.content(), support::toComentarioMap));
        model.addAttribute(
                "anexos",
                anexos.content().stream()
                        .map(anexo -> support.toAnexoMap(
                                anexo.id(),
                                anexo.nomeArquivo(),
                                anexo.contentType(),
                                anexo.tamanhoBytes()
                        ))
                        .toList()
        );
        return "admin/chamados/detalhe";
    }

    private UsuarioForm toUsuarioForm(Usuario usuario) {
        var usuarioForm = new UsuarioForm();
        usuarioForm.setNome(usuario.getNome());
        usuarioForm.setEmail(usuario.getEmail());
        usuarioForm.setTipo(resolveTipoUsuario(usuario));
        return usuarioForm;
    }

    private String resolveTipoUsuario(Usuario usuario) {
        return switch (usuario.getRole()) {
            case "ROLE_ADMINISTRADOR" -> "ADMINISTRADOR";
            case "ROLE_COLABORADOR" -> "COLABORADOR";
            case "ROLE_MORADOR" -> "MORADOR";
            default -> throw new BusinessRuleException("Tipo de usuario nao suportado");
        };
    }

    private void carregarVinculosMorador(Model model, UUID moradorId, UUID blocoId) {
        var morador = requireMorador(moradorId);
        model.addAttribute("moradorSelecionado", support.toUsuarioMap(morador));
        carregarDadosMorador(model, moradorId, blocoId, false);
    }

    private void carregarEscopoColaborador(Model model, UUID colaboradorId) {
        var colaborador = requireColaborador(colaboradorId);
        model.addAttribute("colaboradorSelecionado", support.toUsuarioMap(colaborador));
        carregarDadosColaborador(model, colaboradorId);
    }

    private void carregarDadosMorador(Model model, UUID moradorId, UUID blocoId, boolean incluirBlocosDisponiveis) {
        var unidadesMorador = adminUseCases.listarUnidadesDoMorador(moradorId, lookupPageRequest());
        var unidadesMoradorContent = unidadesMorador.content();
        Set<UUID> unidadeIdsVinculadas = unidadesMoradorContent.stream()
                .map(Unidade::getId)
                .collect(Collectors.toSet());

        model.addAttribute("unidadesMorador", support.mapContent(unidadesMoradorContent, support::toUnidadeMap));

        if (incluirBlocosDisponiveis) {
            carregarBlocosDisponiveis(model);
        }

        if (blocoId != null) {
            model.addAttribute("blocoSelecionadoId", blocoId);
            model.addAttribute("vincularMoradorUnidadeForm", toVincularMoradorUnidadeForm(blocoId));
            carregarUnidadesDoBloco(model, blocoId, unidadeIdsVinculadas);
        }
    }

    private void carregarDadosColaborador(Model model, UUID colaboradorId) {
        var tiposResponsaveis = adminUseCases.listarTiposChamadoDoColaborador(colaboradorId, lookupPageRequest());
        Set<UUID> tiposResponsaveisIds = tiposResponsaveis.content().stream()
                .map(tipoChamado -> tipoChamado.getId())
                .collect(Collectors.toSet());

        model.addAttribute("tiposChamadoColaborador", support.mapContent(tiposResponsaveis.content(), support::toTipoChamadoMap));
        model.addAttribute("tiposChamadoResponsaveisIds", tiposResponsaveisIds);
    }

    private void carregarBlocosDisponiveis(Model model) {
        var blocos = adminUseCases.listarBlocos(lookupPageRequest());
        model.addAttribute("blocosDisponiveis", support.mapContent(blocos.content(), support::toBlocoMap));
    }

    private void carregarTiposChamadoDisponiveis(Model model) {
        var tiposChamado = adminUseCases.listarTiposChamado(lookupPageRequest());
        model.addAttribute("tiposChamadoDisponiveis", support.mapContent(tiposChamado.content(), support::toTipoChamadoMap));
    }

    private void carregarUnidadesDoBloco(Model model, UUID blocoId, Set<UUID> unidadeIdsVinculadas) {
        var unidadesBloco = adminUseCases.listarUnidadesDoBloco(blocoId, lookupPageRequest());
        model.addAttribute(
                "unidadesBloco",
                unidadesBloco.content().stream()
                        .map(unidade -> {
                            var values = support.toUnidadeMap(unidade);
                            values.put("vinculadaAoMorador", unidadeIdsVinculadas.contains(unidade.getId()));
                            return values;
                        })
                        .toList()
        );
    }

    private VincularMoradorUnidadeForm toVincularMoradorUnidadeForm(UUID blocoId) {
        var form = new VincularMoradorUnidadeForm();
        form.setBlocoId(blocoId);
        return form;
    }

    private Morador requireMorador(UUID moradorId) {
        Usuario usuario = adminUseCases.buscarUsuarioPorId(moradorId);
        if (!(usuario instanceof Morador morador)) {
            throw new BusinessRuleException("O usuario selecionado nao e um morador.");
        }
        return morador;
    }

    private Colaborador requireColaborador(UUID colaboradorId) {
        Usuario usuario = adminUseCases.buscarUsuarioPorId(colaboradorId);
        if (!(usuario instanceof Colaborador colaborador)) {
            throw new BusinessRuleException("O usuario selecionado nao e um colaborador.");
        }
        return colaborador;
    }

    private org.springframework.data.domain.PageRequest lookupPageRequest() {
        return support.pageRequest(0, 100);
    }

    private boolean isStatusReservado(String nome) {
        if (nome == null) {
            return false;
        }
        return STATUS_RESERVADOS.stream().anyMatch(reservado -> reservado.equalsIgnoreCase(nome));
    }
}
